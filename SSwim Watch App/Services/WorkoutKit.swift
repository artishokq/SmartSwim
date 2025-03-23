//
//  WorkoutKit.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import Foundation
import Combine

final class WorkoutKit {
    // MARK: - Publishers
    let workoutsPublisher = PassthroughSubject<[SwimWorkoutModels.SwimWorkout], Never>()
    
    // MARK: - Properties
    private let communicationService: WatchCommunicationService
    private var subscriptionIds: [UUID] = []
    
    private var _workouts: [SwimWorkoutModels.SwimWorkout] = []
    private var workoutsLock = NSLock()
    
    private var _pendingWorkoutsRequest = false
    private var pendingLock = NSLock()
    
    // MARK: - Thread-safe getters and setters
    var workouts: [SwimWorkoutModels.SwimWorkout] {
        get {
            workoutsLock.lock()
            defer { workoutsLock.unlock() }
            return _workouts
        }
        set {
            workoutsLock.lock()
            _workouts = newValue
            workoutsLock.unlock()
            workoutsPublisher.send(newValue)
        }
    }
    
    var pendingWorkoutsRequest: Bool {
        get {
            pendingLock.lock()
            defer { pendingLock.unlock() }
            return _pendingWorkoutsRequest
        }
        set {
            pendingLock.lock()
            _pendingWorkoutsRequest = newValue
            pendingLock.unlock()
        }
    }
    
    // MARK: - Initialization
    init(communicationService: WatchCommunicationService) {
        self.communicationService = communicationService
        subscribeToMessages()
        loadWorkoutsFromLocalStorage()
    }
    
    deinit {
        for id in subscriptionIds {
            communicationService.unsubscribe(id: id)
        }
    }
    
    // MARK: - Public Methods
    @discardableResult
    func requestWorkouts() -> Bool {
        if pendingWorkoutsRequest {
            return true
        }
        pendingWorkoutsRequest = true
        
        let cachedWorkouts = loadWorkoutsFromLocalStorage()
        if !cachedWorkouts.isEmpty {
            self.workouts = cachedWorkouts
        }
        
        let success = communicationService.sendMessage(
            type: .requestWorkouts,
            data: ["requestWorkouts": true, "requestId": UUID().uuidString]
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self else { return }
            
            if self.pendingWorkoutsRequest {
                self.pendingWorkoutsRequest = false
                
                let retrySuccess = self.communicationService.sendMessage(
                    type: .requestWorkouts,
                    data: ["requestWorkouts": true, "isRetry": true, "requestId": UUID().uuidString]
                )
            }
        }
        
        if !success {
            pendingWorkoutsRequest = false
        }
        
        return success
    }
    
    func startWorkout(workoutId: String) {
        communicationService.sendMessage(
            type: .startWorkout,
            data: [
                "workoutId": workoutId,
                "startWorkout": true
            ]
        )
    }
    
    func getWorkoutById(_ id: String) -> SwimWorkoutModels.SwimWorkout? {
        return workouts.first { $0.id == id }
    }
    
    // MARK: - Private Methods
    private func subscribeToMessages() {
        let workoutsDataId = communicationService.subscribe(to: .workoutsData) { [weak self] message in
            if let workoutsData = message["workoutsData"] as? [[String: Any]] {
                self?.processWorkoutsData(workoutsData)
            }
        }
        subscriptionIds.append(workoutsDataId)
    }
    
    private func processWorkoutsData(_ workoutsData: [[String: Any]]) {
        let receivedWorkouts = workoutsData.compactMap { SwimWorkoutModels.SwimWorkout.fromDictionary($0) }
        saveWorkoutsLocally(receivedWorkouts)
        
        DispatchQueue.main.async {
            self.workouts = receivedWorkouts
            self.pendingWorkoutsRequest = false
        }
    }
    
    private func saveWorkoutsLocally(_ workouts: [SwimWorkoutModels.SwimWorkout]) {
        do {
            let encoder = JSONEncoder()
            let workoutsData = try encoder.encode(workouts)
            
            if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = docsDir.appendingPathComponent("cached_workouts.json")
                
                try workoutsData.write(to: fileURL, options: .atomic)
            }
        } catch {
        }
    }
    
    private func loadWorkoutsFromLocalStorage() -> [SwimWorkoutModels.SwimWorkout] {
        do {
            if let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileURL = docsDir.appendingPathComponent("cached_workouts.json")
                
                // Проверяем существование файла
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    // Читаем данные из файла
                    let workoutsData = try Data(contentsOf: fileURL)
                    
                    // Декодируем данные
                    let decoder = JSONDecoder()
                    let cachedWorkouts = try decoder.decode([SwimWorkoutModels.SwimWorkout].self, from: workoutsData)
                    return cachedWorkouts
                }
            }
        } catch {
        }
        return []
    }
}
