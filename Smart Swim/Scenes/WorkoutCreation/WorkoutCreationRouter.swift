//
//  WorkoutCreationRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 23.01.2025.
//

import UIKit

protocol WorkoutCreationRoutingLogic {
    func routeToWorkoutList()
}

final class WorkoutCreationRouter: WorkoutCreationRoutingLogic {
    weak var viewController: WorkoutCreationViewController?

    func routeToWorkoutList() {
        viewController?.dismiss(animated: true)
    }
}
