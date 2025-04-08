//
//  WatchSessionManager.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import Foundation
import WatchConnectivity
import CoreData
import HealthKit

protocol WatchDataDelegate: AnyObject {
    func didReceiveHeartRate(_ pulse: Int)
    func didReceiveStrokeCount(_ strokes: Int)
    func didReceiveWatchStatus(_ status: String)
}

protocol WorkoutCompletionDelegate: AnyObject {
    func didReceiveCompletedWorkout(_ completedWorkout: TransferWorkoutModels.TransferWorkoutInfo)
}

final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    weak var delegate: WatchDataDelegate?
    weak var workoutCompletionDelegate: WorkoutCompletionDelegate?
    private var isSessionActive = false
    
    private var currentPoolSize: Double = 25.0
    private var currentSwimmingStyle: Int = 0
    private var currentTotalMeters: Int = 0
    private var parametersExplicitlySet = false
    private var parametersConfirmed = false
    
    private let maxRetries = 3
    private var retryCount = 0
    
    private let healthStore = HKHealthStore()
    private struct HealthData {
        var strokesData: StrokesData
        var heartRateReadings: [HeartRateReading]
        var totalCalories: Double
    }
    
    private struct StrokesData {
        let totalStrokes: Int
        let lapStrokes: [Int]
    }
    
    private struct HeartRateReading {
        let timestamp: Date
        let value: Double
    }
    
    private struct ExerciseMetadata {
        let id: String
        let description: String?
        let style: Int
        let type: Int
        let hasInterval: Bool
        let intervalMinutes: Int
        let intervalSeconds: Int
        let meters: Int
        let repetitions: Int
        let orderIndex: Int
        let preciseStartTime: Date?
        let preciseEndTime: Date?
    }
    
    private override init() {
        super.init()
        startSession()
        requestHealthKitPermissions()
    }
    
    func startSession() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    private func requestHealthKitPermissions() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Ошибка получения разрешений HealthKit: \(String(describing: error))")
            } else {
                print("Разрешения HealthKit получены успешно")
            }
        }
    }
    
    func sendCommandToWatch(_ command: String) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["command": command], replyHandler: { _ in },
                                          errorHandler: { _ in })
        }
    }
    
    func sendTrainingParametersToWatch(poolSize: Double, style: Int, meters: Int) {
        self.currentPoolSize = poolSize
        self.currentSwimmingStyle = style
        self.currentTotalMeters = meters
        self.parametersConfirmed = false
        self.retryCount = 0
        self.parametersExplicitlySet = true
        
        sendParametersWithRetry()
    }
    
    func resetTrainingParameters() {
        parametersExplicitlySet = false
        parametersConfirmed = false
    }
    
    func sendWorkoutsToWatch() {
        if WCSession.default.activationState != .activated {
            WCSession.default.activate()
        }
        
        if WCSession.default.isReachable {
            // Получаем тренировки из CoreData
            let workoutEntities = CoreDataManager.shared.fetchAllWorkouts()
            
            if workoutEntities.isEmpty {
                return
            }
            
            let workoutsData = workoutEntities.map { entity -> [String: Any] in
                let exerciseEntities = entity.exercises?.allObjects as? [ExerciseEntity] ?? []
                let sortedExercises = exerciseEntities.sorted { ($0.orderIndex < $1.orderIndex) }
                
                let exercises = sortedExercises.map { exercise -> [String: Any] in
                    return [
                        "id": exercise.objectID.uriRepresentation().absoluteString,
                        "description": exercise.exerciseDescription ?? "",
                        "style": Int(exercise.style),
                        "type": Int(exercise.type),
                        "hasInterval": exercise.hasInterval,
                        "intervalMinutes": Int(exercise.intervalMinutes),
                        "intervalSeconds": Int(exercise.intervalSeconds),
                        "meters": Int(exercise.meters),
                        "orderIndex": Int(exercise.orderIndex),
                        "repetitions": Int(exercise.repetitions)
                    ]
                }
                
                return [
                    "id": entity.objectID.uriRepresentation().absoluteString,
                    "name": entity.name ?? "Без названия",
                    "poolSize": Int(entity.poolSize),
                    "exercises": exercises
                ]
            }
            
            // Отправляем данные тренировок на часы
            WCSession.default.sendMessage(["workoutsData": workoutsData], replyHandler: { _ in },
                                          errorHandler: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.sendWorkoutsToWatch()
                }
            })
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if WCSession.default.isReachable {
                    self?.sendWorkoutsToWatch()
                }
            }
        }
    }
    
    func activateSessionAndSendWorkouts() {
        if WCSession.default.activationState != .activated {
            WCSession.default.activate()
        }
        
        for delay in [0.5, 2.0, 5.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.sendWorkoutsToWatch()
            }
        }
    }
    
    // MARK: - Private Methods
    private func sendParametersWithRetry() {
        if WCSession.default.isReachable {
            let parameters: [String: Any] = [
                "poolSize": currentPoolSize,
                "swimmingStyle": currentSwimmingStyle,
                "totalMeters": currentTotalMeters
            ]
            
            WCSession.default.sendMessage(parameters, replyHandler: { [weak self] response in
                guard let self = self else { return }
                
                if let confirmation = response["parametersReceived"] as? Bool, confirmation {
                    self.parametersConfirmed = true
                }
            }, errorHandler: { [weak self] _ in
                guard let self = self else { return }
                
                self.retryCount += 1
                if self.retryCount < self.maxRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.sendParametersWithRetry()
                    }
                }
            })
        } else {
            retryCount += 1
            if retryCount < maxRetries {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.sendParametersWithRetry()
                }
            }
        }
    }
    
    // MARK: - Обработка данных о завершенной тренировке
    private func handleWorkoutCompletion(_ metadata: [String: Any]) {
        let actualMetadata = metadata["workoutMetadata"] as? [String: Any] ?? metadata
        let sendId = metadata["sendId"] as? String ?? UUID().uuidString
        
        guard let workoutId = actualMetadata["workoutId"] as? String,
              let workoutName = actualMetadata["workoutName"] as? String,
              let poolSize = actualMetadata["poolSize"] as? Int,
              let startTimeInterval = actualMetadata["startTime"] as? Double,
              let endTimeInterval = actualMetadata["endTime"] as? Double,
              let exercisesData = actualMetadata["exercises"] as? [[String: Any]] else {
            print("Ошибка: Некорректные метаданные тренировки")
            print("Полученные данные: \(actualMetadata)")
            sendWorkoutDataReceivedConfirmation(sendId: sendId)
            return
        }
        
        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let endTime = Date(timeIntervalSince1970: endTimeInterval)
        
        print("iPhone: Получены данные о завершенной тренировке. ID: \(workoutId), Период: \(startTime) - \(endTime)")
        
        // Проверяем наличие дубликата тренировки
        let existingWorkouts = fetchExistingWorkoutSessions(
            workoutId: workoutId,
            startTime: startTime
        )
        
        if !existingWorkouts.isEmpty {
            print("iPhone: Обнаружен дубликат тренировки, отправляем подтверждение")
            sendWorkoutDataReceivedConfirmation(sendId: sendId)
            return
        }
        
        let exercises = processExercisesMetadata(exercisesData)
        
        let totalLaps = exercises.reduce(0) { $0 + (($1.meters * $1.repetitions) / poolSize) }
        print("iPhone: Рассчитано общее количество отрезков: \(totalLaps)")
        
        queryHealthKitData(startTime: startTime, endTime: endTime, poolSize: Int16(poolSize), totalLaps: totalLaps) { [weak self] healthData in
            guard let self = self else { return }
            
            let processedExercises = self.distributeHealthData(
                exercises: exercises,
                healthData: healthData,
                poolSize: Int16(poolSize),
                startTime: startTime,
                endTime: endTime,
                totalLaps: totalLaps
            )
            
            CoreDataManager.shared.createWorkoutSession(
                date: startTime,
                totalTime: endTime.timeIntervalSince(startTime),
                totalCalories: healthData.totalCalories,
                poolSize: Int16(poolSize),
                workoutOriginalId: workoutId,
                workoutName: workoutName,
                exercisesData: processedExercises
            )
            
            print("iPhone: Тренировка сохранена в CoreData с обработанными данными о здоровье")
            
            let transferExercises = processedExercises.map { exercise -> TransferWorkoutModels.TransferExerciseInfo in
                
                let transferLaps = exercise.laps.map { lap -> TransferWorkoutModels.TransferLapInfo in
                    return TransferWorkoutModels.TransferLapInfo.create(
                        timestamp: lap.timestamp,
                        lapNumber: lap.lapNumber,
                        exerciseId: exercise.exerciseId,
                        distance: Int(lap.distance),
                        lapTime: lap.lapTime,
                        heartRate: lap.heartRate,
                        strokes: Int(lap.strokes)
                    )
                }
                
                return TransferWorkoutModels.TransferExerciseInfo.create(
                    exerciseId: exercise.exerciseId,
                    orderIndex: exercise.orderIndex,
                    description: exercise.description,
                    style: exercise.style,
                    type: exercise.type,
                    hasInterval: exercise.hasInterval,
                    intervalMinutes: exercise.intervalMinutes,
                    intervalSeconds: exercise.intervalSeconds,
                    meters: Int(exercise.meters),
                    repetitions: Int(exercise.repetitions),
                    startTime: exercise.startTime,
                    endTime: exercise.endTime,
                    laps: transferLaps
                )
            }
            
            let transferWorkout = TransferWorkoutModels.TransferWorkoutInfo.create(
                workoutId: workoutId,
                workoutName: workoutName,
                poolSize: poolSize,
                startTime: startTime,
                endTime: endTime,
                totalCalories: healthData.totalCalories,
                exercises: transferExercises
            )
            
            DispatchQueue.main.async {
                self.workoutCompletionDelegate?.didReceiveCompletedWorkout(transferWorkout)
                self.sendWorkoutDataReceivedConfirmation(sendId: sendId)
            }
        }
    }
    
    private func processExercisesMetadata(_ exercises: [[String: Any]]) -> [ExerciseMetadata] {
        return exercises.compactMap { exercise in
            guard let id = exercise["exerciseId"] as? String,
                  let style = exercise["style"] as? Int,
                  let type = exercise["type"] as? Int,
                  let hasInterval = exercise["hasInterval"] as? Bool,
                  let intervalMinutes = exercise["intervalMinutes"] as? Int,
                  let intervalSeconds = exercise["intervalSeconds"] as? Int,
                  let meters = exercise["meters"] as? Int,
                  let repetitions = exercise["repetitions"] as? Int,
                  let orderIndex = exercise["orderIndex"] as? Int else {
                return nil
            }
            
            // Извлекаем точные временные метки, если они есть
            var preciseStartTime: Date? = nil
            if let startTimeInterval = exercise["preciseStartTime"] as? TimeInterval {
                preciseStartTime = Date(timeIntervalSince1970: startTimeInterval)
            }
            
            var preciseEndTime: Date? = nil
            if let endTimeInterval = exercise["preciseEndTime"] as? TimeInterval {
                preciseEndTime = Date(timeIntervalSince1970: endTimeInterval)
            }
            
            return ExerciseMetadata(
                id: id,
                description: exercise["description"] as? String,
                style: style,
                type: type,
                hasInterval: hasInterval,
                intervalMinutes: intervalMinutes,
                intervalSeconds: intervalSeconds,
                meters: meters,
                repetitions: repetitions,
                orderIndex: orderIndex,
                preciseStartTime: preciseStartTime,
                preciseEndTime: preciseEndTime
            )
        }
    }
    
    // MARK: - HealthKit запросы
    private func queryHealthKitData(startTime: Date, endTime: Date, poolSize: Int16, totalLaps: Int, completion: @escaping (HealthData) -> Void) {
        let group = DispatchGroup()
        
        var strokesData = StrokesData(totalStrokes: 0, lapStrokes: [])
        var heartRateReadings: [HeartRateReading] = []
        var totalCalories: Double = 0
        
        group.enter()
        queryStrokeCount(from: startTime, to: endTime, totalLaps: totalLaps) { strokeCount, lapStrokesData in
            strokesData = StrokesData(totalStrokes: strokeCount, lapStrokes: lapStrokesData)
            group.leave()
        }
        
        group.enter()
        queryHeartRate(from: startTime, to: endTime) { readings in
            heartRateReadings = readings
            group.leave()
        }
        
        group.enter()
        queryActiveEnergyBurned(from: startTime, to: endTime) { calories in
            totalCalories = calories
            group.leave()
        }
        
        group.notify(queue: .main) {
            let healthData = HealthData(
                strokesData: strokesData,
                heartRateReadings: heartRateReadings,
                totalCalories: totalCalories
            )
            completion(healthData)
        }
    }
    
    private func queryStrokeCount(from startDate: Date, to endDate: Date, totalLaps: Int, completion: @escaping (Int, [Int]) -> Void) {
        guard let strokeType = HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount) else {
            completion(0, [])
            return
        }
        
        print("iPhone: Запрашиваем данные гребков за период \(startDate) - \(endDate), ожидаем \(totalLaps) отрезков")
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let statsQuery = HKStatisticsQuery(
            quantityType: strokeType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            var totalStrokes = 0
            
            if let error = error {
                print("iPhone: Ошибка запроса статистики гребков: \(error.localizedDescription)")
            }
            
            if let sum = result?.sumQuantity() {
                totalStrokes = Int(sum.doubleValue(for: HKUnit.count()))
                print("iPhone: Найдено общее количество гребков: \(totalStrokes)")
            }
            
            let sampleQuery = HKSampleQuery(
                sampleType: strokeType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                var lapStrokes: [Int] = []
                
                if let error = error {
                    print("iPhone: Ошибка запроса образцов гребков: \(error.localizedDescription)")
                }
                
                if let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty {
                    // Сортируем образцы по времени
                    let sortedSamples = quantitySamples.sorted { $0.startDate < $1.startDate }
                    
                    lapStrokes = sortedSamples.map { Int($0.quantity.doubleValue(for: HKUnit.count())) }
                    print("iPhone: Получены данные о гребках по отрезкам: \(lapStrokes.count) записей")
                    
                    if lapStrokes.count > totalLaps {
                        print("iPhone: Количество записей о гребках (\(lapStrokes.count)) больше чем отрезков (\(totalLaps)), берем последние \(totalLaps)")
                        lapStrokes = Array(lapStrokes.suffix(totalLaps))
                    } else if lapStrokes.count < totalLaps {
                        print("iPhone: Количество записей о гребках (\(lapStrokes.count)) меньше чем отрезков (\(totalLaps)), дополняем")
                        let missingLaps = totalLaps - lapStrokes.count
                        let avgStrokes = lapStrokes.isEmpty ? 20 : (lapStrokes.reduce(0, +) / lapStrokes.count)
                        let additionalLaps = Array(repeating: avgStrokes, count: missingLaps)
                        lapStrokes.append(contentsOf: additionalLaps)
                    }
                } else {
                    print("iPhone: Нет детальных данных о гребках, распределяем \(totalStrokes) гребков по \(totalLaps) отрезкам")
                    let strokesPerLap = totalStrokes / totalLaps
                    let extraStrokes = totalStrokes % totalLaps
                    
                    lapStrokes = Array(repeating: strokesPerLap, count: totalLaps)
                    
                    for i in 0..<extraStrokes {
                        lapStrokes[i] += 1
                    }
                }
                
                DispatchQueue.main.async {
                    completion(totalStrokes, lapStrokes)
                }
            }
            
            self.healthStore.execute(sampleQuery)
        }
        healthStore.execute(statsQuery)
    }
    
    private func queryHeartRate(from startDate: Date, to endDate: Date, completion: @escaping ([HeartRateReading]) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            completion([])
            return
        }
        
        let extendedStartTime = startDate.addingTimeInterval(-5.0)
        let extendedEndTime = endDate.addingTimeInterval(5.0)
        
        print("iPhone: Запрашиваем данные пульса за период \(extendedStartTime) - \(extendedEndTime)")
        
        let predicate = HKQuery.predicateForSamples(withStart: extendedStartTime, end: extendedEndTime, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: predicate,
            limit: 700,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            var readings: [HeartRateReading] = []
            
            if let error = error {
                print("iPhone: Ошибка запроса данных пульса: \(error.localizedDescription)")
            }
            
            if let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty {
                readings = quantitySamples.map { sample in
                    let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                    let value = sample.quantity.doubleValue(for: heartRateUnit)
                    return HeartRateReading(timestamp: sample.startDate, value: value)
                }
                print("iPhone: Получены данные о пульсе: \(readings.count) записей")
            } else {
                print("iPhone: Данные о пульсе отсутствуют, возвращаем пустой массив")
            }
            
            DispatchQueue.main.async {
                completion(readings)
            }
        }
        
        healthStore.execute(query)
    }
    
    private func queryActiveEnergyBurned(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(0)
            return
        }
        
        print("iPhone: Запрашиваем данные о сожженных калориях за период \(startDate) - \(endDate)")
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
        
        let query = HKStatisticsQuery(
            quantityType: energyType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, error in
            var totalCalories = 0.0
            
            if let error = error {
                print("iPhone: Ошибка запроса данных о калориях: \(error.localizedDescription)")
            }
            
            if let sum = result?.sumQuantity() {
                totalCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                print("iPhone: Получены данные о калориях: \(totalCalories) ккал")
            } else {
                let duration = endDate.timeIntervalSince(startDate) / 60.0
                totalCalories = duration * 10.0
                print("iPhone: Расчетное количество калорий: \(totalCalories) ккал")
            }
            
            DispatchQueue.main.async {
                completion(totalCalories)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Распределение данных
    private func distributeHealthData(
        exercises: [ExerciseMetadata],
        healthData: HealthData,
        poolSize: Int16,
        startTime: Date,
        endTime: Date,
        totalLaps: Int
    ) -> [CompletedExerciseData] {
        var completedExercises: [CompletedExerciseData] = []
        
        let sortedExercises = exercises.sorted { $0.orderIndex < $1.orderIndex }
        let sortedHeartRates = healthData.heartRateReadings.sorted { $0.timestamp < $1.timestamp }
        let totalDistance = sortedExercises.reduce(0) { $0 + ($1.meters * $1.repetitions) }
        
        var strokesIndex = 0
        var heartRateIndex = 0
        var currentTime = startTime
        var totalPreciseTime: TimeInterval = 0
        var exercisesWithPreciseTime: [ExerciseMetadata] = []
        for exercise in sortedExercises {
            if let preciseStartTime = exercise.preciseStartTime, let preciseEndTime = exercise.preciseEndTime {
                totalPreciseTime += preciseEndTime.timeIntervalSince(preciseStartTime)
                exercisesWithPreciseTime.append(exercise)
            }
        }
        print("iPhone: Найдено \(exercisesWithPreciseTime.count) упражнений с точными временными метками")
        print("iPhone: Общая продолжительность упражнений с точными метками: \(totalPreciseTime) сек")
        for exercise in sortedExercises {
            let exerciseLaps = (exercise.meters * exercise.repetitions) / Int(poolSize)
            let exerciseDistanceProportion = Double(exercise.meters * exercise.repetitions) / Double(totalDistance)
            
            let exerciseStartTime: Date
            let exerciseEndTime: Date
            if let preciseStartTime = exercise.preciseStartTime, let preciseEndTime = exercise.preciseEndTime {
                exerciseStartTime = preciseStartTime
                exerciseEndTime = preciseEndTime
                print("iPhone: Использую точные метки для упражнения \(exercise.id): \(preciseStartTime) - \(preciseEndTime)")
            } else {
                exerciseStartTime = currentTime
                let isLastExercise = exercise.orderIndex == sortedExercises.last?.orderIndex
                if isLastExercise {
                    exerciseEndTime = endTime
                } else {
                    let exerciseProportion = Double(exerciseLaps) / Double(totalLaps)
                    let exerciseDuration = endTime.timeIntervalSince(startTime) * exerciseProportion
                    exerciseEndTime = exerciseStartTime.addingTimeInterval(exerciseDuration)
                }
                print("iPhone: Для упражнения \(exercise.id) расчетные временные рамки: \(exerciseStartTime) - \(exerciseEndTime)")
            }
            
            let heartRatesForExercise: [HeartRateReading]
            if !sortedHeartRates.isEmpty {
                let startIndex = heartRateIndex
                let heartRatesCount = sortedHeartRates.count
                let exerciseHeartRatesCount = Int(Double(heartRatesCount) * exerciseDistanceProportion)
                let endIndex = min(startIndex + exerciseHeartRatesCount, heartRatesCount)
                heartRatesForExercise = Array(sortedHeartRates[startIndex..<endIndex])
                heartRateIndex = endIndex
                
                print("iPhone: Для упражнения с дистанцией \(exercise.meters * exercise.repetitions)м (\(exerciseDistanceProportion * 100)% тренировки) выделено \(heartRatesForExercise.count) показаний пульса")
            } else {
                heartRatesForExercise = []
            }

            let exerciseDuration = exerciseEndTime.timeIntervalSince(exerciseStartTime)
            var lapsData: [CompletedLapData] = []
            for lap in 1...exerciseLaps {
                let strokesValue: Int
                if strokesIndex < healthData.strokesData.lapStrokes.count {
                    strokesValue = healthData.strokesData.lapStrokes[strokesIndex]
                    strokesIndex += 1
                } else {
                    strokesValue = healthData.strokesData.totalStrokes / totalLaps
                }
                
                let lapTime = exerciseDuration / Double(exerciseLaps)
                let lapStart = exerciseStartTime.addingTimeInterval(lapTime * Double(lap - 1))
                let heartRate: Double
                if !heartRatesForExercise.isEmpty {
                    let lapHeartRateProportion = 1.0 / Double(exerciseLaps)
                    let startHRIndex = Int(Double(heartRatesForExercise.count) * lapHeartRateProportion * Double(lap - 1))
                    let endHRIndex = Int(Double(heartRatesForExercise.count) * lapHeartRateProportion * Double(lap))
                    let lapHeartRates = heartRatesForExercise[safe: startHRIndex..<min(endHRIndex, heartRatesForExercise.count)]
                    
                    if !lapHeartRates.isEmpty {
                        let sum = lapHeartRates.reduce(0) { $0 + $1.value }
                        heartRate = sum / Double(lapHeartRates.count)
                    } else if !heartRatesForExercise.isEmpty {
                        let sum = heartRatesForExercise.reduce(0) { $0 + $1.value }
                        heartRate = sum / Double(heartRatesForExercise.count)
                    } else {
                        heartRate = 0
                    }
                } else {
                    heartRate = 0
                }
                
                lapsData.append(CompletedLapData(
                    lapNumber: lap,
                    distance: Int(poolSize),
                    lapTime: lapTime,
                    heartRate: heartRate,
                    strokes: strokesValue,
                    timestamp: lapStart
                ))
            }
            
            let completedExercise = CompletedExerciseData(
                exerciseId: exercise.id,
                orderIndex: exercise.orderIndex,
                description: exercise.description,
                style: exercise.style,
                type: exercise.type,
                hasInterval: exercise.hasInterval,
                intervalMinutes: exercise.intervalMinutes,
                intervalSeconds: exercise.intervalSeconds,
                meters: exercise.meters,
                repetitions: exercise.repetitions,
                startTime: exerciseStartTime,
                endTime: exerciseEndTime,
                laps: lapsData,
                heartRateReadings: heartRatesForExercise.map { (value: $0.value, timestamp: $0.timestamp) }
            )
            
            completedExercises.append(completedExercise)
            if exercise.preciseEndTime == nil {
                currentTime = exerciseEndTime
            }
        }
        
        return completedExercises
    }
    
    private func fetchExistingWorkoutSessions(workoutId: String, startTime: Date) -> [WorkoutSessionEntity] {
        let request: NSFetchRequest<WorkoutSessionEntity> = WorkoutSessionEntity.fetchRequest()
        let calendar = Calendar.current
        let startRange = calendar.date(byAdding: .second, value: -10, to: startTime)!
        let endRange = calendar.date(byAdding: .second, value: 10, to: startTime)!
        
        let predicate = NSPredicate(format: "workoutOriginalId == %@ AND date >= %@ AND date <= %@",
                                    workoutId, startRange as NSDate, endRange as NSDate)
        request.predicate = predicate
        
        do {
            return try CoreDataManager.shared.context.fetch(request)
        } catch {
            print("Error fetching existing workout sessions: \(error)")
            return []
        }
    }
    
    // Отправка подтверждения получения данных на часы
    private func sendWorkoutDataReceivedConfirmation(sendId: String) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(
                [
                    "workoutDataReceived": true,
                    "sendId": sendId
                ],
                replyHandler: { response in
                    print("Watch confirmed receipt of our confirmation")
                },
                errorHandler: { error in
                    print("Error sending confirmation to watch: \(error.localizedDescription)")
                }
            )
        }
    }
    
    // MARK: - WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isSessionActive = activationState == .activated
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            print("iPhone: Получено сообщение от часов \(message.keys)")
            
            if let heartRate = message["heartRate"] as? Int {
                self.delegate?.didReceiveHeartRate(heartRate)
            }
            
            if let strokeCount = message["strokeCount"] as? Int {
                self.delegate?.didReceiveStrokeCount(strokeCount)
            }
            
            if let watchStatus = message["watchStatus"] as? String {
                print("iPhone: Получен статус от часов: \(watchStatus)")
                
                self.delegate?.didReceiveWatchStatus(watchStatus)
                if watchStatus == "stopped" || watchStatus == "workoutStopped" {
                    self.resetTrainingParameters()
                }
            }
            
            if message["workoutCompleted"] as? Bool == true,
               let workoutMetadata = message["workoutMetadata"] as? [String: Any] {
                print("iPhone: Получены данные о завершенной тренировке для обработки")
                self.handleWorkoutCompletion(workoutMetadata)
            }
            
            if let completedWorkoutData = message["completedWorkoutData"] as? [String: Any] {
                let shouldSaveWorkout = message["shouldSaveWorkout"] as? Bool ?? true
                
                if shouldSaveWorkout {
                    print("iPhone: Получены данные о завершенной тренировке для сохранения (старый формат)")
                    self.handleCompletedWorkoutData(completedWorkoutData)
                } else {
                    print("iPhone: Получены данные о тренировке, но shouldSaveWorkout=false")
                }
            }
            
            if let parametersReceived = message["parametersReceived"] as? Bool, parametersReceived {
                self.parametersConfirmed = true
            }
            
            if message["requestWorkouts"] != nil {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.sendWorkoutsToWatch()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.sendWorkoutsToWatch()
                    }
                }
            }
        }
    }
    
    // Обработка сообщений с ожиданием ответа
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            if message["requestPoolLength"] != nil {
                if self.parametersExplicitlySet {
                    replyHandler(["poolLength": self.currentPoolSize])
                } else {
                    replyHandler(["parametersNotSet": true])
                }
            }
            else if message["requestAllParameters"] != nil {
                if self.parametersExplicitlySet {
                    let responseParams: [String: Any] = [
                        "poolSize": self.currentPoolSize,
                        "swimmingStyle": self.currentSwimmingStyle,
                        "totalMeters": self.currentTotalMeters
                    ]
                    replyHandler(responseParams)
                } else {
                    replyHandler(["parametersNotSet": true])
                }
            }
            else if message["requestWorkouts"] != nil {
                replyHandler(["received": true, "processing": true])
                
                DispatchQueue.global(qos: .userInitiated).async {
                    let workoutEntities = CoreDataManager.shared.fetchAllWorkouts()
                    
                    if workoutEntities.isEmpty {
                        return
                    }
                    
                    let workoutsData = workoutEntities.map { entity -> [String: Any] in
                        let exerciseEntities = entity.exercises?.allObjects as? [ExerciseEntity] ?? []
                        let sortedExercises = exerciseEntities.sorted { ($0.orderIndex < $1.orderIndex) }
                        let exercises = sortedExercises.map { exercise -> [String: Any] in
                            return [
                                "id": exercise.objectID.uriRepresentation().absoluteString,
                                "description": exercise.exerciseDescription ?? "",
                                "style": Int(exercise.style),
                                "type": Int(exercise.type),
                                "hasInterval": exercise.hasInterval,
                                "intervalMinutes": Int(exercise.intervalMinutes),
                                "intervalSeconds": Int(exercise.intervalSeconds),
                                "meters": Int(exercise.meters),
                                "orderIndex": Int(exercise.orderIndex),
                                "repetitions": Int(exercise.repetitions)
                            ]
                        }
                        
                        return [
                            "id": entity.objectID.uriRepresentation().absoluteString,
                            "name": entity.name ?? "Без названия",
                            "poolSize": Int(entity.poolSize),
                            "exercises": exercises
                        ]
                    }
                    
                    WCSession.default.sendMessage(["workoutsData": workoutsData], replyHandler: { _ in },
                                                  errorHandler: { _ in
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            WCSession.default.sendMessage(["workoutsData": workoutsData], replyHandler: { _ in },
                                                          errorHandler: { _ in })
                        }
                    })
                }
            }
            else if message["workoutCompleted"] != nil {
                replyHandler(["workoutDataReceived": true])
                self.session(session, didReceiveMessage: message)
            }
            else {
                replyHandler(["received": true])
                
                self.session(session, didReceiveMessage: message)
            }
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            if session.isReachable {
                DispatchQueue.global(qos: .userInteractive).async {
                    self.sendWorkoutsToWatch()
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        isSessionActive = false
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        isSessionActive = false
        WCSession.default.activate()
    }
    
    // MARK: - Для обратной совместимости
    private func handleCompletedWorkoutData(_ data: [String: Any]) {
        if let transferWorkout = TransferWorkoutModels.TransferWorkoutInfo.fromDictionary(data) {
            let sendId = data["sendId"] as? String ?? UUID().uuidString
            let existingWorkouts = fetchExistingWorkoutSessions(
                workoutId: transferWorkout.workoutId,
                startTime: transferWorkout.startTime
            )
            
            if existingWorkouts.isEmpty {
                print("iPhone: Сохраняем новую тренировку с временем: \(transferWorkout.totalTime)")
                
                CoreDataManager.shared.createWorkoutSession(
                    date: transferWorkout.startTime,
                    totalTime: transferWorkout.totalTime,
                    totalCalories: transferWorkout.totalCalories,
                    poolSize: Int16(transferWorkout.poolSize),
                    workoutOriginalId: transferWorkout.workoutId,
                    workoutName: transferWorkout.workoutName,
                    exercisesData: convertToCompletedExerciseData(transferWorkout.exercises)
                )
                
                workoutCompletionDelegate?.didReceiveCompletedWorkout(transferWorkout)
            } else {
                print("iPhone: Дубликат тренировки, игнорируем. Время: \(transferWorkout.totalTime)")
            }
            sendWorkoutDataReceivedConfirmation(sendId: sendId)
        }
    }
    
    // Преобразование данных о упражнениях для CoreDataManager
    private func convertToCompletedExerciseData(_ exercises: [TransferWorkoutModels.TransferExerciseInfo]) -> [CompletedExerciseData] {
        return exercises.map { exercise in
            let completedLapDataArray = exercise.laps.map { lap in
                return CompletedLapData(
                    lapNumber: lap.lapNumber,
                    distance: lap.distance,
                    lapTime: lap.lapTime,
                    heartRate: lap.heartRate,
                    strokes: Int(lap.strokes),
                    timestamp: lap.timestamp
                )
            }
            
            return CompletedExerciseData(
                exerciseId: exercise.exerciseId,
                orderIndex: exercise.orderIndex,
                description: exercise.description,
                style: exercise.style,
                type: exercise.type,
                hasInterval: exercise.hasInterval,
                intervalMinutes: exercise.intervalMinutes,
                intervalSeconds: exercise.intervalSeconds,
                meters: exercise.meters,
                repetitions: exercise.repetitions,
                startTime: exercise.startTime,
                endTime: exercise.endTime,
                laps: completedLapDataArray
            )
        }
    }
}

extension Array {
    subscript(safe range: Range<Index>) -> ArraySlice<Element> {
        if range.lowerBound >= self.count {
            return []
        }
        
        let lower = range.lowerBound
        let upper = Swift.min(range.upperBound, self.count)
        return self[lower..<upper]
    }
}
