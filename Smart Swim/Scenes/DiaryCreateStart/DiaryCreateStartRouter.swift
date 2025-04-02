//
//  DiaryCreateStartRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.03.2025.
//

import Foundation

protocol DiaryCreateStartRoutingLogic {
    func routeToDiary()
}

protocol DiaryCreateStartDataPassing {
    var dataStore: DiaryCreateStartDataStore? { get }
}

final class DiaryCreateStartRouter: NSObject, DiaryCreateStartRoutingLogic, DiaryCreateStartDataPassing {
    weak var viewController: DiaryCreateStartViewController?
    var dataStore: DiaryCreateStartDataStore?
    
    // MARK: - Routing
    func routeToDiary() {
        viewController?.dismiss(animated: true)
    }
}
