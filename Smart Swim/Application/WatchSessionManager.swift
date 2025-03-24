//
//  WatchSessionManager.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import WatchConnectivity
import Foundation

protocol WatchDataDelegate: AnyObject {
    func didReceiveHeartRate(_ pulse: Int)
    func didReceiveStrokeCount(_ strokes: Int)
    func didReceiveWatchStatus(_ status: String)
}

final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    weak var delegate: WatchDataDelegate?
    private var isSessionActive = false
    
    // Хранение текущих параметров тренировки
    private var currentPoolSize: Double = 25.0
    private var currentSwimmingStyle: Int = 0
    private var currentTotalMeters: Int = 0
    
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
        
        // Запускаем процесс отправки
        sendParametersWithRetry()
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
    
    // MARK: - WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isSessionActive = activationState == .activated
        }
    }
    
    // Обработка обычных сообщений
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let heartRate = message["heartRate"] as? Int {
                self.delegate?.didReceiveHeartRate(heartRate)
            }
            
            if let strokeCount = message["strokeCount"] as? Int {
                self.delegate?.didReceiveStrokeCount(strokeCount)
            }
            
            if let watchStatus = message["watchStatus"] as? String {
                self.delegate?.didReceiveWatchStatus(watchStatus)
            }
            
            if let parametersReceived = message["parametersReceived"] as? Bool, parametersReceived {
                self.parametersConfirmed = true
            }
            
            if message["requestWorkouts"] != nil {
                // Отправляем немедленно и несколько раз с интервалами для надежности
                DispatchQueue.global(qos: .userInteractive).async {
                    self.sendWorkoutsToWatch()
                    
                    // Повторная отправка через короткий промежуток
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
                replyHandler(["poolLength": self.currentPoolSize])
            }
            // Обработка запроса всех параметров тренировки
            else if message["requestAllParameters"] != nil {
                // Всегда отправляем текущие параметры
                let responseParams: [String: Any] = [
                    "poolSize": self.currentPoolSize,
                    "swimmingStyle": self.currentSwimmingStyle,
                    "totalMeters": self.currentTotalMeters
                ]
                replyHandler(responseParams)
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
        // Reactivate session if needed
        WCSession.default.activate()
    }
}
