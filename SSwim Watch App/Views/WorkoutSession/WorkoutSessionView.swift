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
    
    init(workout: SwimWorkoutModels.SwimWorkout) {
        _viewModel = StateObject(wrappedValue: WorkoutSessionViewModel(workout: workout))
    }
    
    var body: some View {
        ZStack {
            // Превью упражнения
            if viewModel.showingExercisePreview {
                ExercisePreviewView(
                    exercise: viewModel.sessionService.nextExercisePreview,
                    onStart: { viewModel.startCurrentExercise() }
                )
            }
            
            // Активное упражнение
            if viewModel.showingActiveExercise {
                ExerciseActiveView(
                    exercise: viewModel.sessionService.currentExercise,
                    onComplete: { viewModel.completeCurrentExercise() }
                )
            }
            
            // Экран завершения
            if viewModel.showingCompletionView {
                WorkoutCompletionView(
                    onComplete: { viewModel.completeSession() }
                )
            }
        }
        .onAppear {
            // Начинаем сессию автоматически при показе экрана
            viewModel.startSession()
        }
        .onChange(of: viewModel.navigateBack) { _, newValue in
            if newValue {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Previews
struct WorkoutSessionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Создаем тестовые данные для превью
            let exercise = SwimWorkoutModels.SwimExercise(
                id: "test-1",
                description: nil,
                style: 0,
                type: 1,
                hasInterval: true,
                intervalMinutes: 1,
                intervalSeconds: 0,
                meters: 50,
                orderIndex: 0,
                repetitions: 20
            )
            
            let activeExerciseData = SwimWorkoutModels.ActiveExerciseData(
                from: exercise,
                index: 2,
                totalExercises: 3
            )
            
            // Превью активного упражнения
            ExerciseActiveView(
                exercise: activeExerciseData,
                onComplete: {}
            )
            .previewDisplayName("Активное упражнение")
            
            // Превью экрана упражнения
            ExercisePreviewView(
                exercise: activeExerciseData,
                onStart: {}
            )
            .previewDisplayName("Превью упражнения")
            
            // Превью завершения
            WorkoutCompletionView(onComplete: {})
                .previewDisplayName("Завершение тренировки")
        }
    }
}
