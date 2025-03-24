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
                return "Брасс"
            case 2:
                return "На спине"
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
                return "Разминка"
            case 1:
                return "Основная"
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
                return "Режим \(intervalMinutes) мин \(intervalSeconds > 0 ? "\(intervalSeconds) сек" : "")"
            } else if intervalSeconds > 0 {
                return "Режим \(intervalSeconds) сек"
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
        
        var displayName: String {
            if repetitions > 1 {
                return "\(repetitions)×\(meters)м"
            } else {
                return "\(meters)м"
            }
        }
        
        // Получение полного интервала в секундах
        var intervalInSeconds: Int {
            return (intervalMinutes * 60) + intervalSeconds
        }
    }
    
    // MARK: - Модели для активной тренировки
    enum WorkoutSessionState {
        case notStarted
        case previewingExercise
        case exerciseActive
        case completed
    }
    
    // Данные активного упражнения
    struct ActiveExerciseData {
        let exerciseId: String
        let index: Int
        let totalExercises: Int
        let exerciseRef: SwimExercise
        
        // Данные во время тренировки
        var currentRepetition: Int = 1
        var totalSessionTime: TimeInterval = 0
        var currentRepetitionTime: TimeInterval = 0
        var heartRate: Double = 0
        var strokeCount: Int = 0
        
        // Форматированное время
        var formattedTotalTime: String {
            return formatTimeInterval(totalSessionTime)
        }
        
        var formattedRepetitionTime: String {
            return formatTimeInterval(currentRepetitionTime)
        }
        
        var formattedInterval: String {
            let minutes = exerciseRef.intervalMinutes
            let seconds = exerciseRef.intervalSeconds
            return String(format: "%02d:%02d", minutes, seconds)
        }
        
        // Вспомогательные методы
        private func formatTimeInterval(_ interval: TimeInterval) -> String {
            let hours = Int(interval) / 3600
            let minutes = Int(interval) / 60 % 60
            let seconds = Int(interval) % 60
            
            // Всегда отображаем в формате часы:минуты:секунды
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        
        // Инициализатор
        init(from exercise: SwimExercise, index: Int, totalExercises: Int) {
            self.exerciseId = exercise.id
            self.index = index
            self.totalExercises = totalExercises
            self.exerciseRef = exercise
        }
    }
    
    // Данные о выполненном отрезке
    struct LapData {
        let timestamp: Date
        let lapNumber: Int
        let exerciseId: String
        let distance: Int
        let lapTime: TimeInterval
        let heartRate: Double
        let strokes: Int
    }
    
    // Данные о выполненном упражнении
    struct CompletedExerciseData {
        let exerciseId: String
        let startTime: Date
        let endTime: Date
        let laps: [LapData]
        
        var totalTime: TimeInterval {
            return endTime.timeIntervalSince(startTime)
        }
        
        var averageHeartRate: Double {
            guard !laps.isEmpty else { return 0 }
            return laps.reduce(0) { $0 + $1.heartRate } / Double(laps.count)
        }
        
        var totalStrokes: Int {
            return laps.reduce(0) { $0 + $1.strokes }
        }
    }
    
    // Данные о выполненной тренировке
    struct CompletedWorkoutData {
        let workoutId: String
        let startTime: Date
        let endTime: Date
        let exercises: [CompletedExerciseData]
        
        var totalTime: TimeInterval {
            return endTime.timeIntervalSince(startTime)
        }
    }
}
