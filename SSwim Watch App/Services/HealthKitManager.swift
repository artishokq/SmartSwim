//
//  HealthKitManager.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import Foundation
import HealthKit
import Combine

final class HealthKitManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    // MARK: - Singleton
    static let shared = HealthKitManager()
    
    // MARK: - Publishers
    let heartRatePublisher = PassthroughSubject<Double, Never>()
    let strokeCountPublisher = PassthroughSubject<Int, Never>()
    let workoutStatePublisher = PassthroughSubject<Bool, Never>()
    let errorPublisher = PassthroughSubject<String, Never>()
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var heartRateQuery: HKQuery?
    private var strokeCountQuery: HKQuery?
    
    private var lastStrokeCount: Double = 0
    private var currentPoolLength: Double = 25.0
    
    // Улучшенный подсчет гребков по упражнениям
    private var strokesByExercise: [String: Int] = [:]
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Private Methods
    private func startHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            guard let samples = samples as? [HKQuantitySample], let mostRecentSample = samples.last else {
                return
            }
            
            let heartRate = mostRecentSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async {
                self?.heartRatePublisher.send(heartRate)
            }
        }
        
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            guard let samples = samples as? [HKQuantitySample], let mostRecentSample = samples.last else {
                return
            }
            
            let heartRate = mostRecentSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async {
                self?.heartRatePublisher.send(heartRate)
            }
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    private func stopMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        
        if let query = strokeCountQuery {
            healthStore.stop(query)
            strokeCountQuery = nil
        }
    }
    
    // MARK: - Public Methods
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
            HKObjectType.workoutType()
        ]
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
    }
    
    func getCurrentPoolLength() -> Double {
        return currentPoolLength
    }
    
    // Метод для сброса счетчика гребков для конкретного упражнения
    func resetStrokeCountForExercise(_ exerciseId: String) {
        strokesByExercise[exerciseId] = Int(lastStrokeCount)
        print("Счетчик гребков сброшен для упражнения: \(exerciseId)")
    }
    
    // Метод для получения количества гребков для конкретного упражнения
    func getStrokeCountForExercise(_ exerciseId: String) -> Int {
        let baseCount = strokesByExercise[exerciseId] ?? 0
        let currentCount = Int(lastStrokeCount) - baseCount
        return max(0, currentCount) // Обеспечиваем, что число не будет отрицательным
    }
    
    func startWorkout(poolLength: Double = 25.0) {
        // Останавливаем существующую сессию, если есть
        if workoutSession != nil {
            stopWorkout()
        }
        
        currentPoolLength = poolLength
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .swimming
        configuration.locationType = .indoor
        configuration.swimmingLocationType = .pool
        configuration.lapLength = HKQuantity(unit: HKUnit.meter(), doubleValue: poolLength)
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                                 workoutConfiguration: configuration)
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { (success, error) in
                if let error = error {
                    self.errorPublisher.send("Ошибка начала сбора данных: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.workoutStatePublisher.send(true)
                }
            }
            
            startHeartRateMonitoring()
            
        } catch {
            errorPublisher.send("Ошибка создания сессии тренировки: \(error.localizedDescription)")
        }
    }
    
    func stopWorkout() {
        guard let workoutSession = workoutSession else {
            return
        }
        
        stopMonitoring()
        workoutSession.end()
        workoutBuilder?.endCollection(withEnd: Date()) { [weak self] (success, error) in
            guard let self = self, success else {
                self?.errorPublisher.send("Ошибка завершения сбора данных: \(String(describing: error))")
                return
            }
            
            self.workoutBuilder?.finishWorkout { (workout, error) in
                if let error = error {
                    self.errorPublisher.send("Ошибка сохранения тренировки: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.workoutStatePublisher.send(false)
                    self.workoutSession = nil
                    self.workoutBuilder = nil
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.workoutStatePublisher.send(toState == .running)
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        errorPublisher.send("Ошибка тренировки: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.workoutStatePublisher.send(false)
        }
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            if quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                if let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                    DispatchQueue.main.async {
                        self.heartRatePublisher.send(value)
                    }
                }
            }
            else if quantityType.identifier == HKQuantityTypeIdentifier.swimmingStrokeCount.rawValue {
                let strokeUnit = HKUnit.count()
                if let value = statistics?.sumQuantity()?.doubleValue(for: strokeUnit), value > self.lastStrokeCount {
                    let newCount = Int(value)
                    DispatchQueue.main.async {
                        self.strokeCountPublisher.send(newCount)
                    }
                    self.lastStrokeCount = value
                }
            }
        }
    }
    
    func getWorkoutTotalCalories() -> Double {
        guard let builder = workoutBuilder else { return 0 }
        
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        if let statistics = builder.statistics(for: calorieType),
           let calories = statistics.sumQuantity() {
            return calories.doubleValue(for: HKUnit.kilocalorie())
        }
        
        return 0 // Возвращаем 0, если данные недоступны
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}
