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
    private let communicationService: WatchCommunicationService
    private let workoutKitManager: WorkoutKitManager
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
    
    private struct LapData {
        let lapNumber: Int
        let timestamp: Date
        var strokeCount: Int
        var heartRate: Double
        var distance: Double
    }
    
    private var laps: [LapData] = []
    private var currentLapStartStrokeCount: Int = 0
    private var currentLapNumber: Int = 1
    private var lastKnownHeartRate: Double = 0
    private var lastStrokeMetricTime: Date?
    
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
        // Подписка на завершение отрезков
        _ = workoutKitManager.lapCompletedPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] lapNumber in
                guard let self = self else { return }
                print("Отрезок \(lapNumber) завершен")
                
                // Задержка для сбора возможных данных о гребках
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.finalizeLapData(lapNumber: lapNumber)
                }
            }
        
        // Подписка на обновления сердечного ритма
        _ = workoutKitManager.heartRatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] heartRate in
                guard let self = self else { return }
                self.lastKnownHeartRate = heartRate
                self.updateLatestLapData()
            }
        
        // Подписка на обновления гребков
        _ = workoutKitManager.strokeCountPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] strokeCount in
                guard let self = self else { return }
                
                // Обновляем данные о текущем отрезке
                self.updateStrokeCount(strokeCount)
            }
    }
    
    private func updateLatestLapData() {
        // Сохраняем текущий пульс для отрезка
        if !laps.isEmpty {
            let now = Date()
            if lastStrokeMetricTime == nil || now.timeIntervalSince(lastStrokeMetricTime!) > 4.0 {
                recordCurrentLapMetrics()
                lastStrokeMetricTime = now
            }
        }
    }
    
    private func updateStrokeCount(_ strokeCount: Int) {
        // Обновляем данные о текущем отрезке если он начат
        if laps.isEmpty {
            // Первый отрезок
            laps.append(LapData(
                lapNumber: 1,
                timestamp: Date(),
                strokeCount: strokeCount,
                heartRate: lastKnownHeartRate,
                distance: poolLength
            ))
            currentLapStartStrokeCount = 0
            currentLapNumber = 1
        } else {
            let now = Date()
            if lastStrokeMetricTime == nil || now.timeIntervalSince(lastStrokeMetricTime!) > 4.0 {
                recordCurrentLapMetrics()
                lastStrokeMetricTime = now
            }
        }
    }
    
    private func recordCurrentLapMetrics() {
        let totalStrokeCount = workoutKitManager.getTotalStrokeCount()
        let strokesInCurrentLap = totalStrokeCount - currentLapStartStrokeCount
        
        // Если у нас есть данные для текущего отрезка, обновляем их
        if let index = laps.firstIndex(where: { $0.lapNumber == currentLapNumber }) {
            var updatedLap = laps[index]
            updatedLap.strokeCount = strokesInCurrentLap
            updatedLap.heartRate = lastKnownHeartRate
            laps[index] = updatedLap
        } else {
            // Если нет записи, создаем новую
            laps.append(LapData(
                lapNumber: currentLapNumber,
                timestamp: Date(),
                strokeCount: strokesInCurrentLap,
                heartRate: lastKnownHeartRate,
                distance: poolLength
            ))
        }
    }
    
    private func finalizeLapData(lapNumber: Int) {
        let totalStrokeCount = workoutKitManager.getTotalStrokeCount()
        let strokesInCurrentLap = totalStrokeCount - currentLapStartStrokeCount
        
        if let index = laps.firstIndex(where: { $0.lapNumber == currentLapNumber }) {
            var updatedLap = laps[index]
            updatedLap.strokeCount = strokesInCurrentLap
            updatedLap.heartRate = lastKnownHeartRate
            laps[index] = updatedLap
        } else {
            laps.append(LapData(
                lapNumber: currentLapNumber,
                timestamp: Date(),
                strokeCount: strokesInCurrentLap,
                heartRate: lastKnownHeartRate,
                distance: poolLength
            ))
        }
        
        currentLapStartStrokeCount = totalStrokeCount
        currentLapNumber = lapNumber
        
        laps.append(LapData(
            lapNumber: lapNumber,
            timestamp: Date(),
            strokeCount: 0,
            heartRate: lastKnownHeartRate,
            distance: poolLength
        ))
        
        print("Отрезок \(currentLapNumber-1) финализирован с \(strokesInCurrentLap) гребками")
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
        laps = []
        currentLapStartStrokeCount = 0
        currentLapNumber = 1
        lastKnownHeartRate = 0
        
        workoutStartTime = Date()
        print("StartKit: Запуск тренировки через HealthKit в \(workoutStartTime!)")
        
        // Создаем базовую тренировку по плаванию
        let workout = createBasicSwimWorkout()
        // Запускаем тренировку через HealthKit
        workoutKitManager.startWorkout(workout: workout)
        // Создаем первый отрезок
        laps.append(LapData(
            lapNumber: 1,
            timestamp: Date(),
            strokeCount: 0,
            heartRate: 0,
            distance: poolLength
        ))
    }
    
    func stopWorkout() {
        print("StartKit: Останавливаем тренировку в HealthKit")
        
        recordCurrentLapMetrics()
        workoutKitManager.stopWorkout()
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
    
    func sendHeartRate(_ heartRate: Int) {
        communicationService.sendMessage(
            type: .heartRate,
            data: ["heartRate": heartRate]
        )
    }
    
    func sendStrokeCount(_ count: Int) {
        communicationService.sendMessage(
            type: .strokeCount,
            data: ["strokeCount": count]
        )
    }
    
    func sendStatus(_ status: String, endTime: Date? = nil) {
        if status == "stopping" {
            communicationService.sendMessage(
                type: .status,
                data: [
                    "watchStatus": status,
                    "shouldSaveWorkout": false,
                    "isCollectingData": true
                ]
            )
            print("StartKit: Отправка статуса STOPPING (только для UI, без сохранения)")
            return
        }
        
        if status == "stopped", let endTime = endTime {
            communicationService.sendMessage(
                type: .status,
                data: [
                    "watchStatus": status,
                    "shouldSaveWorkout": false
                ]
            )
            print("StartKit: Отправка статуса STOPPED (только UI)")
        }
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
        laps = []
        currentLapStartStrokeCount = 0
        currentLapNumber = 1
        lastKnownHeartRate = 0
    }
}
