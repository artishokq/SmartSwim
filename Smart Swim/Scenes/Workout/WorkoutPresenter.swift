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
}

final class WorkoutPresenter: WorkoutPresentationLogic {
    weak var viewController: WorkoutDisplayLogic?
    
    func presentWorkoutCreation(response: WorkoutModels.Create.Response) {
        let viewModel = WorkoutModels.Create.ViewModel()
        viewController?.displayWorkoutCreation(viewModel: viewModel)
    }
    
    func presentInfo(response: WorkoutModels.Info.Response) {
        let viewModel = WorkoutModels.Info.ViewModel()
        viewController?.displayInfo(viewModel: viewModel)
    }
}
