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
    @Published var sessionState: SwimWorkoutModels.WorkoutSessionState = .notStarted
    @Published var showingExercisePreview = false
    @Published var showingActiveExercise = false
    @Published var showingCompletionView = false
    @Published var navigateBack = false
    
    // Exercise data - redeclared here to force UI updates
    @Published var currentExerciseData: SwimWorkoutModels.ActiveExerciseData?
    @Published var nextExercisePreviewData: SwimWorkoutModels.ActiveExerciseData?
    
    // Added direct published properties for critical values
    @Published var totalSessionTime: TimeInterval = 0
    @Published var currentRepetitionTime: TimeInterval = 0
    @Published var heartRate: Double = 0
    @Published var strokeCount: Int = 0
    
    // New properties for interval and repetition control
    @Published var currentRepetition: Int = 1
    @Published var totalRepetitions: Int = 1
    @Published var intervalTimeRemaining: TimeInterval = 0
    @Published var canCompleteExercise: Bool = false
    @Published var shouldShowNextRepButton: Bool = false
    @Published var isLastRepetition: Bool = true
    
    // MARK: - Service
    private let sessionService: WorkoutSessionService
    
    // MARK: - Public Properties
    var workout: SwimWorkoutModels.SwimWorkout {
        return sessionService.workout
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    init(workout: SwimWorkoutModels.SwimWorkout) {
        self.sessionService = WorkoutSessionService(workout: workout)
        setupStateObservers()
        setupRefreshTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
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
        // Observe session state changes
        sessionService.$sessionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.sessionState = state
                self?.updateViewState(for: state)
            }
            .store(in: &cancellables)
        
        // Observe current exercise changes
        sessionService.$currentExercise
            .receive(on: DispatchQueue.main)
            .sink { [weak self] exercise in
                self?.currentExerciseData = exercise
                
                // Update the direct properties for better reactivity
                if let exercise = exercise {
                    self?.totalSessionTime = exercise.totalSessionTime
                    self?.currentRepetitionTime = exercise.currentRepetitionTime
                    self?.heartRate = exercise.heartRate
                    self?.strokeCount = exercise.strokeCount
                }
                
                // Force UI update
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Observe preview exercise changes
        sessionService.$nextExercisePreview
            .receive(on: DispatchQueue.main)
            .sink { [weak self] exercise in
                self?.nextExercisePreviewData = exercise
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        // Observe interval and repetition state
        sessionService.$isIntervalCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCompleted in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        sessionService.$intervalTimeRemaining
            .receive(on: DispatchQueue.main)
            .sink { [weak self] timeRemaining in
                self?.intervalTimeRemaining = timeRemaining
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        sessionService.$canCompleteExercise
            .receive(on: DispatchQueue.main)
            .sink { [weak self] canComplete in
                self?.canCompleteExercise = canComplete
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        sessionService.$currentRepetitionNumber
            .receive(on: DispatchQueue.main)
            .sink { [weak self] repetition in
                self?.currentRepetition = repetition
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        sessionService.$totalRepetitions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] total in
                self?.totalRepetitions = total
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        sessionService.$isLastRepetition
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLast in
                self?.isLastRepetition = isLast
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        sessionService.$shouldShowNextRepButton
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shouldShow in
                self?.shouldShowNextRepButton = shouldShow
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    private func setupRefreshTimer() {
        // Add a refresh timer to ensure UI updates even if Combine pipeline misses updates
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.showingActiveExercise else { return }
            
            // Poll the service for latest data
            if let exercise = self.sessionService.currentExercise {
                self.totalSessionTime = exercise.totalSessionTime
                self.currentRepetitionTime = exercise.currentRepetitionTime
                self.heartRate = exercise.heartRate
                self.strokeCount = exercise.strokeCount
                
                // Also poll interval and repetition state
                self.intervalTimeRemaining = self.sessionService.intervalTimeRemaining
                self.canCompleteExercise = self.sessionService.canCompleteExercise
                self.currentRepetition = self.sessionService.currentRepetitionNumber
                self.totalRepetitions = self.sessionService.totalRepetitions
                self.shouldShowNextRepButton = self.sessionService.shouldShowNextRepButton
                
                // Force UI update
                DispatchQueue.main.async {
                    self.objectWillChange.send()
                }
            }
        }
    }
    
    private func updateViewState(for state: SwimWorkoutModels.WorkoutSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notStarted:
                self.showingExercisePreview = false
                self.showingActiveExercise = false
                self.showingCompletionView = false
                
            case .previewingExercise:
                self.showingExercisePreview = true
                self.showingActiveExercise = false
                self.showingCompletionView = false
                
            case .exerciseActive:
                self.showingExercisePreview = false
                self.showingActiveExercise = true
                self.showingCompletionView = false
                
            case .completed:
                self.showingExercisePreview = false
                self.showingActiveExercise = false
                self.showingCompletionView = true
            }
            
            // Force UI update
            self.objectWillChange.send()
        }
    }
}
