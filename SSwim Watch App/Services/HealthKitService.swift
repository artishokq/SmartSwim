//
//  HealthKitService.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import Foundation
import HealthKit
import Combine

class HealthKitService: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    // MARK: - Constants
    private enum Constants {
        static let defaultPoolLength: Double = 25.0
    }
    
    // MARK: - Singleton
    static let shared = HealthKitService()
    
    // MARK: - Properties
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var heartRateQuery: HKQuery?
    private var strokeCountQuery: HKQuery?
    private var currentPoolLength: Double = Constants.defaultPoolLength
    
    private var lastStrokeCount: Double = 0
    
    // MARK: - Publishers
    let heartRatePublisher = PassthroughSubject<Double, Never>()
    let strokeCountPublisher = PassthroughSubject<Int, Never>()
    let workoutStatePublisher = PassthroughSubject<Bool, Never>()
    let errorPublisher = PassthroughSubject<String, Never>()
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    func getCurrentWorkoutPoolLength() -> Double {
        return currentPoolLength
    }
    
    func requestAuthorization() -> Future<Bool, Error> {
        return Future { promise in
            let typesToRead: Set<HKObjectType> = [
                HKObjectType.quantityType(forIdentifier: .heartRate)!,
                HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
                HKObjectType.workoutType()
            ]
            
            let typesToShare: Set<HKSampleType> = [
                HKObjectType.workoutType()
            ]
            
            self.healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(success))
                }
            }
        }
    }
    
    func startWorkout(poolLength: Double = Constants.defaultPoolLength) {
        // Останавливаем существующую сессию, если есть
        if workoutSession != nil {
            print("[HealthKit] Остановка существующей сессии тренировки перед созданием новой")
            stopWorkout()
        }
        
        print("[HealthKit] Запуск новой тренировки с длиной бассейна: \(poolLength)м")
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
                    print("[HealthKit] Тренировка успешно запущена")
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
            print("[HealthKit] Попытка остановить несуществующую тренировку")
            return
        }
        
        print("[HealthKit] Остановка тренировки")
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
                    print("[HealthKit] Тренировка успешно завершена")
                    self.workoutStatePublisher.send(false)
                    self.workoutSession = nil
                    self.workoutBuilder = nil
                }
            }
        }
    }
    
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
    
    // MARK: - HKWorkoutSessionDelegate
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            print("[HealthKit] Изменение состояния тренировки: \(fromState.rawValue) -> \(toState.rawValue)")
            self.workoutStatePublisher.send(toState == .running)
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("[HealthKit] Ошибка тренировки: \(error.localizedDescription)")
        errorPublisher.send("Ошибка тренировки: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.workoutStatePublisher.send(false)
        }
    }
    
    // MARK: - HKLiveWorkoutBuilderDelegate
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
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Обработка событий тренировки
    }
}
