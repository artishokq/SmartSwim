//
//  StartPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.02.2025.
//

import UIKit

protocol StartPresentationLogic {
    func presentContinue(response: StartModels.Continue.Response)
}

final class StartPresenter: StartPresentationLogic {
    weak var viewController: StartDisplayLogic?
    
    func presentContinue(response: StartModels.Continue.Response) {
        let viewModel = StartModels.Continue.ViewModel()
        viewController?.displayContinue(viewModel: viewModel)
    }
}
