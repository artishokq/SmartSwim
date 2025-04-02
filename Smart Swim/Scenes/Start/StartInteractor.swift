//
//  StartInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.02.2025.
//

import UIKit

protocol StartBusinessLogic {
    func continueAction(request: StartModels.Continue.Request)
}

protocol StartDataStore {
    var totalMeters: Int? { get set }
    var poolSize: Int? { get set }
    var swimmingStyle: String? { get set }
}

final class StartInteractor: StartBusinessLogic, StartDataStore {
    var presenter: StartPresentationLogic?
    
    var totalMeters: Int?
    var poolSize: Int?
    var swimmingStyle: String?
    
    func continueAction(request: StartModels.Continue.Request) {
        self.totalMeters = request.totalMeters
        self.poolSize = request.poolSize
        self.swimmingStyle = request.swimmingStyle
        
        let response = StartModels.Continue.Response()
        presenter?.presentContinue(response: response)
    }
}
