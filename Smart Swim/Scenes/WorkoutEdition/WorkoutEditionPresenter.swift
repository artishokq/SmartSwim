//
//  WorkoutEditionPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 28.02.2025.
//

import UIKit

protocol WorkoutEditionPresentationLogic {
    func presentLoadWorkout(response: WorkoutEditionModels.LoadWorkout.Response)
    func presentUpdateWorkout(response: WorkoutEditionModels.UpdateWorkout.Response)
    func presentAddExercise(response: WorkoutEditionModels.AddExercise.Response)
    func presentDeleteExercise(response: WorkoutEditionModels.DeleteExercise.Response)
    func presentUpdateExercise(response: WorkoutEditionModels.UpdateExercise.Response)
}

final class WorkoutEditionPresenter: WorkoutEditionPresentationLogic {
    weak var viewController: WorkoutEditionDisplayLogic?
    
    // MARK: - Load Workout
    func presentLoadWorkout(response: WorkoutEditionModels.LoadWorkout.Response) {
        let viewModel = WorkoutEditionModels.LoadWorkout.ViewModel(
            name: response.name,
            poolSize: response.poolSize,
            exercises: response.exercises
        )
        viewController?.displayLoadWorkout(viewModel: viewModel)
    }
    
    // MARK: - Update Workout
    func presentUpdateWorkout(response: WorkoutEditionModels.UpdateWorkout.Response) {
        let viewModel = WorkoutEditionModels.UpdateWorkout.ViewModel(
            success: response.success,
            errorMessage: response.errorMessage
        )
        viewController?.displayUpdateWorkout(viewModel: viewModel)
    }
    
    // MARK: - Add Exercise
    func presentAddExercise(response: WorkoutEditionModels.AddExercise.Response) {
        let viewModel = WorkoutEditionModels.AddExercise.ViewModel(exercises: response.exercises)
        viewController?.displayAddExercise(viewModel: viewModel)
    }
    
    // MARK: - Delete Exercise
    func presentDeleteExercise(response: WorkoutEditionModels.DeleteExercise.Response) {
        let viewModel = WorkoutEditionModels.DeleteExercise.ViewModel(exercises: response.exercises)
        viewController?.displayDeleteExercise(viewModel: viewModel)
    }
    
    // MARK: - Update Exercise
    func presentUpdateExercise(response: WorkoutEditionModels.UpdateExercise.Response) {
        let viewModel = WorkoutEditionModels.UpdateExercise.ViewModel(exercises: response.exercises)
        viewController?.displayUpdateExercise(viewModel: viewModel)
    }
}
