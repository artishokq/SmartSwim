//
//  WatchSessionService.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import WatchConnectivity
import Combine

class WatchSessionService: NSObject, WCSessionDelegate {
    // MARK: - Constants
    private enum Constants {
        static let defaultPoolLength: Double = 25.0
        static let requestTimeout: TimeInterval = 3.0
    }
    
    // MARK: - Singleton
    static let shared = WatchSessionService()
    
    // MARK: - Publishers
    let commandPublisher = PassthroughSubject<String, Never>()
    let poolLengthPublisher = PassthroughSubject<Double, Never>()
    let swimmingStylePublisher = PassthroughSubject<Int, Never>()
    let totalMetersPublisher = PassthroughSubject<Int, Never>()
    let isConnectedPublisher = PassthroughSubject<Bool, Never>()
    let isReadyToStartPublisher = PassthroughSubject<Bool, Never>()
    
    // MARK: - Properties
    private var isReady: Bool = false {
        didSet {
            isReadyToStartPublisher.send(isReady)
        }
    }
    
    // Значение длины бассейна с потокобезопасным доступом
    private var _currentPoolLength: Double = Constants.defaultPoolLength
    private var currentPoolLengthLock = NSLock()
    
    var currentPoolLength: Double {
        get {
            currentPoolLengthLock.lock()
            defer { currentPoolLengthLock.unlock() }
            return _currentPoolLength
        }
        set {
            currentPoolLengthLock.lock()
            _currentPoolLength = newValue
            currentPoolLengthLock.unlock()
        }
    }
    
    private var _pendingPoolLengthRequest = false
    private var pendingLock = NSLock()
    
    private var pendingPoolLengthRequest: Bool {
        get {
            pendingLock.lock()
            defer { pendingLock.unlock() }
            return _pendingPoolLengthRequest
        }
        set {
            pendingLock.lock()
            _pendingPoolLengthRequest = newValue
            pendingLock.unlock()
        }
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        startSession()
    }
    
    // MARK: - Public Methods
    func startSession() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func getCurrentPoolLength() -> Double {
        return currentPoolLength
    }
    
    // Метод для принудительного запроса всех параметров сразу
    func requestAllParameters() -> Bool {
        if WCSession.default.isReachable {
            print("[WatchSession] Запрос всех параметров от iPhone")
            WCSession.default.sendMessage(["requestAllParameters": true], replyHandler: { response in
                print("[WatchSession] Получен ответ от iPhone с параметрами: \(response)")
                
                if let poolLength = response["poolSize"] as? Double {
                    print("[WatchSession] Получена длина бассейна: \(poolLength)м")
                    self.updatePoolLength(poolLength)
                }
                
                if let style = response["swimmingStyle"] as? Int {
                    print("[WatchSession] Получен стиль: \(style)")
                    self.swimmingStylePublisher.send(style)
                }
                
                if let meters = response["totalMeters"] as? Int {
                    print("[WatchSession] Получена дистанция: \(meters)м")
                    self.totalMetersPublisher.send(meters)
                }
                
                self.isReady = true
                
            }, errorHandler: { error in
                print("[WatchSession] Ошибка при запросе параметров: \(error.localizedDescription)")
                self.pendingPoolLengthRequest = false
            })
            return true
        } else {
            print("[WatchSession] iPhone недоступен")
            return false
        }
    }
    
