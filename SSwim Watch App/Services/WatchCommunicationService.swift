//
//  WatchCommunicationService.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import WatchConnectivity
import Combine

typealias MessageHandler = ([String: Any]) -> Void

class WatchCommunicationService: NSObject, WCSessionDelegate {
    enum MessageType: String {
        // Старты
        case command
        case poolLength
        case swimmingStyle
        case totalMeters
        case heartRate
        case strokeCount
        case status
        case parametersReceived
        
        // Тренировки
        case requestWorkouts
        case workoutsData
        case startWorkout
        case workoutStatus
        
        // Общие
        case error
        case requestAllParameters
    }
    
    // MARK: - Singleton
    static let shared = WatchCommunicationService()
    
    // MARK: - Publishers
    private let messagePublisher = PassthroughSubject<(MessageType, [String: Any]), Never>()
    let isConnectedPublisher = PassthroughSubject<Bool, Never>()
    
    // MARK: - Properties
    private var handlers: [MessageType: [UUID: MessageHandler]] = [:]
    private var subscriptions: [UUID: MessageType] = [:]
    
    private var _isReachable = false
    private var reachableLock = NSLock()
    
    var isReachable: Bool {
        get {
            reachableLock.lock()
            defer { reachableLock.unlock() }
            return _isReachable && WCSession.default.isReachable
        }
        set {
            reachableLock.lock()
            _isReachable = newValue
            reachableLock.unlock()
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
    
    @discardableResult
    func sendMessage(type: MessageType, data: [String: Any] = [:]) -> Bool {
        guard isReachable else {
            return false
        }
        
        var messageData = data
        messageData["messageType"] = type.rawValue
        
        WCSession.default.sendMessage(messageData, replyHandler: nil) { _ in }
        return true
    }
    
    @discardableResult
    func sendMessageWithReply(type: MessageType, data: [String: Any] = [:], timeout: TimeInterval = 3.0, completion: @escaping ([String: Any]?) -> Void) -> Bool {
        guard isReachable else {
            completion(nil)
            return false
        }
        
        var messageData = data
        messageData["messageType"] = type.rawValue
        var hasCompleted = false
        
        WCSession.default.sendMessage(messageData, replyHandler: { response in
            hasCompleted = true
            completion(response)
        }, errorHandler: { _ in
            if !hasCompleted {
                hasCompleted = true
                completion(nil)
            }
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            if !hasCompleted {
                hasCompleted = true
                completion(nil)
            }
        }
        return true
    }
    
    func subscribe(to type: MessageType, handler: @escaping MessageHandler) -> UUID {
        let id = UUID()
        
        if handlers[type] == nil {
            handlers[type] = [:]
        }
        
        handlers[type]?[id] = handler
        subscriptions[id] = type
        return id
    }
    
    func unsubscribe(id: UUID) {
        if let type = subscriptions[id] {
            handlers[type]?[id] = nil
            if let handlers = handlers[type], handlers.isEmpty {
                self.handlers[type] = nil
            }
        }
        subscriptions[id] = nil
    }
    
    // MARK: - WCSessionDelegate Methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            let isActive = activationState == .activated
            self.isReachable = isActive
            self.isConnectedPublisher.send(isActive)
        }
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            let isReachable = session.isReachable
            self.isReachable = isReachable
            self.isConnectedPublisher.send(isReachable)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.handleMessage(message)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            self.handleMessage(message)
            
            var response: [String: Any] = ["received": true, "timestamp": Date().timeIntervalSince1970]
            if message["requestAllParameters"] != nil {
                response["requestAllParametersReceived"] = true
            } else if message["requestPoolLength"] != nil {
                response["requestPoolLengthReceived"] = true
            } else if message["requestWorkouts"] != nil {
                response["requestWorkoutsReceived"] = true
            }
            replyHandler(response)
        }
    }
    
    // MARK: - Private Methods
    private func handleMessage(_ message: [String: Any]) {
        if let command = message["command"] as? String {
            let messageWithType = addMessageType(to: message, type: .command)
            notifyHandlers(type: .command, message: messageWithType)
            return
        }
        
        if message["poolSize"] != nil {
            let messageWithType = addMessageType(to: message, type: .poolLength)
            notifyHandlers(type: .poolLength, message: messageWithType)
            return
        }
        
        if message["swimmingStyle"] != nil {
            let messageWithType = addMessageType(to: message, type: .swimmingStyle)
            notifyHandlers(type: .swimmingStyle, message: messageWithType)
            return
        }
        
        if message["totalMeters"] != nil {
            let messageWithType = addMessageType(to: message, type: .totalMeters)
            notifyHandlers(type: .totalMeters, message: messageWithType)
            return
        }
        
        if message["requestAllParameters"] != nil {
            let messageWithType = addMessageType(to: message, type: .requestAllParameters)
            notifyHandlers(type: .requestAllParameters, message: messageWithType)
            return
        }
        
        if message["requestPoolLength"] != nil {
            let messageWithType = addMessageType(to: message, type: .poolLength)
            notifyHandlers(type: .poolLength, message: messageWithType)
            return
        }
        
        if message["workoutsData"] != nil {
            let messageWithType = addMessageType(to: message, type: .workoutsData)
            notifyHandlers(type: .workoutsData, message: messageWithType)
            return
        }
        
        if message["requestWorkouts"] != nil {
            let messageWithType = addMessageType(to: message, type: .requestWorkouts)
            notifyHandlers(type: .requestWorkouts, message: messageWithType)
            return
        }
        
        if let typeString = message["messageType"] as? String,
           let type = MessageType(rawValue: typeString) {
            notifyHandlers(type: type, message: message)
            return
        }
    }
    
    private func notifyHandlers(type: MessageType, message: [String: Any]) {
        messagePublisher.send((type, message))
        
        if let typeHandlers = handlers[type] {
            for (_, handler) in typeHandlers {
                handler(message)
            }
        }
    }
    
    private func addMessageType(to message: [String: Any], type: MessageType) -> [String: Any] {
        var newMessage = message
        newMessage["messageType"] = type.rawValue
        return newMessage
    }
}
