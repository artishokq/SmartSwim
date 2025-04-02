//
//  DiaryRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import UIKit
import CoreData

protocol DiaryRoutingLogic {
    func routeToStartDetail(startID: NSManagedObjectID)
    func routeToWorkoutSessionDetail(sessionID: UUID)
    func routeToCreateStart()
}

protocol DiaryDataPassing {
    var dataStore: DiaryDataStore? { get }
}

final class DiaryRouter: NSObject, DiaryRoutingLogic, DiaryDataPassing {
    weak var viewController: DiaryViewController?
    var dataStore: DiaryDataStore?
    
    // MARK: - Route to Start Detail
    func routeToStartDetail(startID: NSManagedObjectID) {
        let startDetailVC = DiaryStartDetailViewController()
        let interactor = DiaryStartDetailInteractor()
        let presenter = DiaryStartDetailPresenter()
        let router = DiaryStartDetailRouter()
        
        startDetailVC.interactor = interactor
        startDetailVC.router = router
        interactor.presenter = presenter
        presenter.viewController = startDetailVC
        router.viewController = startDetailVC
        router.dataStore = interactor
        
        interactor.startID = startID
        startDetailVC.startID = startID
        
        viewController?.navigationController?.pushViewController(startDetailVC, animated: true)
    }
    
    // MARK: - Route to Create Start
    func routeToCreateStart() {
        let createStartVC = DiaryCreateStartViewController()
        let interactor = DiaryCreateStartInteractor()
        let presenter = DiaryCreateStartPresenter()
        let router = DiaryCreateStartRouter()
        
        createStartVC.interactor = interactor
        createStartVC.router = router
        interactor.presenter = presenter
        presenter.viewController = createStartVC
        router.viewController = createStartVC
        
        let navigationController = UINavigationController(rootViewController: createStartVC)
        viewController?.present(navigationController, animated: true)
    }
    
    // MARK: - Route to Workout Detail
    func routeToWorkoutSessionDetail(sessionID: UUID) {
        let detailVC = WorkoutSessionDetailViewController()
        let interactor = WorkoutSessionDetailInteractor()
        let presenter = WorkoutSessionDetailPresenter()
        let router = WorkoutSessionDetailRouter()
        
        detailVC.interactor = interactor
        detailVC.router = router
        interactor.presenter = presenter
        presenter.viewController = detailVC
        router.viewController = detailVC
        router.dataStore = interactor
        
        interactor.sessionID = sessionID
        detailVC.sessionID = sessionID
        
        viewController?.navigationController?.pushViewController(detailVC, animated: true)
    }
}