    // Метод для запроса только длины бассейна с iPhone
    func requestPoolLengthFromPhone() -> Bool {
        // Если уже есть ожидающий запрос, не отправляем еще один
        if pendingPoolLengthRequest {
            print("[WatchSession] Запрос длины бассейна уже отправлен и ожидает ответа")
            return false
        }
        
        if WCSession.default.isReachable {
            print("[WatchSession] Запрос длины бассейна от iPhone")
            pendingPoolLengthRequest = true
            
            WCSession.default.sendMessage(["requestPoolLength": true], replyHandler: { response in
                self.pendingPoolLengthRequest = false
                
                if let poolLength = response["poolLength"] as? Double {
                    print("[WatchSession] Получен ответ с длиной бассейна: \(poolLength)м")
                    self.updatePoolLength(poolLength)
                } else {
                    print("[WatchSession] Получен ответ, но длина бассейна отсутствует")
                }
            }, errorHandler: { error in
                self.pendingPoolLengthRequest = false
                print("[WatchSession] Ошибка при запросе длины бассейна: \(error.localizedDescription)")
            })
            
            // Устанавливаем таймаут для запроса
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.requestTimeout) {
                if self.pendingPoolLengthRequest {
                    print("[WatchSession] Таймаут запроса длины бассейна")
                    self.pendingPoolLengthRequest = false
                }
            }
            
            return true
        } else {
            print("[WatchSession] iPhone недоступен для запроса длины бассейна")
            return false
        }
    }
    
    // Обновляет длину бассейна и уведомляет подписчиков
    func updatePoolLength(_ length: Double) {
        print("[WatchSession] Обновление длины бассейна на: \(length)м")
        
        // Если значение не изменилось, не отправляем уведомление
        if currentPoolLength == length {
            print("[WatchSession] Длина бассейна не изменилась")
            return
        }
        
        // Вызываем в основном потоке для безопасного обновления UI
        DispatchQueue.main.async {
            self.currentPoolLength = length
            self.poolLengthPublisher.send(length)
        }
    }
    
    func sendMessageToPhone(message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("[WatchSession] Ошибка отправки сообщения на телефон: \(error.localizedDescription)")
            }
        } else {
            print("[WatchSession] Телефон недоступен")
        }
    }
    
    func sendHeartRateToPhone(heartRate: Int) {
        sendMessageToPhone(message: ["heartRate": heartRate])
    }
    
    func sendStrokeCountToPhone(strokeCount: Int) {
        print("[WatchSession] Отправляем гребки на iPhone: \(strokeCount)")
        sendMessageToPhone(message: ["strokeCount": strokeCount])
    }
    
    func sendStatusToPhone(status: String) {
        print("[WatchSession] Отправляем статус на iPhone: \(status)")
        sendMessageToPhone(message: ["watchStatus": status])
    }
    
    // MARK: - WCSessionDelegate Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            let isActive = activationState == .activated
            self.isConnectedPublisher.send(isActive)
            
            if isActive {
                print("[WatchSession] Сессия активирована, запрашиваем параметры")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.requestAllParameters()
                }
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            print("[WatchSession] Получено сообщение от iPhone: \(message)")
            
            if let command = message["command"] as? String {
                print("[WatchSession] Получена команда от iPhone: \(command)")
                self.commandPublisher.send(command)
            }
            
            if let poolSize = message["poolSize"] as? Double {
                print("[WatchSession] Получена длина бассейна от iPhone: \(poolSize) метров")
                self.updatePoolLength(poolSize)
            }
            
            if let style = message["swimmingStyle"] as? Int {
                print("[WatchSession] Получен стиль плавания от iPhone: \(style)")
                self.swimmingStylePublisher.send(style)
            }
            
            if let meters = message["totalMeters"] as? Int {
                print("[WatchSession] Получена общая дистанция от iPhone: \(meters) метров")
                self.totalMetersPublisher.send(meters)
            }
            
            // Проверка, получены ли все необходимые данные
            if message.keys.contains("poolSize") ||
               message.keys.contains("swimmingStyle") ||
               message.keys.contains("totalMeters") {
                self.isReady = true
                
                // Отправляем подтверждение получения
                self.sendMessageToPhone(message: ["parametersReceived": true])
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            print("[WatchSession] Получено сообщение с ожиданием ответа: \(message)")
            
            // Обрабатываем сообщение как обычно
            self.session(session, didReceiveMessage: message)
            
            // Отправляем ответ
            replyHandler(["received": true])
        }
    }
}
