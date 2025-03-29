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
        
        static let warmupTypeValue: Int = 0
        static let cooldownTypeValue: Int = 2
        static let mainExerciseTypeValue: Int = 1
        
        static let displayNameFontSize: CGFloat = 24
        static let styleNameFontSize: CGFloat = 20
        static let headerFontSize: CGFloat = 16
        static let modeLabelFontSize: CGFloat = 20
        static let modeValueFontSize: CGFloat = 22
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
                // Номер задания вверху с дополнительным отступом
                ZStack(alignment: .leading) {
                    // Фоновый прямоугольник для лучшей видимости заголовка
                    Rectangle()
                        .fill(Color.black)
                        .frame(height: 26)
                    
                    // Заголовок с номером задания
                    Text(Constants.exercisePrefix + "\(exercise.index)")
                        .font(.system(size: Constants.headerFontSize, weight: .medium))
                        .foregroundColor(Constants.headerColor)
                        .padding(.vertical, 4)
                }
                .padding(.top, 4) // Отступ сверху, чтобы избежать блюринга
                
                // Проверяем тип упражнения для специального отображения
                if exercise.exerciseRef.type == Constants.warmupTypeValue {
                    Text(Constants.warmupText)
                        .font(.body)
                } else if exercise.exerciseRef.type == Constants.mainExerciseTypeValue {
                    Text(Constants.mainExerciseText)
                        .font(.body)
                }else if exercise.exerciseRef.type == Constants.cooldownTypeValue {
                    Text(Constants.cooldownText)
                        .font(.body)
                }
                
                // Метраж и повторения
                Text(exercise.exerciseRef.displayName)
                    .font(.system(size: Constants.displayNameFontSize, weight: .bold))
                    .foregroundColor(Constants.exerciseNameColor)
                
                // Стиль плавания
                Text(exercise.exerciseRef.getStyleName())
                    .font(.system(size: Constants.styleNameFontSize, weight: .semibold))
                
                // Интервал (режим) с выравниванием значения справа
                if exercise.exerciseRef.hasInterval {
                    HStack {
                        Text(Constants.modeText)
                            .font(.system(size: Constants.modeLabelFontSize, weight: .semibold))
                        Spacer()
                        Text(exercise.formattedInterval)
                            .font(.system(size: Constants.modeValueFontSize, weight: .bold))
                            .foregroundColor(Constants.modeValueColor)
                    }
                }
                
                Spacer()
                
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
        .padding(.bottom, Constants.verticalPadding)
        .padding(.horizontal, 12)
    }
}

// MARK: - Previews
struct ExercisePreviewView_Previews: PreviewProvider {
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
        
        ExercisePreviewView(
            exercise: activeExerciseData,
            onStart: {}
        )
    }
}
