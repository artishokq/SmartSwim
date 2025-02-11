//
//  StartRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.02.2025.
//

import UIKit

protocol StartRoutingLogic {
    
}

protocol StartDataPassing {

}

final class StartRouter: NSObject, StartRoutingLogic, StartDataPassing {
    weak var viewController: StartViewController?
}
