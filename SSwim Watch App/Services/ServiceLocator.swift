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
    
    // MARK: - Private Methods
    func checkAndSyncPendingWorkouts() {
        let fileManager = FileManager.default
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("pending_workouts.json")
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }
        
        do {
            let savedData = try Data(contentsOf: fileURL)
            guard let savedWorkouts = try JSONSerialization.jsonObject(with: savedData) as? [[String: Any]], !savedWorkouts.isEmpty else {
                return
            }
            
            print("При запуске приложения найдено \(savedWorkouts.count) ожидающих отправки тренировок")
            
            if communicationService.isReachable {
                for workoutData in savedWorkouts {
                    if let metadata = workoutData["workoutMetadata"] as? [String: Any],
                       let sendId = workoutData["sendId"] as? String {
                        
                        communicationService.sendMessageWithReply(
                            type: .command,
                            data: [
                                "workoutCompleted": true,
                                "workoutMetadata": metadata,
                                "sendId": sendId
                            ],
                            timeout: 5.0
                        ) { response in
                            if let confirmed = response?["workoutDataReceived"] as? Bool, confirmed {
                                print("Получено подтверждение от iPhone о получении отложенных данных тренировки")
                                self.removeLocalWorkoutData(sendId: sendId)
                            }
                        }
                    }
                }
            } else {
                print("iPhone недоступен при запуске, синхронизация отложена")
            }
        } catch {
            print("Ошибка при проверке ожидающих тренировок: \(error)")
        }
    }
    
    private func removeLocalWorkoutData(sendId: String) {
        do {
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            let fileURL = documentsDirectory.appendingPathComponent("pending_workouts.json")
            
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return
            }
            
            let savedData = try Data(contentsOf: fileURL)
            guard var savedWorkouts = try JSONSerialization.jsonObject(with: savedData) as? [[String: Any]] else {
                return
            }
            
            savedWorkouts.removeAll { workout in
                return (workout["sendId"] as? String) == sendId
            }
            
            let updatedData = try JSONSerialization.data(withJSONObject: savedWorkouts)
            try updatedData.write(to: fileURL)
            print("Локально сохраненные данные удалены после успешной отправки")
        } catch {
            print("Ошибка при удалении данных тренировки: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func initializeServices() {
        _ = communicationService
        _ = workoutKitManager
        _ = startKit
        _ = workoutKit
        _ = startService
        _ = workoutService
        
        checkAndSyncPendingWorkouts()
    }
    
    func requestWorkoutPermissions() {
        workoutKitManager.requestAuthorization { success, error in
            if !success {
                print("Failed to get authorization: \(String(describing: error))")
            }
        }
    }
}
