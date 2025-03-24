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
