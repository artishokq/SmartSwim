//
//  WorkoutDataModel.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit

enum PoolSize: Int, Codable {
    case poolSize25 = 25
    case poolSize50 = 50
}

enum ExerciseType: String, Codable {
    case warmup = "warmup"
    case main = "main"
    case cooldown = "cooldown"
}

enum SwimStyle: String, Codable {
    case freestyle = "freestyle"
    case breaststroke = "breaststroke"
    case backstroke = "backstroke"
    case butterfly = "butterfly"
    case medley = "medley"
}

struct Exercise: Codable {
    var type: ExerciseType
    var meters: Int?
    var repetitions: Int?
    var hasInterval: Bool
    var intervalMinutes: Int?
    var intervalSeconds: Int?
    var style: SwimStyle
    var description: String
}

struct Workout: Codable {
    var name: String
    var poolSize: PoolSize
    var exercises: [Exercise]
}
