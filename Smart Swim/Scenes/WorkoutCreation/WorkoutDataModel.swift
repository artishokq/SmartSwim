//
//  WorkoutDataModel.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit

enum PoolSize: Int16, Codable {
    case poolSize25 = 25
    case poolSize50 = 50
}

enum ExerciseType: Int16, Codable {
    case warmup = 0
    case main = 1
    case cooldown = 2
}

enum SwimStyle: Int16, Codable {
    case freestyle = 0
    case breaststroke = 1
    case backstroke = 2
    case butterfly = 3
    case medley = 4
    case any = 5
}

struct Exercise: Codable {
    var type: ExerciseType
    var meters: Int16
    var repetitions: Int16
    var hasInterval: Bool
    var intervalMinutes: Int16?
    var intervalSeconds: Int16?
    var style: SwimStyle
    var description: String
}

struct Workout: Codable {
    var name: String
    var poolSize: PoolSize
    var exercises: [Exercise]
}
