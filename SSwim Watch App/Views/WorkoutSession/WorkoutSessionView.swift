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
        VStack {
            if viewModel.showingExercisePreview {
                ExercisePreviewView(
                    exercise: viewModel.nextExercisePreviewData,
                    onStart: {
                        viewModel.startCurrentExercise()
                        refreshTrigger.toggle()
                    }
                )
            } else if viewModel.showingActiveExercise {
                // Отдельные свойства, а не только объект упражнения чтобы обеспечить обновление представления при изменении свойств
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
                .id("active-\(viewModel.totalSessionTime)-\(viewModel.heartRate)-\(viewModel.currentRepetition)-\(viewModel.canCompleteExercise)") // Force view updates
            } else if viewModel.showingCompletionView {
                WorkoutCompletionView(
                    onComplete: {
                        viewModel.completeSession()
                        refreshTrigger.toggle()
                    }
                )
            } else {
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
