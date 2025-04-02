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
        
        print("DEBUG: Запрашиваем данные гребков за период \(startDate) - \(endDate)")
        
        // Создаем предикат для временного периода
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        let interval = DateComponents(second: 0, nanosecond: 100000000)
        
        // Используем HKStatisticsCollectionQuery для получения суммы гребков
        let query = HKStatisticsCollectionQuery(
            quantityType: strokeType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )
        
        query.initialResultsHandler = { query, results, error in
            var totalStrokes = 0.0
            
            if let error = error {
                print("DEBUG: Ошибка запроса данных HealthKit: \(error.localizedDescription)")
            }
            
            if let statsCollection = results {
                print("DEBUG: Получена коллекция статистики HealthKit")
                
                statsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, stop in
                    if let sumQuantity = statistics.sumQuantity() {
                        let value = sumQuantity.doubleValue(for: HKUnit.count())
                        if value > 0 {
                            totalStrokes = max(totalStrokes, value)
                            print("DEBUG: Найдено значение гребков: \(value) на \(statistics.startDate)")
                        }
                    }
                }
            } else {
                print("DEBUG: Не удалось получить коллекцию статистики")
            }
            
            DispatchQueue.main.async {
                print("DEBUG: Итоговое количество гребков: \(Int(totalStrokes))")
                completion(Int(totalStrokes))
            }
        }
        
        // Запускаем запрос
        healthStore.execute(query)
        print("DEBUG: Запрос данных HealthKit запущен")
        
        // Еще один запрос с использованием HKSampleQuery для дополнительной надежности
        let sampleQuery = HKSampleQuery(
            sampleType: strokeType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { query, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else {
                print("DEBUG: Ошибка запроса образцов HealthKit: \(String(describing: error))")
                return
            }
            
            let totalFromSamples = samples.reduce(0.0) { total, sample in
                return total + sample.quantity.doubleValue(for: HKUnit.count())
            }
            
            print("DEBUG: Количество гребков из образцов: \(Int(totalFromSamples))")
            
            if totalFromSamples > 0 {
                DispatchQueue.main.async {
                    completion(Int(totalFromSamples))
                }
            }
        }
        
        healthStore.execute(sampleQuery)
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
                if let value = statistics?.sumQuantity()?.doubleValue(for: strokeUnit) {
                    let newCount = Int(value)
                    
                    // Определяем, был ли это новый отрезок, с более точной логикой
                    let strokeDifference = value - self.lastStrokeCount
                    if strokeDifference == 0 || self.lastStrokeCount == 0 {
                        // Первое измерение или нет изменений
                    } else {
                        // Сохраняем новое значение в любом случае
                        DispatchQueue.main.async {
                            self.strokeCountPublisher.send(newCount)
                        }
                        
                        // Для определения завершения отрезка используем более точные критерии
                        if workoutBuilder.workoutEvents.contains(where: { $0.type == .lap }) {
                            // Обработка будет в workoutBuilderDidCollectEvent
                        } else if strokeDifference < 5 && strokeDifference > 0 && self.lastStrokeCount > 10 {
                            // Это может указывать на новый отрезок - небольшое количество новых гребков
                            // после значительного количества предыдущих
                            self.lapCounter += 1
                            self.lapCompletedPublisher.send(self.lapCounter)
                        }
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
        
        print("DEBUG: Получено \(workoutEvents.count) событий тренировки")
        
        // Проверяем на наличие новых событий отрезка
        for event in workoutEvents {
            let eventTimeStamp = event.dateInterval.start.timeIntervalSince1970
            
            // Если событие уже обработано, пропускаем его
            if processedEventTimestamps.contains(eventTimeStamp) {
                continue
            }
            
            print("DEBUG: Новое событие типа \(event.type.rawValue) в \(event.dateInterval.start)")
            
            // Обрабатываем событие отрезка
            if event.type == .lap {
                self.lapCounter += 1
                print("DEBUG: Зарегистрировано событие LAP #\(self.lapCounter)")
                
                DispatchQueue.main.async {
                    self.lapCompletedPublisher.send(self.lapCounter)
                }
            }
            
            // Помечаем событие как обработанное
            processedEventTimestamps.insert(eventTimeStamp)
        }
    }
}
