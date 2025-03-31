//
//  StartService.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import Foundation
import Combine

class StartService: ObservableObject {
    // MARK: - Published Properties
    @Published var session = SwimSession()
    @Published var isReadyToStart = false
    @Published var command = ""
    
    // MARK: - Private Properties
    private let startKit: StartKit
    private let workoutKitManager: WorkoutKitManager
    private var cancellables = Set<AnyCancellable>()
    private var hasUpdatedPoolLength = false
    private var retryCount = 0
    
    // Флаг активности сбора данных для предотвращения дублей
    private var isDataCollectionActive = false
    
    // MARK: - Initialization
    init(startKit: StartKit, workoutKitManager: WorkoutKitManager) {
        self.startKit = startKit
        self.workoutKitManager = workoutKitManager
        self.isReadyToStart = false
        session.poolLength = startKit.getCurrentPoolLength()
        setupSubscriptions()
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        startKit.poolLengthPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] poolLength in
                guard let self = self else { return }
                self.session.poolLength = poolLength
                self.hasUpdatedPoolLength = true
            }
            .store(in: &cancellables)
        
        startKit.swimmingStylePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] style in
                self?.session.swimmingStyle = style
            }
            .store(in: &cancellables)
        
        startKit.totalMetersPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] meters in
                self?.session.totalMeters = meters
            }
            .store(in: &cancellables)
        
        startKit.isReadyPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isReady in
                self?.isReadyToStart = isReady
            }
            .store(in: &cancellables)
        
        startKit.commandPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] cmd in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.command = cmd
                }
            }
            .store(in: &cancellables)
        
        workoutKitManager.heartRatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] heartRate in
                guard let self = self else { return }
                self.session.heartRate = heartRate
                self.startKit.sendHeartRate(Int(heartRate))
            }
            .store(in: &cancellables)
        
        workoutKitManager.strokeCountPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] strokeCount in
                guard let self = self else { return }
                self.session.strokeCount = strokeCount
                self.startKit.sendStrokeCount(strokeCount)
            }
            .store(in: &cancellables)
        
        workoutKitManager.workoutStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isActive in
                self?.session.isActive = isActive
            }
            .store(in: &cancellables)
    }
    
    private func ensurePoolLength(completion: @escaping () -> Void) {
        let requestSuccess = startKit.requestPoolLength()
        
        if requestSuccess {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let poolLength = self.startKit.getCurrentPoolLength()
                self.session.poolLength = poolLength
                completion()
            }
        } else {
            retryCount += 1
            
            if retryCount < 3 {
                // Пробуем другой способ получения параметров
                let allParamsSuccess = startKit.requestAllParameters()
                
                if allParamsSuccess {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // Обновляем длину бассейна в сессии
                        let poolLength = self.startKit.getCurrentPoolLength()
                        self.session.poolLength = poolLength
                        completion()
                    }
                } else {
                    completion()
                }
            } else {
                completion()
            }
        }
    }
    
    // MARK: - Public Methods
    func requestParameters() {
        startKit.requestAllParameters()
    }
    
    func resetParameters() {
        isDataCollectionActive = false
        startKit.resetReadyState()
        isReadyToStart = false
        resetCommand()
    }
    
    func startWorkout() {
        retryCount = 0
        print("START: Запускаем тренировку в режиме старта")
        
        ensurePoolLength { [weak self] in
            guard let self = self else { return }
            self.startKit.startWorkout()
            self.startKit.sendStatus("started")
            print("START: Тренировка запущена в Health")
        }
    }
    
    func stopWorkout() {
        if isDataCollectionActive {
            print("Остановка уже в процессе, игнорируем повторный запрос")
            return
        }
        
        print("STOP: Пользователь запросил остановку")
        let stopTime = Date()
        isDataCollectionActive = true
        
        startKit.sendStatus("stopping")
        print("STOP: Статус UI обновлен на stopping")
        
        print("Фактическая остановка тренировки")
        startKit.stopWorkout()
        
        startKit.sendStatus("stopped", endTime: stopTime)
        isDataCollectionActive = false
    }
    
    func resetCommand() {
        command = ""
    }
    
    func getCurrentPoolLength() -> Double {
        return startKit.getCurrentPoolLength()
    }
    
    func resetAndRequestParameters() {
        startKit.resetReadyState()
        isReadyToStart = false
        resetCommand()
        requestParameters()
    }
}
