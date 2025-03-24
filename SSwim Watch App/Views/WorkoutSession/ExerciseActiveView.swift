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
        static let countTextLeadingSpacing: String = "   "
        
        static let heartIcon: String = "heart.fill"
        
        static let totalTimeFontSize: CGFloat = 32
        static let repetitionTimeFontSize: CGFloat = 22
        static let displayNameFontSize: CGFloat = 24
        static let heartRateFontSize: CGFloat = 30
        static let heartRateIconSize: CGFloat = 24
        static let buttonTextFontSize: CGFloat = 18
        
        static let verticalSpacing: CGFloat = 0
        static let repetitionTimeTopPadding: CGFloat = -3
        static let countTextSpacing: CGFloat = 4
        static let buttonMinWidth: CGFloat = 140
        static let buttonMinHeight: CGFloat = 44
        static let buttonCornerRadius: CGFloat = 8
        
        static let headerColor: Color = Color.blue
        static let totalTimeColor: Color = Color.yellow
        static let repTimeColor: Color = Color.blue
        static let exerciseNameColor: Color = Color.green
        static let repCountColor: Color = Color.red
        static let heartIconColor: Color = Color.red
        static let buttonBackgroundColor: Color = Color.green
        static let buttonTextColor: Color = Color.black
        static let backgroundColor: Color = Color.black
    }
    
    let exercise: SwimWorkoutModels.ActiveExerciseData?
    let onComplete: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            if let exercise = exercise {
                // Заголовок
                Text(Constants.exercisePrefix + "\(exercise.index)")
                    .font(.headline)
                    .foregroundColor(Constants.headerColor)
                
                // Общее время тренировки
                Text(exercise.formattedTotalTime)
                    .font(.system(size: Constants.totalTimeFontSize, weight: .bold))
                    .foregroundColor(Constants.totalTimeColor)
                
                // Время текущего повторения/интервала
                Text(exercise.formattedRepetitionTime)
                    .font(.system(size: Constants.repetitionTimeFontSize, weight: .medium))
                    .foregroundColor(Constants.repTimeColor)
                    .padding(.top, Constants.repetitionTimeTopPadding)
                
                // Информация о дистанции, счётчике повторов и стиле
                Group {
                    if exercise.exerciseRef.repetitions > 1 {
                        // Для интервальных упражнений: название и счётчик рядом
                        HStack(spacing: Constants.countTextSpacing) {
                            Text(exercise.exerciseRef.displayName)
                                .font(.system(size: Constants.displayNameFontSize, weight: .bold))
                                .foregroundColor(Constants.exerciseNameColor)
                            
                            Text(Constants.countTextLeadingSpacing + "\(exercise.currentRepetition)/\(exercise.exerciseRef.repetitions)")
                                .font(.system(size: Constants.displayNameFontSize, weight: .bold))
                                .foregroundColor(Constants.repCountColor)
                        }
                    } else {
                        // Для одиночных упражнений
                        Text(exercise.exerciseRef.displayName)
                            .font(.system(size: Constants.displayNameFontSize, weight: .bold))
                            .foregroundColor(Constants.exerciseNameColor)
                    }
                    
                    Text(exercise.exerciseRef.getStyleName())
                        .font(.body)
                }
                
                // Пульс
                HStack {
                    Text("\(Int(exercise.heartRate))")
                        .font(.system(size: Constants.heartRateFontSize, weight: .bold))
                    
                    Image(systemName: Constants.heartIcon)
                        .font(.system(size: Constants.heartRateIconSize))
                        .foregroundColor(Constants.heartIconColor)
                }
                
                Spacer()
                // Кнопка "Далее"
                HStack {
                    Button(action: onComplete) {
                        Text(Constants.nextButtonText)
                            .font(.system(size: Constants.buttonTextFontSize, weight: .medium))
                            .frame(minWidth: Constants.buttonMinWidth, minHeight: Constants.buttonMinHeight)
                            .background(Constants.buttonBackgroundColor)
                            .foregroundColor(Constants.buttonTextColor)
                            .cornerRadius(Constants.buttonCornerRadius)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
            } else {
                ProgressView()
            }
        }
        .padding()
        .background(Constants.backgroundColor)
    }
}
