//
//  WorkoutEditionRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 28.02.2025.
//

import UIKit

protocol WorkoutEditionRoutingLogic {
    func routeToWorkoutList()
}

protocol WorkoutEditionDataPassing {
    var dataStore: WorkoutEditionDataStore? { get }
}

final class WorkoutEditionRouter: NSObject, WorkoutEditionRoutingLogic, WorkoutEditionDataPassing {
    weak var viewController: WorkoutEditionViewController?
    var dataStore: WorkoutEditionDataStore?
    
    func routeToWorkoutList() {
        viewController?.dismiss(animated: true)
    }
}
