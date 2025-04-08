//
//  CompletedExerciseData.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 24.03.2025.
//

import Foundation

// Модель отрезка для CoreDataManager
struct CompletedLapData {
    let lapNumber: Int
    let distance: Int
    let lapTime: Double
    let heartRate: Double
    let strokes: Int
    let timestamp: Date
}

// Модель упражнения для CoreDataManager
struct CompletedExerciseData {
    let exerciseId: String
    let orderIndex: Int
    let description: String?
    let style: Int
    let type: Int
    let hasInterval: Bool
    let intervalMinutes: Int
    let intervalSeconds: Int
    let meters: Int
    let repetitions: Int
    let startTime: Date
    let endTime: Date
    let laps: [CompletedLapData]
    let heartRateReadings: [(value: Double, timestamp: Date)]
    
    var totalTime: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }
    
    var averageHeartRate: Double {
        if !heartRateReadings.isEmpty {
            let values = heartRateReadings.map { $0.value }.filter { $0 > 0 }
            return values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)
        }
        
        guard !laps.isEmpty else { return 0 }
        return laps.reduce(0) { $0 + $1.heartRate } / Double(laps.count)
    }
    
    var totalStrokes: Int {
        return laps.reduce(0) { $0 + $1.strokes }
    }
    
    init(exerciseId: String, orderIndex: Int, description: String?, style: Int, type: Int,
         hasInterval: Bool, intervalMinutes: Int, intervalSeconds: Int, meters: Int,
         repetitions: Int, startTime: Date, endTime: Date, laps: [CompletedLapData],
         heartRateReadings: [(value: Double, timestamp: Date)] = []) {
        
        self.exerciseId = exerciseId
        self.orderIndex = orderIndex
        self.description = description
        self.style = style
        self.type = type
        self.hasInterval = hasInterval
        self.intervalMinutes = intervalMinutes
        self.intervalSeconds = intervalSeconds
        self.meters = meters
        self.repetitions = repetitions
        self.startTime = startTime
        self.endTime = endTime
        self.laps = laps
        self.heartRateReadings = heartRateReadings
    }
}
