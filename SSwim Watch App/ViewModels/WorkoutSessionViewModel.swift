//
//  WorkoutSessionViewModel.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 24.03.2025.
//

import Foundation
import Combine
import SwiftUI

final class WorkoutSessionViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var sessionService: WorkoutSessionService
    @Published var showingExercisePreview = false
    @Published var showingActiveExercise = false
    @Published var showingCompletionView = false
    @Published var navigateBack = false
    
    // MARK: - Public Properties
    var workout: SwimWorkoutModels.SwimWorkout {
        return sessionService.workout
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(workout: SwimWorkoutModels.SwimWorkout) {
        self.sessionService = WorkoutSessionService(workout: workout)
        setupStateObservers()
    }
    
    // MARK: - Public Methods
    func startSession() {
        sessionService.startSession()
    }
    
    func startCurrentExercise() {
        sessionService.startCurrentExercise()
    }
    
    func completeCurrentExercise() {
        sessionService.completeCurrentExercise()
    }
    
    func completeSession() {
        sessionService.completeSession()
        navigateBack = true
    }
    
    // MARK: - Private Methods
    private func setupStateObservers() {
        // Наблюдаем за изменениями состояния сессии
        sessionService.$sessionState
            .sink { [weak self] state in
                self?.updateViewState(for: state)
            }
            .store(in: &cancellables)
    }
    
    private func updateViewState(for state: SwimWorkoutModels.WorkoutSessionState) {
        switch state {
        case .notStarted:
            showingExercisePreview = false
            showingActiveExercise = false
            showingCompletionView = false
            
        case .previewingExercise:
            showingExercisePreview = true
            showingActiveExercise = false
            showingCompletionView = false
            
        case .exerciseActive:
            showingExercisePreview = false
            showingActiveExercise = true
            showingCompletionView = false
            
        case .completed:
            showingExercisePreview = false
            showingActiveExercise = false
            showingCompletionView = true
        }
    }
}
