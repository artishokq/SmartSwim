//
//  WorkoutDetailView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import SwiftUI

struct WorkoutDetailView: View {
    // MARK: - Constants
    private enum Constants {
        static let poolLengthFormat = "Бассейн: %dм"
        static let totalFormat = "Всего: %dм"
        static let startButton = "Начать"
        
        static let mainStackSpacing: CGFloat = 12
        static let titleStackSpacing: CGFloat = 2
        static let exerciseStackSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let buttonHeight: CGFloat = 44
        static let vstackTopPadding: CGFloat = 8
        static let totalMetersTopPadding: CGFloat = 4
        static let buttonBottomPadding: CGFloat = 12
        
        static let primaryColor = Color.green
    }
    
    // MARK: - Properties
    let workout: SwimWorkoutModels.SwimWorkout
    @State private var showingWorkoutSession = false
    @EnvironmentObject private var workoutService: WorkoutService
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.mainStackSpacing) {
                VStack(spacing: Constants.titleStackSpacing) {
                    Text(workout.name)
                        .font(.headline)
                    
                    Text(String(format: Constants.poolLengthFormat, workout.poolSize))
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                .padding(.top, Constants.vstackTopPadding)
                
                // Список упражнений
                exercisesList
                
                // Общая информация и кнопка старта
                Text(String(format: Constants.totalFormat, workout.totalMeters))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal)
                    .padding(.top, Constants.totalMetersTopPadding)
                
                // Кнопка Начать
                Button(action: {
                    // Выбираем эту тренировку
                    workoutService.selectWorkout(workout)
                    // Показываем экран сессии
                    showingWorkoutSession = true
                }) {
                    Text(Constants.startButton)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: Constants.buttonHeight)
                        .background(Constants.primaryColor)
                        .foregroundColor(.white)
                        .cornerRadius(Constants.cornerRadius)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, Constants.buttonBottomPadding)
            }
        }
        .navigationDestination(isPresented: $showingWorkoutSession) {
            WorkoutSessionView(workout: workout)
        }
    }
    
    // MARK: - Views
    private var exercisesList: some View {
        VStack(spacing: Constants.exerciseStackSpacing) {
            let sortedExercises = workout.exercises.sorted { $0.orderIndex < $1.orderIndex }
            
            ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                ExerciseItemView(exercise: exercise, index: index + 1)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Previews
struct WorkoutDetailView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutDetailView(
            workout: SwimWorkoutModels.SwimWorkout(
                id: "1",
                name: "Тренировка #1",
                poolSize: 25,
                exercises: [
                    SwimWorkoutModels.SwimExercise(
                        id: "1-1",
                        description: "плыть спокойно",
                        style: 0,
                        type: 1,
                        hasInterval: false,
                        intervalMinutes: 0,
                        intervalSeconds: 0,
                        meters: 800,
                        orderIndex: 0,
                        repetitions: 1
                    ),
                    SwimWorkoutModels.SwimExercise(
                        id: "1-2",
                        description: nil,
                        style: 0,
                        type: 0,
                        hasInterval: true,
                        intervalMinutes: 1,
                        intervalSeconds: 30,
                        meters: 50,
                        orderIndex: 1,
                        repetitions: 20
                    )
                ]
            )
        )
        .environmentObject(ServiceLocator.shared.workoutService)
    }
}
