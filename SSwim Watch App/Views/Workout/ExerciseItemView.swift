//
//  ExerciseItemView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import SwiftUI

struct ExerciseItemView: View {
    // MARK: - Constants
    private enum Constants {
        static let cornerRadius: CGFloat = 8
        static let padding: CGFloat = 10
        static let spacingV: CGFloat = 4
        static let backgroundColor = Color.gray.opacity(0.15)
        
        static let typeHorizontalPadding: CGFloat = 5
        static let typeTetxColor: Color = .blue
        
        static let intervalTextColor: Color = .gray
        
        static let descriptionTextColor: Color = .secondary
        static let descriptionTopPadding: CGFloat = 2
    }
    
    // MARK: - Properties
    let exercise: SwimWorkoutModels.SwimExercise
    let index: Int
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.spacingV) {
            HStack {
                Text("\(index).")
                    .font(.subheadline)
                
                // Тип упражнения
                Text(exercise.getTypeName())
                    .font(.caption)
                    .foregroundColor(Constants.typeTetxColor)
                    .padding(.horizontal, Constants.typeHorizontalPadding)
            }
            
            // Метры, повторения, стиль
            if exercise.repetitions > 1 {
                Text("\(exercise.repetitions)×\(exercise.meters)м \(exercise.getStyleName())")
                    .font(.subheadline)
            } else {
                Text("\(exercise.meters)м \(exercise.getStyleName())")
                    .font(.subheadline)
            }
            
            // Режим (интервал)
            if !exercise.getFormattedInterval().isEmpty {
                Text(exercise.getFormattedInterval())
                    .font(.caption)
                    .foregroundColor(Constants.intervalTextColor)
            }
            
            // Описание
            if let description = exercise.description, !description.isEmpty {
                Text(description)
                    .font(.caption2)
                    .foregroundColor(Constants.descriptionTextColor)
                    .padding(.top, Constants.descriptionTopPadding)
            }
        }
        .padding(Constants.padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Constants.backgroundColor)
        .cornerRadius(Constants.cornerRadius)
    }
}

// MARK: - Previews
struct ExerciseItemView_Previews: PreviewProvider {
    static var previews: some View {
        ExerciseItemView(
            exercise: SwimWorkoutModels.SwimExercise(
                id: "1",
                description: "Плыть с хорошей техникой, фокус на гребок",
                style: 0,
                type: 0,
                hasInterval: true,
                intervalMinutes: 1,
                intervalSeconds: 0,
                meters: 100,
                orderIndex: 0,
                repetitions: 4
            ),
            index: 1
        )
    }
}
