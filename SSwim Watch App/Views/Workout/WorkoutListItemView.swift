//
//  WorkoutListItemView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import SwiftUI

struct WorkoutListItemView: View {
    // MARK: - Constants
    private enum Constants {
        static let cornerRadius: CGFloat = 8
        static let padding: CGFloat = 12
        static let backgroundColor = Color.gray.opacity(0.2)
        static let itemSpacing: CGFloat = 2
        static let poolSizeFormat = "Бассейн: %dм"
    }
    
    // MARK: - Properties
    let workout: SwimWorkoutModels.SwimWorkout
    
    // MARK: - Body
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Constants.itemSpacing) {
                // Название тренировки
                Text(workout.name)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                // Размер бассейна
                Text(String(format: Constants.poolSizeFormat, workout.poolSize))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                // Общий метраж тренировки
                Text("\(workout.totalMeters)м")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(Constants.padding)
        .background(Constants.backgroundColor)
        .cornerRadius(Constants.cornerRadius)
    }
}

// MARK: - Previews
struct WorkoutListItemView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutListItemView(
            workout: SwimWorkoutModels.SwimWorkout(
                id: "1",
                name: "Тренировка #1",
                poolSize: 25,
                exercises: []
            )
        )
        .previewLayout(.sizeThatFits)
    }
}
