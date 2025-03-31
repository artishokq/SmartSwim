//
//  WorkoutKitManager.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 29.03.2025.
//

import Foundation
import HealthKit
import Combine

final class WorkoutKitManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    // MARK: - Singleton
    static let shared = WorkoutKitManager()
    
    // MARK: - Publishers
    let heartRatePublisher = PassthroughSubject<Double, Never>()
    let strokeCountPublisher = PassthroughSubject<Int, Never>()
    let caloriesPublisher = PassthroughSubject<Double, Never>()
    let workoutStatePublisher = PassthroughSubject<Bool, Never>()
    let errorPublisher = PassthroughSubject<String, Never>()
    let lapCompletedPublisher = PassthroughSubject<Int, Never>()
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var processedEventTimestamps = Set<TimeInterval>()
    
    private var lastStrokeCount: Double = 0
    private var currentPoolLength: Double = 25.0
    private var strokesByExercise: [String: Int] = [:]
    private var lapCounter: Int = 0
    
    // MARK: - Initialization
    private override init() {
        super.init()
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
    
    func resetStrokeCountForExercise(_ exerciseId: String) {
        strokesByExercise[exerciseId] = Int(lastStrokeCount)
    }
    
    func getStrokeCountForExercise(_ exerciseId: String) -> Int {
        let baseCount = strokesByExercise[exerciseId] ?? 0
        let currentCount = Int(lastStrokeCount) - baseCount
        return max(0, currentCount)
    }
    
    func getWorkoutTotalCalories() -> Double {
        guard let builder = workoutBuilder else { return 0 }
        
        let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        if let statistics = builder.statistics(for: calorieType),
           let calories = statistics.sumQuantity() {
            return calories.doubleValue(for: HKUnit.kilocalorie())
        }
        
        return 0
    }
    
    func getTotalStrokeCount() -> Int {
        return Int(lastStrokeCount)
    }
    
    func queryFinalStrokeCount(from startDate: Date, to endDate: Date, completion: @escaping (Int) -> Void) {
        guard let strokeType = HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount) else {
            completion(0)
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let interval = DateComponents(second: 1)
        let query = HKStatisticsCollectionQuery(quantityType: strokeType,
                                                quantitySamplePredicate: predicate,
                                                options: .cumulativeSum,
                                                anchorDate: startDate,
                                                intervalComponents: interval)
        query.initialResultsHandler = { query, results, error in
            var totalStrokes = 0.0
            if let statsCollection = results {
                statsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    if let sumQuantity = statistics.sumQuantity() {
                        totalStrokes += sumQuantity.doubleValue(for: HKUnit.count())
                    }
                }
            }
            DispatchQueue.main.async {
                completion(Int(totalStrokes))
            }
        }
        healthStore.execute(query)
    }
    
    
    func startWorkout(workout: SwimWorkoutModels.SwimWorkout) {
        // Останавливаем существующую сессию, если есть
        if workoutSession != nil {
            stopWorkout()
        }
        
        currentPoolLength = Double(workout.poolSize)
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .swimming
        configuration.locationType = .indoor
        configuration.swimmingLocationType = .pool
        configuration.lapLength = HKQuantity(unit: HKUnit.meter(), doubleValue: currentPoolLength)
        
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
            
        } catch {
            errorPublisher.send("Ошибка создания сессии тренировки: \(error.localizedDescription)")
        }
    }
    
    func stopWorkout() {
        guard let workoutSession = workoutSession else {
            return
        }
        
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
    
    // MARK: - HKWorkoutSessionDelegate
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
                    
                    // Определяем, был ли это новый отрезок
                    let strokeDifference = value - self.lastStrokeCount
                    if strokeDifference == 0 || self.lastStrokeCount == 0 {
                        // Первое измерение или нет изменений
                    } else if strokeDifference < 3 {
                        // Малое количество гребков может означать завершение отрезка и начало нового (остановка, разворот и продолжение)
                        self.lapCounter += 1
                        self.lapCompletedPublisher.send(self.lapCounter)
                    }
                    
                    DispatchQueue.main.async {
                        self.strokeCountPublisher.send(newCount)
                    }
                    self.lastStrokeCount = value
                }
            }
            else if quantityType.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue {
                let calorieUnit = HKUnit.kilocalorie()
                if let value = statistics?.sumQuantity()?.doubleValue(for: calorieUnit) {
                    DispatchQueue.main.async {
                        self.caloriesPublisher.send(value)
                    }
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Получаем массив событий тренировки
        let workoutEvents = workoutBuilder.workoutEvents
        
        // Проверяем на наличие новых событий отрезка
        for event in workoutEvents {
            let eventTimeStamp = event.dateInterval.start.timeIntervalSince1970
            
            // Если событие уже обработано, пропускаем его
            if processedEventTimestamps.contains(eventTimeStamp) {
                continue
            }
            
            // Обрабатываем событие отрезка
            if event.type == .lap {
                self.lapCounter += 1
                DispatchQueue.main.async {
                    self.lapCompletedPublisher.send(self.lapCounter)
                }
            }
            
            // Помечаем событие как обработанное
            processedEventTimestamps.insert(eventTimeStamp)
        }
    }
}
