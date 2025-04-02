//
//  WorkoutSessionView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 24.03.2025.
//

import SwiftUI

struct WorkoutSessionView: View {
    @StateObject var viewModel: WorkoutSessionViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var refreshTrigger = false
    
    init(workout: SwimWorkoutModels.SwimWorkout) {
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(workout: workout))
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if viewModel.showingExercisePreview {
                ExercisePreviewView(
                    exercise: viewModel.nextExercisePreviewData,
                    onStart: {
                        viewModel.startCurrentExercise()
                        refreshTrigger.toggle()
                    }
                )
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 1.1)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
                .animation(.easeInOut(duration: 0.5), value: viewModel.showingExercisePreview)
            }
            
            if viewModel.showingCountdown {
                CountdownView(onComplete: {
                    viewModel.startExerciseAfterCountdown()
                    refreshTrigger.toggle()
                })
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: viewModel.showingCountdown)
            }
            
            if viewModel.showingActiveExercise {
                ExerciseActiveView(
                    exercise: viewModel.currentExerciseData,
                    sessionTime: viewModel.totalSessionTime,
                    repetitionTime: viewModel.currentRepetitionTime,
                    heartRate: viewModel.heartRate,
                    strokeCount: viewModel.strokeCount,
                    currentRepetition: viewModel.currentRepetition,
                    totalRepetitions: viewModel.totalRepetitions,
                    intervalTimeRemaining: viewModel.intervalTimeRemaining,
                    canCompleteExercise: viewModel.canCompleteExercise,
                    shouldShowNextRepButton: viewModel.shouldShowNextRepButton,
                    onComplete: {
                        viewModel.completeCurrentExercise()
                        refreshTrigger.toggle()
                    }
                )
                .id("active-\(viewModel.totalSessionTime)-\(viewModel.heartRate)-\(viewModel.currentRepetition)-\(viewModel.canCompleteExercise)")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.9)),
                    removal: .opacity.combined(with: .scale(scale: 0.9))
                ))
                .animation(.easeInOut(duration: 0.5), value: viewModel.showingActiveExercise)
            }
            
            if viewModel.showingCompletionView {
                WorkoutCompletionView(
                    onComplete: {
                        viewModel.completeSession()
                        refreshTrigger.toggle()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 1.1)))
                .animation(.easeInOut(duration: 0.5), value: viewModel.showingCompletionView)
            }
            
            if !viewModel.showingExercisePreview && !viewModel.showingCountdown &&
                !viewModel.showingActiveExercise && !viewModel.showingCompletionView {
                ProgressView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            refreshTrigger.toggle()
                        }
                    }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Начинаем сессию когда появляется view
            viewModel.startSession()
            
            // Заставляем несколько раз перезагрузиться
            for delay in [0.5, 1.5, 3.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    refreshTrigger.toggle()
                }
            }
        }
        .onChange(of: viewModel.navigateBack) { _, newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            // Чтобы стригерить view refreshers
        }
    }
}
