//
//  ExerciseActiveView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 24.03.2025.
//

import Foundation
import SwiftUI

struct ExerciseActiveView: View {
    private enum Constants {
        static let exercisePrefix: String = "Задание "
        static let nextButtonText: String = "Далее"
        static let nextRepButtonText: String = "След. повт."
        static let completeButtonText: String = "Завершить"
        static let waitingButtonText: String = "Выполняется..."
        static let remainingTimeText: String = "Осталось: "
        
        static let headerFontSize: CGFloat = 16
        static let totalTimeFontSize: CGFloat = 28
        static let repetitionTimeFontSize: CGFloat = 20
        static let displayNameFontSize: CGFloat = 20
        static let styleNameFontSize: CGFloat = 18
        static let repCountFontSize: CGFloat = 20
        static let heartRateFontSize: CGFloat = 18
        static let heartRateIconSize: CGFloat = 18
        static let intervalTimeFontSize: CGFloat = 14
        static let buttonTextFontSize: CGFloat = 16
        
        static let minVerticalSpacing: CGFloat = -2
        static let compactVerticalSpacing: CGFloat = 0
        static let buttonMinWidth: CGFloat = 120
        static let buttonMinHeight: CGFloat = 36
        static let buttonCornerRadius: CGFloat = 8
        static let verticalPadding: CGFloat = 6
        
        static let headerColor: Color = Color.blue
        static let totalTimeColor: Color = Color.yellow
        static let repTimeColor: Color = Color.blue
        static let exerciseNameColor: Color = Color.green
        static let styleNameColor: Color = Color.white
        static let repCountColor: Color = Color.red
        static let heartIconColor: Color = Color.red
        static let timerColor: Color = Color.orange
        static let buttonBackgroundColor: Color = Color.green
        static let buttonBackgroundDisabledColor: Color = Color.gray
        static let buttonTextColor: Color = Color.black
        static let backgroundColor: Color = Color.black
    }
    
    let exercise: SwimWorkoutModels.ActiveExerciseData?
    
    let sessionTime: TimeInterval
    let repetitionTime: TimeInterval
    let heartRate: Double
    let strokeCount: Int
    
    let currentRepetition: Int
    let totalRepetitions: Int
    let intervalTimeRemaining: TimeInterval
    let canCompleteExercise: Bool
    let shouldShowNextRepButton: Bool
    
    let onComplete: () -> Void
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) / 60 % 60
        let seconds = Int(interval) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func formatIntervalTimeRemaining() -> String {
        let minutes = Int(intervalTimeRemaining) / 60
        let seconds = Int(intervalTimeRemaining) % 60
        
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func getButtonText() -> String {
        if !canCompleteExercise && !shouldShowNextRepButton {
            return Constants.waitingButtonText
        } else if shouldShowNextRepButton {
            return Constants.nextRepButtonText
        } else if canCompleteExercise {
            return Constants.completeButtonText
        } else {
            return Constants.nextButtonText
        }
    }
    
    private func getButtonBackground() -> Color {
        if !canCompleteExercise && !shouldShowNextRepButton {
            return Constants.buttonBackgroundDisabledColor
        } else {
            return Constants.buttonBackgroundColor
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.compactVerticalSpacing) {
            if let exercise = exercise {
                // Заголовок номер задания
                Text(Constants.exercisePrefix + "\(exercise.index)")
                    .font(.system(size: Constants.headerFontSize, weight: .semibold))
                    .foregroundColor(Constants.headerColor)
                    .padding(.bottom, Constants.minVerticalSpacing)
                
                // Общее время
                Text(formatTimeInterval(sessionTime))
                    .font(.system(size: Constants.totalTimeFontSize, weight: .bold))
                    .foregroundColor(Constants.totalTimeColor)
                    .padding(.bottom, Constants.minVerticalSpacing)
                
                // Время текущего задания
                Text(formatTimeInterval(repetitionTime))
                    .font(.system(size: Constants.repetitionTimeFontSize, weight: .medium))
                    .foregroundColor(Constants.repTimeColor)
                    .padding(.bottom, Constants.minVerticalSpacing)
                
                // Оставшееся время интервала
                if exercise.exerciseRef.hasInterval && intervalTimeRemaining > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "timer")
                            .foregroundColor(Constants.timerColor)
                            .font(.system(size: Constants.intervalTimeFontSize))
                        
                        Text(Constants.remainingTimeText + formatIntervalTimeRemaining())
                            .font(.system(size: Constants.intervalTimeFontSize))
                            .foregroundColor(Constants.timerColor)
                    }
                    .padding(.bottom, Constants.minVerticalSpacing)
                }
                
                // Метраж/повторения с текущим повторением справа
                HStack {
                    Text(exercise.exerciseRef.displayName)
                        .font(.system(size: Constants.displayNameFontSize, weight: .semibold))
                        .foregroundColor(Constants.exerciseNameColor)
                    
                    Spacer()
                    
                    if totalRepetitions > 1 {
                        Text("\(currentRepetition)/\(totalRepetitions)")
                            .font(.system(size: Constants.repCountFontSize, weight: .bold))
                            .foregroundColor(Constants.repCountColor)
                    }
                }
                .padding(.bottom, Constants.minVerticalSpacing)
                
                // Стиль плавания с пульсом справа
                HStack {
                    Text(exercise.exerciseRef.getStyleName())
                        .font(.system(size: Constants.styleNameFontSize))
                        .foregroundColor(Constants.styleNameColor)
                    
                    Spacer()
                    
                    // Пульс
                    HStack(spacing: 2) {
                        Text("\(Int(heartRate))")
                            .font(.system(size: Constants.heartRateFontSize, weight: .bold))
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: Constants.heartRateIconSize))
                            .foregroundColor(Constants.heartIconColor)
                    }
                }
                .padding(.bottom, 2)
                
                Spacer()
                
                // Кнопка
                HStack {
                    Spacer()
                    Button(action: onComplete) {
                        Text(getButtonText())
                            .font(.system(size: Constants.buttonTextFontSize, weight: .medium))
                            .frame(minWidth: Constants.buttonMinWidth, minHeight: Constants.buttonMinHeight)
                            .background(getButtonBackground())
                            .foregroundColor(Constants.buttonTextColor)
                            .cornerRadius(Constants.buttonCornerRadius)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(!canCompleteExercise && !shouldShowNextRepButton)
                    Spacer()
                }
                .padding(.bottom, Constants.verticalPadding)
                
            } else {
                ProgressView()
            }
        }
        .padding(.horizontal)
        .padding(.top, Constants.verticalPadding)
        .background(Constants.backgroundColor)
        .id("exercise-\(sessionTime)-\(repetitionTime)-\(heartRate)-\(currentRepetition)-\(intervalTimeRemaining)")
    }
}

// MARK: - Previews
struct ActiveExerciseViewRefactored_Previews: PreviewProvider {
    static var previews: some View {
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
        
        ExerciseActiveView(
            exercise: activeExerciseData,
            sessionTime: 120,
            repetitionTime: 45,
            heartRate: 145,
            strokeCount: 30,
            currentRepetition: 3,
            totalRepetitions: 20,
            intervalTimeRemaining: 30,
            canCompleteExercise: false,
            shouldShowNextRepButton: false,
            onComplete: {}
        )
    }
}
