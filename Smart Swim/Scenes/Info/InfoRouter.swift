//
//  InfoRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 02.04.2025.
//

import UIKit

protocol InfoRoutingLogic {
    func routeToPoolDetails(poolId: String)
    func routeBack()
}

final class InfoRouter: NSObject, InfoRoutingLogic {
    weak var viewController: UIViewController?
    
    func routeToPoolDetails(poolId: String) {

    }
    
    func routeBack() {
        viewController?.navigationController?.popViewController(animated: true)
    }
}
