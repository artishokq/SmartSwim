//
//  WorkoutSessionDetailRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 25.03.2025.
//

import UIKit

protocol WorkoutSessionDetailRoutingLogic {

}

protocol WorkoutSessionDetailDataPassing {
    var dataStore: WorkoutSessionDetailDataStore? { get }
}

final class WorkoutSessionDetailRouter: NSObject, WorkoutSessionDetailRoutingLogic, WorkoutSessionDetailDataPassing {
    weak var viewController: WorkoutSessionDetailViewController?
    var dataStore: WorkoutSessionDetailDataStore?
}
