//
//  ExercisePreviewView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 24.03.2025.
//

import Foundation
import SwiftUI

struct ExercisePreviewView: View {
    private enum Constants {
        static let exercisePrefix: String = "Задание "
        static let warmupText: String = "Разминка"
        static let cooldownText: String = "Заминка"
        static let mainExerciseText: String = "Основное"
        static let modeText: String = "Режим:"
        static let startButtonText: String = "Начать"
        
        static let warmupTypeValue: Int = 1
        static let cooldownTypeValue: Int = 2
        static let mainExerciseTypeValue: Int = 0
        
        static let displayNameFontSize: CGFloat = 28
        static let styleNameFontSize: CGFloat = 22
        static let modeLabelFontSize: CGFloat = 20
        static let modeValueFontSize: CGFloat = 28
        static let buttonTextFontSize: CGFloat = 18
        
        static let verticalSpacing: CGFloat = 0
        static let verticalPadding: CGFloat = 8
        static let buttonMinWidth: CGFloat = 140
        static let buttonMinHeight: CGFloat = 44
        static let buttonCornerRadius: CGFloat = 8
        
        static let headerColor: Color = Color.blue
        static let exerciseNameColor: Color = Color.green
        static let modeValueColor: Color = Color.yellow
        static let buttonBackgroundColor: Color = Color.green
        static let buttonTextColor: Color = Color.black
    }
    
    let exercise: SwimWorkoutModels.ActiveExerciseData?
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
            if let exercise = exercise {
                // Заголовок
                Text(Constants.exercisePrefix + "\(exercise.index)")
                    .font(.headline)
                    .foregroundColor(Constants.headerColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: Constants.verticalSpacing) {
                    // Данные упражнения
                    
                    // Проверяем тип упражнения для специального отображения
                    if exercise.exerciseRef.type == Constants.warmupTypeValue {
                        Text(Constants.warmupText)
                            .font(.body)
                    } else if exercise.exerciseRef.type == Constants.cooldownTypeValue {
                        Text(Constants.cooldownText)
                            .font(.body)
                    } else if exercise.exerciseRef.type == Constants.mainExerciseTypeValue {
                        Text(Constants.mainExerciseText)
                            .font(.body)
                    }
                    
                    // Метраж и повторения
                    Text(exercise.exerciseRef.displayName)
                        .font(.system(size: Constants.displayNameFontSize, weight: .bold))
                        .foregroundColor(Constants.exerciseNameColor)
                    
                    // Стиль плавания
                    Text(exercise.exerciseRef.getStyleName())
                        .font(.system(size: Constants.styleNameFontSize, weight: .semibold))
                    
                    // Интервал (режим)
                    if exercise.exerciseRef.hasInterval {
                        HStack {
                            Text(Constants.modeText)
                                .font(.system(size: Constants.modeLabelFontSize, weight: .semibold))
                            Text(exercise.formattedInterval)
                                .font(.system(size: Constants.modeValueFontSize, weight: .bold))
                                .foregroundColor(Constants.modeValueColor)
                        }
                    }
                }
                .padding(.vertical, Constants.verticalPadding)
                
                // Кнопка "Начать"
                HStack {
                    Button(action: onStart) {
                        Text(Constants.startButtonText)
                            .font(.system(size: Constants.buttonTextFontSize, weight: .medium))
                            .frame(maxWidth: Constants.buttonMinWidth, minHeight: Constants.buttonMinHeight)
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
    }
}
