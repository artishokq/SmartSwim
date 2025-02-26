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
                let responseParams: [String: Any] = [
                    "poolSize": self.currentPoolSize,
                    "swimmingStyle": self.currentSwimmingStyle,
                    "totalMeters": self.currentTotalMeters
                ]
                print("Отправляем параметры: \(responseParams)")
                replyHandler(responseParams)
            }
            else {
                // Для других запросов
                replyHandler(["received": true])
                
                // Также обрабатываем сообщение как обычное
                self.session(session, didReceiveMessage: message)
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
