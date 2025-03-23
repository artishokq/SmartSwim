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
                
                if exercise.repetitions > 1 {
                    Text("\(exercise.repetitions)×\(exercise.meters)м \(exercise.getStyleName())")
                        .font(.subheadline)
                } else {
                    Text("\(exercise.meters)м \(exercise.getStyleName())")
                        .font(.subheadline)
                }
            }
            
            if !exercise.getFormattedInterval().isEmpty {
                Text(exercise.getFormattedInterval())
                    .font(.caption)
                    .foregroundColor(.gray)
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
                description: nil,
                style: 0,
                type: 1,
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
