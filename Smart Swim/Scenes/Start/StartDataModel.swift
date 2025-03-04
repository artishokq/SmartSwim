//
//  StartDataModel.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 04.03.2025.
//

import UIKit

enum PoolSizeData: Int16, Codable {
    case poolSize25 = 25
    case poolSize50 = 50
}

enum SwimStyleData: Int16, Codable {
    case freestyle = 0
    case breaststroke = 1
    case backstroke = 2
    case butterfly = 3
    case medley = 4
}

struct LapData: Codable {
    var lapTime: Double
    var pulse: Int16
    var strokes: Int16
    var lapNumber: Int16
}

struct StartData: Codable {
    var poolSize: PoolSizeData
    var totalMeters: Int16
    var swimmingStyle: SwimStyleData
    var date: Date
    var totalTime: Double
    var laps: [LapData]
}
