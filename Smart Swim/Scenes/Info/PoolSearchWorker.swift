//
//  PoolSearchWorker.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 02.04.2025.
//

import Foundation
import YandexMapsMobile

protocol PoolSearchWorkerProtocol {
    func searchPools(near location: Location, in region: YMKVisibleRegion, completion: @escaping (Result<[PoolLocation], Error>) -> Void)
}

final class PoolSearchWorker {
    // MARK: - Properties
    private var searchManager: YMKSearchManager
    private var searchSession: YMKSearchSession?
    
    // MARK: - Initialization
    init() {
        searchManager = YMKSearchFactory.instance().createSearchManager(with: .online)
    }
    
    // MARK: - Private Methods
    private func createSearchOptions() -> YMKSearchOptions {
        let options = YMKSearchOptions()
        options.searchTypes = .biz
        options.resultPageSize = 200
        return options
    }
    
    private func handleSearchResponse(
        response: YMKSearchResponse?,
        error: Error?,
        completion: @escaping (Result<[PoolLocation], Error>) -> Void
    ) {
        if let error = error {
            completion(.failure(error))
            return
        }
        
        guard let response = response else {
            completion(.failure(NSError(domain: "PoolSearchError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Нет ответа от поискового сервиса"])))
            return
        }
        
        var pools: [PoolLocation] = []
        for item in response.collection.children {
            guard let geoObject = item.obj,
                  let point = geoObject.geometry.first?.point,
                  let name = geoObject.name else {
                continue
            }
            
            let business = geoObject.metadataContainer.getItemOf(YMKSearchBusinessObjectMetadata.self) as? YMKSearchBusinessObjectMetadata
            
            let pool = PoolLocation(
                id: UUID().uuidString,
                name: name,
                address: business?.address.formattedAddress ?? "Адрес не указан",
                latitude: point.latitude,
                longitude: point.longitude
            )
            
            pools.append(pool)
        }
        completion(.success(pools))
    }
    
    // MARK: - Public Methods
    func searchPools(near location: Location, in region: YMKVisibleRegion, completion: @escaping (Result<[PoolLocation], Error>) -> Void) {
        // Создаем поисковые параметры
        let searchOptions = createSearchOptions()
        let searchGeometry = YMKVisibleRegionUtils.toPolygon(with: region)
        searchSession?.cancel()
        
        // Запускаем сессию поиска бассейнов
        searchSession = searchManager.submit(
            withText: "бассейн",
            geometry: searchGeometry,
            searchOptions: searchOptions,
            responseHandler: { response, error in
                self.handleSearchResponse(response: response, error: error, completion: completion)
            }
        )
    }
}
