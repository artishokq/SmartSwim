//
//  SwimWorkoutModels.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 22.03.2025.
//

import Foundation

enum SwimWorkoutModels {
    struct SwimWorkout: Identifiable, Equatable, Codable {
        let id: String
        let name: String
        let poolSize: Int
        let exercises: [SwimExercise]
        
        var totalMeters: Int {
            exercises.reduce(0) { $0 + ($1.meters * Int($1.repetitions)) }
        }
        
        static func == (lhs: SwimWorkout, rhs: SwimWorkout) -> Bool {
            return lhs.id == rhs.id
        }
        
        static func fromDictionary(_ dict: [String: Any]) -> SwimWorkout? {
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let poolSize = dict["poolSize"] as? Int,
                  let exercisesData = dict["exercises"] as? [[String: Any]] else {
                return nil
            }
            
            let exercises = exercisesData.compactMap { SwimExercise.fromDictionary($0) }
            
            return SwimWorkout(
                id: id,
                name: name,
                poolSize: poolSize,
                exercises: exercises
            )
        }
    }
    
    struct SwimExercise: Identifiable, Equatable, Codable {
        let id: String
        let description: String?
        let style: Int
        let type: Int
        let hasInterval: Bool
        let intervalMinutes: Int
        let intervalSeconds: Int
        let meters: Int
        let orderIndex: Int
        let repetitions: Int
        
        func getStyleName() -> String {
            switch style {
            case 0:
                return "Кроль"
            case 1:
                return "На спине"
            case 2:
                return "Брасс"
            case 3:
                return "Батт"
            case 4:
                return "К/П"
            default:
                return "Любой стиль"
            }
        }
        
        func getTypeName() -> String {
            switch type {
            case 0:
                return "Основная"
            case 1:
                return "Разминка"
            case 2:
                return "Заминка"
            default:
                return "Основная"
            }
        }
        
        func getFormattedInterval() -> String {
            if !hasInterval {
                return ""
            }
            
            if intervalMinutes > 0 {
                return "режим \(intervalMinutes) мин \(intervalSeconds > 0 ? "\(intervalSeconds) сек" : "")"
            } else if intervalSeconds > 0 {
                return "режим \(intervalSeconds) сек"
            }
            return ""
        }
        
        static func == (lhs: SwimExercise, rhs: SwimExercise) -> Bool {
            return lhs.id == rhs.id
        }
        
        static func fromDictionary(_ dict: [String: Any]) -> SwimExercise? {
            guard let id = dict["id"] as? String,
                  let style = dict["style"] as? Int,
                  let type = dict["type"] as? Int,
                  let hasInterval = dict["hasInterval"] as? Bool,
                  let meters = dict["meters"] as? Int,
                  let orderIndex = dict["orderIndex"] as? Int,
                  let repetitions = dict["repetitions"] as? Int else {
                return nil
            }
            
            return SwimExercise(
                id: id,
                description: dict["description"] as? String,
                style: style,
                type: type,
                hasInterval: hasInterval,
                intervalMinutes: dict["intervalMinutes"] as? Int ?? 0,
                intervalSeconds: dict["intervalSeconds"] as? Int ?? 0,
                meters: meters,
                orderIndex: orderIndex,
                repetitions: repetitions
            )
        }
    }
}
