//
//  WorkoutService.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import Foundation
import Combine

final class WorkoutService: ObservableObject {
    // MARK: - Published Properties
    @Published var workouts: [SwimWorkoutModels.SwimWorkout] = []
    @Published var selectedWorkout: SwimWorkoutModels.SwimWorkout?
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    private let workoutKit: WorkoutKit
    private let communicationService: WatchCommunicationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(workoutKit: WorkoutKit, communicationService: WatchCommunicationService) {
        self.workoutKit = workoutKit
        self.communicationService = communicationService
        setupSubscriptions()
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        workoutKit.workoutsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] workouts in
                self?.workouts = workouts
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func loadWorkouts() {
        isLoading = true
        let success = workoutKit.requestWorkouts()
        
        if !success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                if self?.isLoading == true {
                    self?.isLoading = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        self?.loadWorkouts()
                    }
                }
            }
        }
    }
    
    func selectWorkout(_ workout: SwimWorkoutModels.SwimWorkout) {
        selectedWorkout = workout
    }
    
    func selectWorkoutById(_ id: String) {
        selectedWorkout = workoutKit.getWorkoutById(id)
    }
    
    func startSelectedWorkout() -> Bool {
        guard let workout = selectedWorkout else {
            return false
        }
        
        communicationService.sendMessage(
            type: .poolLength,
            data: ["poolSize": Double(workout.poolSize)]
        )
        
        if let firstExercise = workout.exercises.min(by: { $0.orderIndex < $1.orderIndex }) {
            communicationService.sendMessage(
                type: .swimmingStyle,
                data: ["swimmingStyle": firstExercise.style]
            )
        }
        
        communicationService.sendMessage(
            type: .totalMeters,
            data: ["totalMeters": workout.totalMeters]
        )
        
        workoutKit.startWorkout(workoutId: workout.id)
        return true
    }
    
    func hasWorkouts() -> Bool {
        return !workouts.isEmpty
    }
}
