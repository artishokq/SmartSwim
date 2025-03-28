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
    private let healthManager: HealthKitManager
    private var cancellables = Set<AnyCancellable>()
    private var hasUpdatedPoolLength = false
    private var retryCount = 0
    
    // MARK: - Initialization
    init(startKit: StartKit, healthManager: HealthKitManager) {
        self.startKit = startKit
        self.healthManager = healthManager
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
                
                // Если тренировка уже активна и длина бассейна изменилась, перезапускаем тренировку
                if self.session.isActive && poolLength != self.healthManager.getCurrentPoolLength() {
                    self.restartWorkoutIfNeeded(with: poolLength)
                }
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
        
        healthManager.heartRatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] heartRate in
                guard let self = self else { return }
                self.session.heartRate = heartRate
                self.startKit.sendHeartRate(Int(heartRate))
            }
            .store(in: &cancellables)
        
        healthManager.strokeCountPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] strokeCount in
                guard let self = self else { return }
                self.session.strokeCount = strokeCount
                self.startKit.sendStrokeCount(strokeCount)
            }
            .store(in: &cancellables)
        
        healthManager.workoutStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isActive in
                self?.session.isActive = isActive
            }
            .store(in: &cancellables)
    }
    
    private func restartWorkoutIfNeeded(with poolLength: Double) {
        healthManager.stopWorkout()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.healthManager.startWorkout(poolLength: poolLength)
        }
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
    
    func startWorkout() {
        retryCount = 0
        
        ensurePoolLength { [weak self] in
            guard let self = self else { return }
            let poolLength = self.session.poolLength
            self.startKit.startWorkout()
            self.startKit.sendStatus("started")
        }
    }
    
    func stopWorkout() {
        startKit.stopWorkout()
        startKit.sendStatus("stopped")
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
