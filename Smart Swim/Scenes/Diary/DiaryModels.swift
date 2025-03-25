//
//  DiaryModels.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import UIKit
import CoreData

enum DiaryModels {
    enum FetchStarts {
        struct Request {
            
        }
        
        struct Response {
            struct StartData {
                let id: NSManagedObjectID
                let date: Date
                let totalMeters: Int16
                let swimmingStyle: Int16
                let totalTime: Double
            }
            
            let starts: [StartData]
        }
        
        struct ViewModel {
            struct DisplayedStart {
                let id: NSManagedObjectID
                let dateString: String
                let metersString: String
                let styleString: String
                let timeString: String
            }
            
            let starts: [DisplayedStart]
        }
    }
    
    enum DeleteStart {
        struct Request {
            let id: NSManagedObjectID
            let index: Int
        }
        
        struct Response {
            let index: Int
        }
        
        struct ViewModel {
            let index: Int
        }
    }
    
    enum ShowStartDetail {
        struct Request {
            let startID: NSManagedObjectID
        }
        
        struct Response {
            let startID: NSManagedObjectID
        }
        
        struct ViewModel {
            let startID: NSManagedObjectID
        }
    }
    
    enum CreateStart {
        struct Request {
            
        }
        
        struct Response {
            
        }
        
        struct ViewModel {
            
        }
    }
    
    enum FetchWorkoutSessions {
        struct Request {
            
        }
        
        struct Response {
            struct WorkoutSessionData {
                let id: UUID
                let date: Date
                let totalMeters: Int
                let totalTime: Double
                let poolSize: Int16
                let workoutName: String
                
                struct ExerciseData {
                    let orderIndex: Int
                    let description: String?
                    let style: Int16
                    let type: Int16
                    let meters: Int16
                    let repetitions: Int16
                    let hasInterval: Bool
                    let intervalMinutes: Int16
                    let intervalSeconds: Int16
                    
                    var formattedString: String {
                        var result = "\(orderIndex + 1). "
                        
                        if let typeText = getTypeDescription(ExerciseType(rawValue: type) ?? .main) {
                            result += typeText + " "
                        }
                        
                        if repetitions > 1 {
                            result += "\(repetitions)x\(meters)м "
                        } else {
                            result += "\(meters)м "
                        }
                        
                        let style = SwimStyle(rawValue: style) ?? .freestyle
                        result += getStyleDescription(style)
                        
                        if hasInterval && (intervalMinutes > 0 || intervalSeconds > 0) {
                            var intervalParts: [String] = ["  Режим"]
                            if intervalMinutes > 0 {
                                intervalParts.append(" \(intervalMinutes) мин")
                            }
                            if intervalSeconds > 0 {
                                intervalParts.append(" \(intervalSeconds) сек")
                            }
                            result += "\n  " + intervalParts.joined(separator: " ")
                        }
                        
                        if let description = description, !description.isEmpty {
                            result += "\n  " + description
                        }
                        
                        return result
                    }
                    
                    private func getStyleDescription(_ style: SwimStyle) -> String {
                        switch style {
                        case .freestyle: return "кроль"
                        case .breaststroke: return "брасс"
                        case .backstroke: return "на спине"
                        case .butterfly: return "баттерфляй"
                        case .medley: return "комплекс"
                        case .any: return "любой стиль"
                        }
                    }
                    
                    private func getTypeDescription(_ type: ExerciseType) -> String? {
                        switch type {
                        case .warmup: return "Разминка"
                        case .cooldown: return "Заминка"
                        case .main: return nil
                        }
                    }
                }
                
                let exercises: [ExerciseData]
            }
            
            let workoutSessions: [WorkoutSessionData]
        }
        
        struct ViewModel {
            struct DisplayedWorkoutSession {
                let id: UUID
                let dateString: String
                let totalMeters: String
                let totalTimeString: String
                let rawTotalSeconds: Double
                
                let exercises: [String]
            }
            
            let workoutSessions: [DisplayedWorkoutSession]
        }
    }
    
    enum DeleteWorkoutSession {
        struct Request {
            let id: UUID
            let index: Int
        }
        
        struct Response {
            let index: Int
        }
        
        struct ViewModel {
            let index: Int
        }
    }
    
    enum ShowWorkoutSessionDetail {
        struct Request {
            let sessionID: UUID
        }
        
        struct Response {
            let sessionID: UUID
        }
        
        struct ViewModel {
            let sessionID: UUID
        }
    }
}
