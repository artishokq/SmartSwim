//
//  WatchSessionManager.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 19.02.2025.
//  Updated by Artem Tkachuk on 27.03.2025.
//

import WatchConnectivity
import Foundation

protocol WatchDataDelegate: AnyObject {
    func didReceiveHeartRate(_ pulse: Int)
    func didReceiveStrokeCount(_ strokes: Int)
    func didReceiveWatchStatus(_ status: String)
}

class WatchSessionManager: NSObject, WCSessionDelegate {
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
            print("Отправка команды на Apple Watch: \(command)")
            WCSession.default.sendMessage(["command": command], replyHandler: { reply in
                print("Подтверждение получения команды \(command): \(reply)")
            }, errorHandler: { error in
                print("Ошибка отправки команды на Watch: \(error.localizedDescription)")
            })
        } else {
            print("Watch недоступен для отправки команды")
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
        
        print("Сохранены параметры для отправки: бассейн \(poolSize)м, стиль \(style), дистанция \(meters)м")
        
        // Запускаем процесс отправки
        sendParametersWithRetry()
    }
    
    // MARK: - Работа с тренировками
    
    // Метод для отправки списка тренировок на Apple Watch
    func sendWorkoutsToWatch() {
        // Перед отправкой проверяем и пытаемся активировать соединение
        if WCSession.default.activationState != .activated {
            print("Соединение неактивно, активируем перед отправкой тренировок")
            WCSession.default.activate()
        }
        
        // Проверяем соединение с часами, даже если activationState = .activated
        if !WCSession.default.isReachable {
            print("Apple Watch недоступны, но всё равно пробуем отправить")
        }
        
        if WCSession.default.isReachable {
            // Получаем тренировки из CoreData
            let workoutEntities = CoreDataManager.shared.fetchAllWorkouts()
            print("Загружено \(workoutEntities.count) тренировок из CoreData")
            
            if workoutEntities.isEmpty {
                print("⚠️ Предупреждение: В CoreData нет ни одной тренировки")
                return
            }
            
            // Вывод отладочной информации о каждой тренировке
            for (index, workout) in workoutEntities.enumerated() {
                let exerciseCount = (workout.exercises?.count ?? 0)
                print("Тренировка #\(index + 1): \(workout.name ?? "Без имени"), упражнений: \(exerciseCount), бассейн: \(workout.poolSize)м")
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
            
            print("Отправка \(workoutsData.count) тренировок на Apple Watch")
            
            // Отправляем данные тренировок на часы
            WCSession.default.sendMessage(["workoutsData": workoutsData], replyHandler: { reply in
                print("Данные тренировок успешно отправлены: \(reply)")
            }, errorHandler: { error in
                print("Ошибка отправки данных тренировок: \(error.localizedDescription)")
                
                // Пробуем отправить еще раз через небольшую задержку
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    print("Повторная попытка отправки тренировок после ошибки")
                    self?.sendWorkoutsToWatch()
                }
            })
        } else {
            print("Apple Watch недоступны для отправки тренировок")
            
            // Вторая попытка с задержкой
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if WCSession.default.isReachable {
                    print("Apple Watch стал доступен, повторяем отправку тренировок")
                    self?.sendWorkoutsToWatch()
                } else {
                    print("Apple Watch все еще недоступен. Дальнейшие попытки отменены.")
                }
            }
        }
    }
    
    func activateSessionAndSendWorkouts() {
        print("Активация сессии при запуске приложения")
        
        // Если сессия не активна, активируем её
        if WCSession.default.activationState != .activated {
            WCSession.default.activate()
        }
        
        // Независимо от состояния сессии, пробуем отправить тренировки через короткие промежутки времени
        for delay in [0.5, 2.0, 5.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                print("Попытка отправки тренировок после задержки \(delay) сек")
                self?.sendWorkoutsToWatch()
            }
        }
    }
    
    // MARK: - Private Methods
    
    // Метод для отправки параметров с возможностью повторных попыток
    private func sendParametersWithRetry() {
        if WCSession.default.isReachable {
            print("Отправка параметров тренировки на Apple Watch (попытка \(retryCount + 1))")
            
            let parameters: [String: Any] = [
                "poolSize": currentPoolSize,
                "swimmingStyle": currentSwimmingStyle,
                "totalMeters": currentTotalMeters
            ]
            
            WCSession.default.sendMessage(parameters, replyHandler: { [weak self] response in
                guard let self = self else { return }
                
                print("Параметры успешно отправлены на Apple Watch")
                if let confirmation = response["parametersReceived"] as? Bool, confirmation {
                    print("Получено подтверждение получения параметров от Apple Watch")
                    self.parametersConfirmed = true
                }
            }, errorHandler: { [weak self] error in
                guard let self = self else { return }
                
                print("Ошибка отправки параметров на Watch: \(error.localizedDescription)")
                
                // Повторная попытка отправки
                self.retryCount += 1
                if self.retryCount < self.maxRetries {
                    print("Повторная попытка отправки параметров (\(self.retryCount + 1)/\(self.maxRetries))...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.sendParametersWithRetry()
                    }
                } else {
                    print("Исчерпано максимальное количество попыток отправки параметров")
                }
            })
        } else {
            print("Watch недоступен для отправки параметров")
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
            print("Watch Session активирована: \(self.isSessionActive)")
            
            if let error = error {
                print("Ошибка при активации сессии Watch: \(error.localizedDescription)")
            }
        }
    }
    
    // Обработка обычных сообщений
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let heartRate = message["heartRate"] as? Int {
                print("Получен пульс: \(heartRate)")
                self.delegate?.didReceiveHeartRate(heartRate)
            }
            
            if let strokeCount = message["strokeCount"] as? Int {
                print("Получено количество гребков: \(strokeCount)")
                self.delegate?.didReceiveStrokeCount(strokeCount)
            }
            
            if let watchStatus = message["watchStatus"] as? String {
                print("Получен статус часов: \(watchStatus)")
                self.delegate?.didReceiveWatchStatus(watchStatus)
            }
            
            if let parametersReceived = message["parametersReceived"] as? Bool, parametersReceived {
                print("Получено подтверждение получения параметров")
                self.parametersConfirmed = true
            }
            
            if message["requestWorkouts"] != nil {
                print("Получен запрос тренировок от Apple Watch - ВЫСОКИЙ ПРИОРИТЕТ")
                
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
            print("Получен запрос с ожиданием ответа от Apple Watch: \(message)")
            
            // Обработка запроса параметров длины бассейна
            if message["requestPoolLength"] != nil {
                print("Запрос длины бассейна от Apple Watch. Отправляем: \(self.currentPoolSize)м")
                replyHandler(["poolLength": self.currentPoolSize])
            }
            // Обработка запроса всех параметров тренировки
            else if message["requestAllParameters"] != nil {
                print("Запрос всех параметров тренировки от Apple Watch")
                
                // Всегда отправляем текущие параметры, не зависимо от того, запрашивались ли они ранее
                let responseParams: [String: Any] = [
                    "poolSize": self.currentPoolSize,
                    "swimmingStyle": self.currentSwimmingStyle,
                    "totalMeters": self.currentTotalMeters
                ]
                print("Отправляем параметры: \(responseParams)")
                replyHandler(responseParams)
            }
            // Обработка запроса для списка тренировок
            else if message["requestWorkouts"] != nil {
                print("Получен запрос тренировок от Apple Watch")
                
                // Подтверждаем получение запроса
                replyHandler(["received": true, "processing": true])
                
                // Отправляем список тренировок с высоким приоритетом
                DispatchQueue.global(qos: .userInitiated).async {
                    print("Начинаем обработку запроса тренировок в фоновом потоке")
                    
                    // Получаем тренировки из CoreData
                    let workoutEntities = CoreDataManager.shared.fetchAllWorkouts()
                    print("Загружено \(workoutEntities.count) тренировок из CoreData для ответа на запрос")
                    
                    if workoutEntities.isEmpty {
                        print("⚠️ Предупреждение: В CoreData нет ни одной тренировки для отправки на часы")
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
                    
                    print("Отправка \(workoutsData.count) тренировок на Apple Watch в ответ на запрос")
                    
                    // Отправляем данные тренировок на часы
                    WCSession.default.sendMessage(["workoutsData": workoutsData], replyHandler: { reply in
                        print("Данные тренировок успешно отправлены в ответ на запрос: \(reply)")
                    }, errorHandler: { error in
                        print("Ошибка отправки данных тренировок в ответ на запрос: \(error.localizedDescription)")
                        
                        // Пробуем отправить еще раз через небольшую задержку
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            print("Повторная попытка отправки тренировок после ошибки")
                            
                            WCSession.default.sendMessage(["workoutsData": workoutsData], replyHandler: { reply in
                                print("Данные тренировок успешно отправлены после повторной попытки: \(reply)")
                            }, errorHandler: { error in
                                print("Ошибка повторной отправки данных тренировок: \(error.localizedDescription)")
                            })
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
            print("Доступность Apple Watch изменилась: \(session.isReachable ? "доступны" : "недоступны")")
            
            // Если часы стали доступны, немедленно отправляем тренировки
            if session.isReachable {
                print("Apple Watch стали доступны, немедленно отправляем тренировки")
                DispatchQueue.global(qos: .userInteractive).async {
                    self.sendWorkoutsToWatch()
                }
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        isSessionActive = false
        print("Watch Session стала неактивной")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        isSessionActive = false
        print("Watch Session деактивирована, выполняем повторную активацию")
        // Reactivate session if needed
        WCSession.default.activate()
    }
}
