//
//  TransferWorkoutModels.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 24.03.2025.
//

import Foundation

// Модели для передачи данных между Apple Watch и iPhone
struct TransferWorkoutModels {
    
    // Данные о выполненном отрезке для передачи
    struct TransferLapInfo: Codable, Equatable {
        let timestamp: Date
        let lapNumber: Int
        let exerciseId: String
        let distance: Int
        let lapTime: TimeInterval
        let heartRate: Double
        let strokes: Int
        
        // Преобразование в словарь для WatchConnectivity
        func toDictionary() -> [String: Any] {
            return [
                "timestamp": timestamp,
                "lapNumber": lapNumber,
                "exerciseId": exerciseId,
                "distance": distance,
                "lapTime": lapTime,
                "heartRate": heartRate,
                "strokes": strokes
            ]
        }
        
        // Создание из словаря
        static func fromDictionary(_ dict: [String: Any]) -> TransferLapInfo? {
            guard let timestamp = dict["timestamp"] as? Date,
                  let lapNumber = dict["lapNumber"] as? Int,
                  let exerciseId = dict["exerciseId"] as? String,
                  let distance = dict["distance"] as? Int,
                  let lapTime = dict["lapTime"] as? TimeInterval,
                  let heartRate = dict["heartRate"] as? Double,
                  let strokes = dict["strokes"] as? Int else {
                return nil
            }
            
            return TransferLapInfo(
                timestamp: timestamp,
                lapNumber: lapNumber,
                exerciseId: exerciseId,
                distance: distance,
                lapTime: lapTime,
                heartRate: heartRate,
                strokes: strokes
            )
        }
        
        // Конструктор с отдельными параметрами вместо зависимости от SwimWorkoutModels
        static func create(
            timestamp: Date,
            lapNumber: Int,
            exerciseId: String,
            distance: Int,
            lapTime: TimeInterval,
            heartRate: Double,
            strokes: Int
        ) -> TransferLapInfo {
            return TransferLapInfo(
                timestamp: timestamp,
                lapNumber: lapNumber,
                exerciseId: exerciseId,
                distance: distance,
                lapTime: lapTime,
                heartRate: heartRate,
                strokes: strokes
            )
        }
    }
    
    // Данные о выполненном упражнении для передачи
    struct TransferExerciseInfo: Codable, Equatable {
        let exerciseId: String
        let startTime: Date
        let endTime: Date
        let laps: [TransferLapInfo]
        
        // Дополнительные поля для сохранения данных об упражнении
        let orderIndex: Int
        let description: String?
        let style: Int
        let type: Int
        let hasInterval: Bool
        let intervalMinutes: Int
        let intervalSeconds: Int
        let meters: Int
        let repetitions: Int
        
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
        
        // Преобразование в словарь для WatchConnectivity
        func toDictionary() -> [String: Any] {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            guard let data = try? encoder.encode(self),
                  let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return [:]
            }
            
            return dictionary
        }
        
        // Создание из словаря
        static func fromDictionary(_ dict: [String: Any]) -> TransferExerciseInfo? {
            guard let data = try? JSONSerialization.data(withJSONObject: dict) else {
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                return try decoder.decode(TransferExerciseInfo.self, from: data)
            } catch {
                print("Ошибка декодирования TransferExerciseInfo: \(error)")
                return nil
            }
        }
        
        
        // Конструктор с отдельными параметрами вместо зависимости от SwimWorkoutModels
        static func create(
            exerciseId: String,
            orderIndex: Int,
            description: String?,
            style: Int,
            type: Int,
            hasInterval: Bool,
            intervalMinutes: Int,
            intervalSeconds: Int,
            meters: Int,
            repetitions: Int,
            startTime: Date,
            endTime: Date,
            laps: [TransferLapInfo]
        ) -> TransferExerciseInfo {
            return TransferExerciseInfo(
                exerciseId: exerciseId,
                startTime: startTime,
                endTime: endTime,
                laps: laps,
                orderIndex: orderIndex,
                description: description,
                style: style,
                type: type,
                hasInterval: hasInterval,
                intervalMinutes: intervalMinutes,
                intervalSeconds: intervalSeconds,
                meters: meters,
                repetitions: repetitions
            )
        }
    }
    
    // Данные о выполненной тренировке для передачи
    struct TransferWorkoutInfo: Codable, Equatable {
        let workoutId: String
        let workoutName: String
        let poolSize: Int
        let startTime: Date
        let endTime: Date
        let totalCalories: Double
        let exercises: [TransferExerciseInfo]
        
        var totalTime: TimeInterval {
            return endTime.timeIntervalSince(startTime)
        }
        
        // Преобразование в словарь для WatchConnectivity
        func toDictionary() -> [String: Any] {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            guard let data = try? encoder.encode(self),
                  let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return [:]
            }
            
            return dictionary
        }
        
        // Создание из словаря
        static func fromDictionary(_ dict: [String: Any]) -> TransferWorkoutInfo? {
            guard let data = try? JSONSerialization.data(withJSONObject: dict) else {
                return nil
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                return try decoder.decode(TransferWorkoutInfo.self, from: data)
            } catch {
                print("Ошибка декодирования TransferWorkoutInfo: \(error)")
                return nil
            }
        }
        
        // Конструктор с отдельными параметрами
        static func create(
            workoutId: String,
            workoutName: String,
            poolSize: Int,
            startTime: Date,
            endTime: Date,
            totalCalories: Double,
            exercises: [TransferExerciseInfo]
        ) -> TransferWorkoutInfo {
            return TransferWorkoutInfo(
                workoutId: workoutId,
                workoutName: workoutName,
                poolSize: poolSize,
                startTime: startTime,
                endTime: endTime,
                totalCalories: totalCalories,
                exercises: exercises
            )
        }
    }
}
