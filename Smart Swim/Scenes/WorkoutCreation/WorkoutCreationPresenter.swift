//
//  WorkoutCreationPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 23.01.2025.
//

import UIKit

protocol WorkoutCreationPresentationLogic {
    func presentCreateWorkout(response: WorkoutCreationModels.CreateWorkout.Response)
    func presentAddExercise(response: WorkoutCreationModels.AddExercise.Response)
    func presentDeleteExercise(response: WorkoutCreationModels.DeleteExercise.Response)
    func presentUpdateExercise(response: WorkoutCreationModels.UpdateExercise.Response)
}

final class WorkoutCreationPresenter: WorkoutCreationPresentationLogic {
    weak var viewController: WorkoutCreationDisplayLogic?
    
    // MARK: - Create Workout
    func presentCreateWorkout(response: WorkoutCreationModels.CreateWorkout.Response) {
        let viewModel = WorkoutCreationModels.CreateWorkout.ViewModel(
            success: response.success,
            errorMessage: response.errorMessage
        )
        viewController?.displayCreateWorkout(viewModel: viewModel)
    }
    
    // MARK: - Add Exercise
    func presentAddExercise(response: WorkoutCreationModels.AddExercise.Response) {
        let viewModel = WorkoutCreationModels.AddExercise.ViewModel(exercises: response.exercises)
        viewController?.displayAddExercise(viewModel: viewModel)
    }
    
    // MARK: - Delete Exercise
    func presentDeleteExercise(response: WorkoutCreationModels.DeleteExercise.Response) {
        let viewModel = WorkoutCreationModels.DeleteExercise.ViewModel(exercises: response.exercises)
        viewController?.displayDeleteExercise(viewModel: viewModel)
    }
    
    // MARK: - Update Exercise
    func presentUpdateExercise(response: WorkoutCreationModels.UpdateExercise.Response) {
        let viewModel = WorkoutCreationModels.UpdateExercise.ViewModel(exercises: response.exercises)
        viewController?.displayUpdateExercise(viewModel: viewModel)
    }
}
