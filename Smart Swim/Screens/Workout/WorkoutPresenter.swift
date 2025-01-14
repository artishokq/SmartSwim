//
//  WorkoutPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol WorkoutPresentationLogic {
    func presentCreateWorkout(response: Workout.Create.Response)
    func presentInfo(response: Workout.Info.Response)
}

final class WorkoutPresenter: WorkoutPresentationLogic {
    weak var viewController: WorkoutDisplayLogic?
    
    func presentCreateWorkout(response: Workout.Create.Response) {
        let viewModel = Workout.Create.ViewModel()
        viewController?.displayCreateWorkout(viewModel: viewModel)
    }
    
    func presentInfo(response: Workout.Info.Response) {
        let viewModel = Workout.Info.ViewModel()
        viewController?.displayInfo(viewModel: viewModel)
    }
}
