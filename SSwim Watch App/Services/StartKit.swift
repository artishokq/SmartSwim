//
//  StartKit.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import Foundation
import Combine

final class StartKit {
    // MARK: - Constants
    private enum Constants {
        static let defaultPoolLength: Double = 25.0
        static let requestTimeout: TimeInterval = 3.0
    }
    
    // MARK: - Publishers
    let poolLengthPublisher = PassthroughSubject<Double, Never>()
    let swimmingStylePublisher = PassthroughSubject<Int, Never>()
    let totalMetersPublisher = PassthroughSubject<Int, Never>()
    let commandPublisher = PassthroughSubject<String, Never>()
    let isReadyPublisher = PassthroughSubject<Bool, Never>()
    
    // MARK: - Properties
    let communicationService: WatchCommunicationService
    let workoutKitManager: WorkoutKitManager
    private var subscriptionIds: [UUID] = []
    
    private var _poolLength: Double = Constants.defaultPoolLength
    private var poolLengthLock = NSLock()
    
    private var _swimmingStyle: Int = 0
    private var swimmingStyleLock = NSLock()
    
    private var _totalMeters: Int = 0
    private var totalMetersLock = NSLock()
    
    private var _isReady: Bool = false
    private var isReadyLock = NSLock()
    
    private var _pendingPoolLengthRequest = false
    private var pendingLock = NSLock()
    
    private var workoutStartTime: Date?
    private var currentLapNumber: Int = 1
    
    // MARK: - getters and setters
    var poolLength: Double {
        get {
            poolLengthLock.lock()
            defer { poolLengthLock.unlock() }
            return _poolLength
        }
        set {
            poolLengthLock.lock()
            let oldValue = _poolLength
            _poolLength = newValue
            poolLengthLock.unlock()
            
            if oldValue != newValue {
                poolLengthPublisher.send(newValue)
            }
        }
    }
    
    var swimmingStyle: Int {
        get {
            swimmingStyleLock.lock()
            defer { swimmingStyleLock.unlock() }
            return _swimmingStyle
        }
        set {
            swimmingStyleLock.lock()
            let oldValue = _swimmingStyle
            _swimmingStyle = newValue
            swimmingStyleLock.unlock()
            
            if oldValue != newValue {
                swimmingStylePublisher.send(newValue)
            }
        }
    }
    
    var totalMeters: Int {
        get {
            totalMetersLock.lock()
            defer { totalMetersLock.unlock() }
            return _totalMeters
        }
        set {
            totalMetersLock.lock()
            let oldValue = _totalMeters
            _totalMeters = newValue
            totalMetersLock.unlock()
            
            if oldValue != newValue {
                totalMetersPublisher.send(newValue)
            }
        }
    }
    
    var isReady: Bool {
        get {
            isReadyLock.lock()
            defer { isReadyLock.unlock() }
            return _isReady
        }
        set {
            isReadyLock.lock()
            let oldValue = _isReady
            _isReady = newValue
            isReadyLock.unlock()
            
            if oldValue != newValue {
                isReadyPublisher.send(newValue)
            }
        }
    }
    
