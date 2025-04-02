//
//  InfoInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 02.04.2025.
//

import Foundation
import YandexMapsMobile

protocol InfoBusinessLogic {
    func getPools(request: InfoModels.GetPools.Request)
}

final class InfoInteractor: InfoBusinessLogic {
    var presenter: InfoPresentationLogic?
    private let poolSearchWorker = PoolSearchWorker()
    private let locationWorker = LocationWorker()
    
    func getPools(request: InfoModels.GetPools.Request) {
        // Получаем текущее местоположение пользователя
        locationWorker.getCurrentLocation { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let location):
                // Создаем видимый регион для поиска
                let visibleRegion = self.createVisibleRegion(around: location)
                
                // Ищем бассейны в данном регионе
                self.poolSearchWorker.searchPools(near: location, in: visibleRegion) { poolsResult in
                    switch poolsResult {
                    case .success(let pools):
                        let response = InfoModels.GetPools.Response(
                            pools: pools,
                            userLocation: (location.latitude, location.longitude)
                        )
                        self.presenter?.presentPools(response: response)
                        
                    case .failure(let error):
                        self.presenter?.presentError(message: "Не удалось найти бассейны: \(error.localizedDescription)")
                    }
                }
                
            case .failure(let error):
                // Используем дефолтное местоположение в случае ошибки
                let defaultLocation = self.locationWorker.getDefaultLocation()
                let visibleRegion = self.createVisibleRegion(around: defaultLocation)
                
                print("Ошибка определения местоположения: \(error.localizedDescription). Используем стандартное местоположение.")
                
                // Ищем бассейны вокруг дефолтного местоположения
                self.poolSearchWorker.searchPools(near: defaultLocation, in: visibleRegion) { poolsResult in
                    switch poolsResult {
                    case .success(let pools):
                        let response = InfoModels.GetPools.Response(
                            pools: pools,
                            userLocation: (defaultLocation.latitude, defaultLocation.longitude)
                        )
                        self.presenter?.presentPools(response: response)
                        
                    case .failure(let searchError):
                        self.presenter?.presentError(message: "Не удалось найти бассейны: \(searchError.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // Создаем видимый регион вокруг указанного местоположения
    private func createVisibleRegion(around location: Location) -> YMKVisibleRegion {
        // Размер региона (примерно 10км в каждую сторону)
        let delta: Double = 0.1
        
        // Создаем угловые точки региона
        let topLeft = YMKPoint(
            latitude: location.latitude + delta,
            longitude: location.longitude - delta
        )
        
        let topRight = YMKPoint(
            latitude: location.latitude + delta,
            longitude: location.longitude + delta
        )
        
        let bottomLeft = YMKPoint(
            latitude: location.latitude - delta,
            longitude: location.longitude - delta
        )
        
        let bottomRight = YMKPoint(
            latitude: location.latitude - delta,
            longitude: location.longitude + delta
        )
        
        // Создаем видимый регион
        return YMKVisibleRegion(
            topLeft: topLeft,
            topRight: topRight,
            bottomLeft: bottomLeft,
            bottomRight: bottomRight
        )
    }
}
