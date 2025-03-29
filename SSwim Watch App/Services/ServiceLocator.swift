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
    
    private(set) lazy var workoutKitManager: WorkoutKitManager = {
        return WorkoutKitManager.shared
    }()
    
    // MARK: - Second layers
    private(set) lazy var startKit: StartKit = {
        return StartKit(communicationService: communicationService, workoutKitManager: workoutKitManager)
    }()
    
    private(set) lazy var workoutKit: WorkoutKit = {
        return WorkoutKit(communicationService: communicationService)
    }()
    
    // MARK: - UI Services
    private(set) lazy var startService: StartService = {
        return StartService(startKit: startKit, workoutKitManager: workoutKitManager)
    }()
    
    private(set) lazy var workoutService: WorkoutService = {
        return WorkoutService(workoutKit: workoutKit, communicationService: communicationService)
    }()
    
    // MARK: - Workout Session Service Factory
    func createWorkoutSessionService(for workout: SwimWorkoutModels.SwimWorkout) -> WorkoutSessionService {
        return WorkoutSessionService(
            workout: workout,
            workoutKitManager: workoutKitManager,
            communicationService: communicationService
        )
    }
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    func initializeServices() {
        // Просто обращаемся к lazy свойствам для их инициализации
        _ = communicationService
        _ = workoutKitManager
        _ = startKit
        _ = workoutKit
        _ = startService
        _ = workoutService
    }
    
    // Запрашиваем разрешения при запуске
    func requestWorkoutPermissions() {
        workoutKitManager.requestAuthorization { success, error in
            if !success {
                print("Failed to get authorization: \(String(describing: error))")
            }
        }
    }
}
