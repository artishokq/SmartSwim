//
//  WorkoutPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol WorkoutPresentationLogic {
    func presentCreateWorkout(response: WorkoutHomeModels.Create.Response)
    func presentInfo(response: WorkoutHomeModels.Info.Response)
}

final class WorkoutPresenter: WorkoutPresentationLogic {
    weak var viewController: WorkoutDisplayLogic?
    
    func presentCreateWorkout(response: WorkoutHomeModels.Create.Response) {
        let viewModel = WorkoutHomeModels.Create.ViewModel()
        viewController?.displayCreateWorkout(viewModel: viewModel)
    }
    
    func presentInfo(response: WorkoutHomeModels.Info.Response) {
        let viewModel = WorkoutHomeModels.Info.ViewModel()
        viewController?.displayInfo(viewModel: viewModel)
    }
}
