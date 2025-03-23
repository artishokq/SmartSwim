//
//  WorkoutListView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import SwiftUI

struct WorkoutListView: View {
    // MARK: - Constants
    private enum Constants {
        static let emptyMessage = "Нет доступных тренировок"
        static let loadingMessage = "Загрузка тренировок..."
        static let itemSpacing: CGFloat = 8
    }
    
    // MARK: - Properties
    @EnvironmentObject private var workoutService: WorkoutService
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.itemSpacing) {
            if workoutService.isLoading {
                Text(Constants.loadingMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
            } else if workoutService.workouts.isEmpty {
                Text(Constants.emptyMessage)
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding()
            } else {
                workoutsList
            }
        }
    }
    
    // MARK: - Views
    private var workoutsList: some View {
        VStack(spacing: Constants.itemSpacing) {
            ForEach(workoutService.workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    WorkoutListItemView(workout: workout)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

// MARK: - Previews
struct WorkoutListView_Previews: PreviewProvider {
    static var previews: some View {
        WorkoutListView()
            .environmentObject(ServiceLocator.shared.workoutService)
    }
}
