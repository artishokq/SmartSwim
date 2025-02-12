//
//  StartRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.02.2025.
//

import UIKit

protocol StartRoutingLogic {
    func routeToStopwatch()
}

protocol StartDataPassing {
    var dataStore: StartDataStore? { get set }
}

final class StartRouter: NSObject, StartRoutingLogic, StartDataPassing {
    weak var viewController: StartViewController?
    var dataStore: StartDataStore?
    
    func routeToStopwatch() {
        let stopwatchVC = StopwatchViewController()
        let interactor = StopwatchInteractor()
        let presenter = StopwatchPresenter()
        let router = StopwatchRouter()
        
        stopwatchVC.interactor = interactor
        stopwatchVC.router = router
        interactor.presenter = presenter
        presenter.viewController = stopwatchVC
        router.viewController = stopwatchVC
        router.dataStore = interactor
        
        // Передаем данные из StartDataStore (dataStore) в StopwatchInteractor
        if let startDataStore = dataStore {
            interactor.totalMeters = startDataStore.totalMeters
            interactor.poolSize = startDataStore.poolSize
            interactor.swimmingStyle = startDataStore.swimmingStyle
        }
        
        viewController?.navigationController?.pushViewController(stopwatchVC, animated: true)
    }
}
