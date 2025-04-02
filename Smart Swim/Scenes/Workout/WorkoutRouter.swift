//
//  WorkoutRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol WorkoutRoutingLogic {
    func routeToWorkoutCreation()
    func routeToWorkoutEdition(index: Int)
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
    
    func routeToWorkoutEdition(index: Int) {
        let workoutEditionVC = WorkoutEditionViewController()
        let interactor = WorkoutEditionInteractor()
        let presenter = WorkoutEditionPresenter()
        let router = WorkoutEditionRouter()
        
        workoutEditionVC.interactor = interactor
        workoutEditionVC.router = router
        interactor.presenter = presenter
        presenter.viewController = workoutEditionVC
        router.viewController = workoutEditionVC
        router.dataStore = interactor
        
        // Передаем индекс тренировки в dataStore
        interactor.workoutIndex = index
        
        // Если есть доступ к тренировкам в dataStore, то передаем их
        if let workouts = dataStore?.workouts {
            interactor.workouts = workouts
        }
        
        let navigationController = UINavigationController(rootViewController: workoutEditionVC)
        viewController?.present(navigationController, animated: true)
    }
    
    func routeToInfo() {
        let infoVC = InfoViewController()
        
        let interactor = InfoInteractor()
        let presenter = InfoPresenter()
        let router = InfoRouter()
        
        infoVC.interactor = interactor
        infoVC.router = router
        interactor.presenter = presenter
        presenter.viewController = infoVC
        router.viewController = infoVC
        
        viewController?.navigationController?.pushViewController(infoVC, animated: true)
    }
}
