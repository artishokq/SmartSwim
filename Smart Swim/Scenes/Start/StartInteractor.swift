//
//  StartInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.02.2025.
//

import UIKit

protocol StartBusinessLogic {
    
}

protocol StartDataStore {

}

final class StartInteractor: StartBusinessLogic, StartDataStore {
    var presenter: StartPresentationLogic?
    
}