    var pendingPoolLengthRequest: Bool {
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
    init(communicationService: WatchCommunicationService, workoutKitManager: WorkoutKitManager) {
        self.communicationService = communicationService
        self.workoutKitManager = workoutKitManager
        self._isReady = false
        subscribeToMessages()
        setupWorkoutSubscriptions()
    }
    
    deinit {
        for id in subscriptionIds {
            communicationService.unsubscribe(id: id)
        }
    }
    
    // MARK: - Private Methods
    private func subscribeToMessages() {
        let commandId = communicationService.subscribe(to: .command) { [weak self] message in
            if let command = message["command"] as? String {
                self?.commandPublisher.send(command)
            }
        }
        subscriptionIds.append(commandId)
        
        let poolLengthId = communicationService.subscribe(to: .poolLength) { [weak self] message in
            if let poolSize = message["poolSize"] as? Double {
                self?.poolLength = poolSize
            }
        }
        subscriptionIds.append(poolLengthId)
        
        let styleId = communicationService.subscribe(to: .swimmingStyle) { [weak self] message in
            if let style = message["swimmingStyle"] as? Int {
                self?.swimmingStyle = style
            }
        }
        subscriptionIds.append(styleId)
        
        let metersId = communicationService.subscribe(to: .totalMeters) { [weak self] message in
            if let meters = message["totalMeters"] as? Int {
                self?.totalMeters = meters
            }
        }
        subscriptionIds.append(metersId)
    }
    
    private func setupWorkoutSubscriptions() {
        _ = workoutKitManager.lapCompletedPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] lapNumber in
                guard let self = self else { return }
                print("Отрезок \(lapNumber) завершен")
                self.currentLapNumber = lapNumber
            }
    }
    
    // MARK: - Public Methods
    @discardableResult
    func requestAllParameters() -> Bool {
        return communicationService.sendMessageWithReply(
            type: .requestAllParameters,
            data: ["requestAllParameters": true]
        ) { [weak self] response in
            guard let self = self, let response = response else { return }
            
            if response["parametersNotSet"] != nil {
                self.isReady = false
                return
            }
            
            if let poolLength = response["poolSize"] as? Double {
                self.poolLength = poolLength
            }
            
            if let style = response["swimmingStyle"] as? Int {
                self.swimmingStyle = style
            }
            
            if let meters = response["totalMeters"] as? Int {
                self.totalMeters = meters
            }
            
            if response["poolSize"] != nil || response["swimmingStyle"] != nil || response["totalMeters"] != nil {
                self.isReady = true
            }
        }
    }
    
    @discardableResult
    func requestPoolLength() -> Bool {
        if pendingPoolLengthRequest {
            return false
        }
        pendingPoolLengthRequest = true
        
        let success = communicationService.sendMessageWithReply(
            type: .poolLength,
            data: ["requestPoolLength": true]
        ) { [weak self] response in
            guard let self = self else { return }
            self.pendingPoolLengthRequest = false
            
            if response?["parametersNotSet"] != nil {
                return
            }
            
            if let poolLength = response?["poolLength"] as? Double {
                self.poolLength = poolLength
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.requestTimeout) {
            if self.pendingPoolLengthRequest {
                self.pendingPoolLengthRequest = false
            }
        }
        return success
    }
    
    func startWorkout() {
        currentLapNumber = 1
        workoutStartTime = Date()
        print("StartKit: Запуск тренировки через HealthKit в \(workoutStartTime!)")
        let workout = createBasicSwimWorkout()
        workoutKitManager.startWorkout(workout: workout)
    }
    
    func stopWorkout() {
        print("StartKit: Останавливаем тренировку в HealthKit")
        workoutKitManager.stopWorkout()
        communicationService.sendMessage(
            type: .status,
            data: [
                "watchStatus": "workoutStopped",
                "workoutStopTime": Date()
            ]
        )
    }
    
    private func createBasicSwimWorkout() -> SwimWorkoutModels.SwimWorkout {
        let exercise = SwimWorkoutModels.SwimExercise(
            id: UUID().uuidString,
            description: "Свободное плавание",
            style: swimmingStyle,
            type: 1,
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0,
            meters: totalMeters > 0 ? totalMeters : 1000,
            orderIndex: 0,
            repetitions: 1
        )
        
        return SwimWorkoutModels.SwimWorkout(
            id: UUID().uuidString,
            name: "Свободное плавание",
            poolSize: Int(poolLength),
            exercises: [exercise]
        )
    }
    
    func sendStatus(_ status: String, endTime: Date? = nil) {
        communicationService.sendMessage(
            type: .status,
            data: [
                "watchStatus": status,
                "endTime": endTime as Any
            ]
        )
        print("StartKit: Отправка статуса \(status)")
    }
    
    func getCurrentPoolLength() -> Double {
        return poolLength
    }
    
    func resetReadyState() {
        isReady = false
        pendingPoolLengthRequest = false
        poolLength = Constants.defaultPoolLength
        swimmingStyle = 0
        totalMeters = 0
        workoutStartTime = nil
        currentLapNumber = 1
    }
}
