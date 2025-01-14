//
//  WorkoutRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol WorkoutRoutingLogic {
    func routeToCreateWorkout()
    func routeToInfo()
}

protocol WorkoutDataPassing {
    var dataStore: WorkoutDataStore? { get }
}

final class WorkoutRouter: NSObject, WorkoutRoutingLogic, WorkoutDataPassing {
    weak var viewController: WorkoutViewController?
    var dataStore: WorkoutDataStore?
    
    func routeToCreateWorkout() {
        let createWorkoutVC = CreateWorkoutViewController()
        let navigationController = UINavigationController(rootViewController: createWorkoutVC)
        viewController?.present(navigationController, animated: true)
    }
    
    func routeToInfo() {
        let infoVC = InfoViewController()
        let navigationController = UINavigationController(rootViewController: infoVC)
        viewController?.present(navigationController, animated: true)
    }
}
