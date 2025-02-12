//
//  WorkoutRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol WorkoutRoutingLogic {
    func routeToWorkoutCreation()
    func routeToInfo()
}

protocol WorkoutDataPassing {
    var dataStore: WorkoutDataStore? { get }
}

final class WorkoutRouter: NSObject, WorkoutRoutingLogic, WorkoutDataPassing {
    weak var viewController: WorkoutViewController?
    var dataStore: WorkoutDataStore?
    
    func routeToWorkoutCreation() {
        let workoutCreationVC = WorkoutCreationViewController()
        let interactor = WorkoutCreationInteractor()
        let presenter = WorkoutCreationPresenter()
        let router = WorkoutCreationRouter()
        
        workoutCreationVC.interactor = interactor
        workoutCreationVC.router = router
        interactor.presenter = presenter
        presenter.viewController = workoutCreationVC
        router.viewController = workoutCreationVC
        
        let navigationController = UINavigationController(rootViewController: workoutCreationVC)
        viewController?.present(navigationController, animated: true)
    }
    
    func routeToInfo() {
        let infoVC = InfoViewController()
        let navigationController = UINavigationController(rootViewController: infoVC)
        viewController?.present(navigationController, animated: true)
    }
}
