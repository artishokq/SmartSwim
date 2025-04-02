//
//  InfoModels.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 02.04.2025.
//

import Foundation

struct PoolLocation {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}

enum InfoModels {
    enum GetPools {
        struct Request {}
        
        struct Response {
            let pools: [PoolLocation]
            let userLocation: (latitude: Double, longitude: Double)
        }
        
        struct ViewModel {
            let pools: [PoolLocationViewModel]
            let userLocation: (latitude: Double, longitude: Double)
        }
        
        struct PoolLocationViewModel {
            let id: String
            let name: String
            let address: String
            let coordinate: (latitude: Double, longitude: Double)
        }
    }
}
