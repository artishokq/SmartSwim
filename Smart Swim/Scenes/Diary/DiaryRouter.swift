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
        startDetailVC.startID = startID
        viewController?.navigationController?.pushViewController(startDetailVC, animated: true)
    }
    
    // MARK: - Route to Create Start
    func routeToCreateStart() {
        let createStartVC = DiaryCreateStartViewController()
        let navigationController = UINavigationController(rootViewController: createStartVC)
        viewController?.present(navigationController, animated: true)
    }
}
