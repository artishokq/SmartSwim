//
//  WorkoutPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol WorkoutPresentationLogic {
    func presentWorkoutCreation(response: WorkoutModels.Create.Response)
    func presentInfo(response: WorkoutModels.Info.Response)
    func presentWorkouts(response: WorkoutModels.FetchWorkouts.Response)
    func presentDeleteWorkout(response: WorkoutModels.DeleteWorkout.Response)
    func presentEditWorkout(response: WorkoutModels.EditWorkout.Response)
}

final class WorkoutPresenter: WorkoutPresentationLogic {
    weak var viewController: WorkoutDisplayLogic?
    
    // MARK: - Create Workout Button
    func presentWorkoutCreation(response: WorkoutModels.Create.Response) {
        let viewModel = WorkoutModels.Create.ViewModel()
        viewController?.displayWorkoutCreation(viewModel: viewModel)
    }
    
    // MARK: - Show Info Button
    func presentInfo(response: WorkoutModels.Info.Response) {
        let viewModel = WorkoutModels.Info.ViewModel()
        viewController?.displayInfo(viewModel: viewModel)
    }
    
    // MARK: - Fetch Workouts
    func presentWorkouts(response: WorkoutModels.FetchWorkouts.Response) {
        let displayedWorkouts = response.workouts.map { workoutData -> WorkoutModels.FetchWorkouts.ViewModel.DisplayedWorkout in
            return WorkoutModels.FetchWorkouts.ViewModel.DisplayedWorkout(
                name: workoutData.name,
                totalVolume: workoutData.totalVolume,
                exercises: workoutData.exercises.map { $0.formattedString }
            )
        }
        
        let viewModel = WorkoutModels.FetchWorkouts.ViewModel(workouts: displayedWorkouts)
        viewController?.displayWorkouts(viewModel: viewModel)
    }
    
    // MARK: - Workout Deletion
    func presentDeleteWorkout(response: WorkoutModels.DeleteWorkout.Response) {
        let viewModel = WorkoutModels.DeleteWorkout.ViewModel(deletedIndex: response.deletedIndex)
        viewController?.displayDeleteWorkout(viewModel: viewModel)
    }
    
    // MARK: - Workout Edition
    func presentEditWorkout(response: WorkoutModels.EditWorkout.Response) {
        let viewModel = WorkoutModels.EditWorkout.ViewModel(index: response.index)
        viewController?.displayEditWorkout(viewModel: viewModel)
    }
}
