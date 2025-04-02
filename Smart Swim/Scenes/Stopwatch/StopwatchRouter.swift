//
//  StopwatchRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.02.2025.
//

import UIKit

protocol StopwatchRoutingLogic {
    func routeToBack()
}

protocol StopwatchDataPassing {
    var dataStore: StopwatchDataStore? { get set }
}

final class StopwatchRouter: NSObject, StopwatchRoutingLogic, StopwatchDataPassing {
    weak var viewController: StopwatchViewController?
    var dataStore: StopwatchDataStore?
    
    func routeToBack() {
        viewController?.navigationController?.popViewController(animated: true)
    }
}
