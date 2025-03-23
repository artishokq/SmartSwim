//
//  ServiceLocator.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import Foundation

final class ServiceLocator {
    // MARK: - Singleton
    static let shared = ServiceLocator()
    
    // MARK: -  Basic layers
    private(set) lazy var communicationService: WatchCommunicationService = {
        return WatchCommunicationService.shared
    }()
    
    private(set) lazy var healthManager: HealthKitManager = {
        return HealthKitManager.shared
    }()
    
    // MARK: - Second layers
    private(set) lazy var startKit: StartKit = {
        return StartKit(communicationService: communicationService, healthManager: healthManager)
    }()
    
    private(set) lazy var workoutKit: WorkoutKit = {
        return WorkoutKit(communicationService: communicationService)
    }()
    
    // MARK: - UI Services
    private(set) lazy var startService: StartService = {
        return StartService(startKit: startKit, healthManager: healthManager)
    }()
    
    private(set) lazy var workoutService: WorkoutService = {
        return WorkoutService(workoutKit: workoutKit, communicationService: communicationService)
    }()
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    func initializeServices() {
        // Просто обращаемся к lazy свойствам для их инициализации
        _ = communicationService
        _ = healthManager
        _ = startKit
        _ = workoutKit
        _ = startService
        _ = workoutService
    }
}
