//
//  WatchSessionManager.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import WatchConnectivity
import Foundation
import CoreData

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
    
    // Хранение текущих параметров тренировки
    private var currentPoolSize: Double = 25.0
    private var currentSwimmingStyle: Int = 0
    private var currentTotalMeters: Int = 0
    private var parametersExplicitlySet = false
    
    // Индикатор подтверждения получения параметров
    private var parametersConfirmed = false
    
    // Максимальное количество попыток отправки параметров
    private let maxRetries = 3
    private var retryCount = 0
    
    private override init() {
        super.init()
        startSession()
    }
    
    func startSession() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendCommandToWatch(_ command: String) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["command": command], replyHandler: { _ in },
                                          errorHandler: { _ in })
        }
    }
    
    // Метод для отправки всех параметров тренировки на часы с подтверждением
    func sendTrainingParametersToWatch(poolSize: Double, style: Int, meters: Int) {
        // Сохраняем параметры локально
        self.currentPoolSize = poolSize
        self.currentSwimmingStyle = style
        self.currentTotalMeters = meters
        self.parametersConfirmed = false
        self.retryCount = 0
        self.parametersExplicitlySet = true
        
        // Запускаем процесс отправки
        sendParametersWithRetry()
    }
    
    // Метод для сброса параметров
    func resetTrainingParameters() {
        parametersExplicitlySet = false
        parametersConfirmed = false
    }
    
    // Метод для отправки списка тренировок на Apple Watch
    func sendWorkoutsToWatch() {
        // Перед отправкой проверяем и пытаемся активировать соединение
        if WCSession.default.activationState != .activated {
            WCSession.default.activate()
        }
        
        if WCSession.default.isReachable {
            // Получаем тренировки из CoreData
            let workoutEntities = CoreDataManager.shared.fetchAllWorkouts()
            
            if workoutEntities.isEmpty {
                return
            }
            
            // Преобразуем в словари для передачи
            let workoutsData = workoutEntities.map { entity -> [String: Any] in
                // Получаем упражнения для этой тренировки и сортируем их по порядку
                let exerciseEntities = entity.exercises?.allObjects as? [ExerciseEntity] ?? []
                let sortedExercises = exerciseEntities.sorted { ($0.orderIndex < $1.orderIndex) }
                
                // Преобразуем упражнения в словари
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
                
                // Создаем словарь тренировки
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
                // Пробуем отправить еще раз через небольшую задержку
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.sendWorkoutsToWatch()
                }
            })
        } else {
            // Вторая попытка с задержкой
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if WCSession.default.isReachable {
                    self?.sendWorkoutsToWatch()
                }
            }
        }
    }
    
    func activateSessionAndSendWorkouts() {
        // Если сессия не активна, активируем её
        if WCSession.default.activationState != .activated {
            WCSession.default.activate()
        }
        
        // Независимо от состояния сессии, пробуем отправить тренировки через короткие промежутки времени
        for delay in [0.5, 2.0, 5.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.sendWorkoutsToWatch()
            }
        }
    }
    
    // MARK: - Private Methods
    // Метод для отправки параметров с возможностью повторных попыток
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
                
                // Повторная попытка отправки
                self.retryCount += 1
                if self.retryCount < self.maxRetries {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.sendParametersWithRetry()
                    }
                }
            })
        } else {
            // Повторная попытка
            retryCount += 1
            if retryCount < maxRetries {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.sendParametersWithRetry()
                }
            }
        }
    }
    
    private func handleCompletedWorkoutData(_ data: [String: Any]) {
        if let transferWorkout = TransferWorkoutModels.TransferWorkoutInfo.fromDictionary(data) {
            let sendId = data["sendId"] as? String ?? UUID().uuidString
            
            // Проверяем, получали ли мы уже эту тренировку
            let existingWorkouts = fetchExistingWorkoutSessions(
                workoutId: transferWorkout.workoutId,
                startTime: transferWorkout.startTime
            )
            
            if existingWorkouts.isEmpty {
                print("iPhone: Сохраняем новую тренировку с временем: \(transferWorkout.totalTime)")
                
                // Сохраняем в CoreData
                CoreDataManager.shared.createWorkoutSession(
                    date: transferWorkout.startTime,
                    totalTime: transferWorkout.totalTime,
                    totalCalories: transferWorkout.totalCalories,
                    poolSize: Int16(transferWorkout.poolSize),
                    workoutOriginalId: transferWorkout.workoutId,
                    workoutName: transferWorkout.workoutName,
                    exercisesData: convertToCompletedExerciseData(transferWorkout.exercises)
                )
                
                // Уведомляем делегата
                workoutCompletionDelegate?.didReceiveCompletedWorkout(transferWorkout)
            } else {
                print("iPhone: Дубликат тренировки, игнорируем. Время: \(transferWorkout.totalTime)")
            }
            
            // В любом случае отправляем подтверждение получения данных
            sendWorkoutDataReceivedConfirmation(sendId: sendId)
        }
    }
    
    // Сохранение данных о завершенной тренировке в CoreData
    private func saveCompletedWorkout(_ transferWorkout: TransferWorkoutModels.TransferWorkoutInfo) {
        let existingWorkouts = fetchExistingWorkoutSessions(
            workoutId: transferWorkout.workoutId,
            startTime: transferWorkout.startTime
        )
        
        if existingWorkouts.isEmpty {
            CoreDataManager.shared.createWorkoutSession(
                date: transferWorkout.startTime,
                totalTime: transferWorkout.totalTime,
                totalCalories: transferWorkout.totalCalories,
                poolSize: Int16(transferWorkout.poolSize),
                workoutOriginalId: transferWorkout.workoutId,
                workoutName: transferWorkout.workoutName,
                exercisesData: convertToCompletedExerciseData(transferWorkout.exercises)
            )
            print("Новая тренировка сохранена с временем: \(transferWorkout.totalTime)")
        } else {
            print("Найден дубликат тренировки. Время: \(transferWorkout.totalTime)")
        }
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
    
    // Преобразование данных о упражнениях для CoreDataManager
    private func convertToCompletedExerciseData(_ exercises: [TransferWorkoutModels.TransferExerciseInfo]) -> [CompletedExerciseData] {
        return exercises.map { exercise in
            // Преобразуем отрезки
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
            
            // Создаем CompletedExerciseData
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
            
            // Обработка метрик в реальном времени
            if let heartRate = message["heartRate"] as? Int {
                self.delegate?.didReceiveHeartRate(heartRate)
            }
            
            if let strokeCount = message["strokeCount"] as? Int {
                self.delegate?.didReceiveStrokeCount(strokeCount)
            }
            
            // Обработка статуса тренировки от часов
            if let watchStatus = message["watchStatus"] as? String {
                print("iPhone: Получен статус от часов: \(watchStatus)")
                
                _ = message["workoutStopTime"] as? Date
                _ = message["endTime"] as? Date
                
                self.delegate?.didReceiveWatchStatus(watchStatus)
                // Если получен статус остановки тренировки, сбрасываем параметры
                if watchStatus == "stopped" || watchStatus == "workoutStopped" {
                    self.resetTrainingParameters()
                }
            }
            
            // Обработка отдельного сообщения с данными о завершенной тренировке
            if let completedWorkoutData = message["completedWorkoutData"] as? [String: Any] {
                let shouldSaveWorkout = message["shouldSaveWorkout"] as? Bool ?? true
                
                if shouldSaveWorkout {
                    print("iPhone: Получены данные о завершенной тренировке для сохранения")
                    self.handleCompletedWorkoutData(completedWorkoutData)
                } else {
                    print("iPhone: Получены данные о тренировке, но shouldSaveWorkout=false")
                }
            }
            
            // Другие обработчики
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
            // Обработка запроса параметров длины бассейна
            if message["requestPoolLength"] != nil {
                if self.parametersExplicitlySet {
                    replyHandler(["poolLength": self.currentPoolSize])
                } else {
                    replyHandler(["parametersNotSet": true])
                }
            }
            // Обработка запроса всех параметров тренировки
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
            // Обработка запроса для списка тренировок
            else if message["requestWorkouts"] != nil {
                // Подтверждаем получение запроса
                replyHandler(["received": true, "processing": true])
                
                // Отправляем список тренировок с высоким приоритетом
                DispatchQueue.global(qos: .userInitiated).async {
                    // Получаем тренировки из CoreData
                    let workoutEntities = CoreDataManager.shared.fetchAllWorkouts()
                    
                    if workoutEntities.isEmpty {
                        return
                    }
                    
                    // Преобразуем в словари для передачи
                    let workoutsData = workoutEntities.map { entity -> [String: Any] in
                        // Получаем упражнения для этой тренировки и сортируем их по порядку
                        let exerciseEntities = entity.exercises?.allObjects as? [ExerciseEntity] ?? []
                        let sortedExercises = exerciseEntities.sorted { ($0.orderIndex < $1.orderIndex) }
                        
                        // Преобразуем упражнения в словари
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
                        
                        // Создаем словарь тренировки
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
                        // Пробуем отправить еще раз через небольшую задержку
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            WCSession.default.sendMessage(["workoutsData": workoutsData], replyHandler: { _ in },
                                                          errorHandler: { _ in })
                        }
                    })
                }
            }
            else {
                // Для других запросов
                replyHandler(["received": true])
                
                // Также обрабатываем сообщение как обычное
                self.session(session, didReceiveMessage: message)
            }
        }
    }
    
    // Проверка доступности Watch
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            // Если часы стали доступны, немедленно отправляем тренировки
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
}
