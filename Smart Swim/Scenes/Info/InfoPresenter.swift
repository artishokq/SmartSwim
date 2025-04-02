//
//  InfoPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 02.04.2025.
//

import Foundation

protocol InfoPresentationLogic {
    func presentPools(response: InfoModels.GetPools.Response)
    func presentError(message: String)
}

final class InfoPresenter: InfoPresentationLogic {
    weak var viewController: InfoDisplayLogic?
    
    func presentPools(response: InfoModels.GetPools.Response) {
        let poolViewModels = response.pools.map { pool in
            InfoModels.GetPools.PoolLocationViewModel(
                id: pool.id,
                name: pool.name,
                address: pool.address,
                coordinate: (pool.latitude, pool.longitude)
            )
        }
        
        let viewModel = InfoModels.GetPools.ViewModel(
            pools: poolViewModels,
            userLocation: response.userLocation
        )
        
        viewController?.displayPools(viewModel: viewModel)
    }
    
    func presentError(message: String) {
        viewController?.displayError(message: message)
    }
}
