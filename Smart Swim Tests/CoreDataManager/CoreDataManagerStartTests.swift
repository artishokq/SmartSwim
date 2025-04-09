//
//  CoreDataManagerStartTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
@testable import Smart_Swim

final class CompletedExerciseDataTests: XCTestCase {
    func testTotalTimeCalculation() {
        // Arrange
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(600)
        let exerciseData = CompletedExerciseData(
            exerciseId: "ex-1",
            orderIndex: 0,
            description: "Test Exercise",
            style: 0,
            type: 1,
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0,
            meters: 100,
            repetitions: 1,
            startTime: startTime,
            endTime: endTime,
            laps: [],
            heartRateReadings: []
        )
        
        // Act
        let totalTime = exerciseData.totalTime
        
        // Assert
        XCTAssertEqual(totalTime, 600, accuracy: 0.01)
    }
    
    func testAverageHeartRateCalculationWithHeartRateReadings() {
        // Arrange
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(600)
        let heartRateReadings: [(value: Double, timestamp: Date)] = [
            (value: 140, timestamp: startTime),
            (value: 150, timestamp: startTime.addingTimeInterval(100)),
            (value: 160, timestamp: startTime.addingTimeInterval(200))
        ]
        
        let exerciseData = CompletedExerciseData(
            exerciseId: "ex-2",
            orderIndex: 1,
            description: "Test Exercise With HR Readings",
            style: 0,
            type: 1,
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0,
            meters: 100,
            repetitions: 1,
            startTime: startTime,
            endTime: endTime,
            laps: [],
            heartRateReadings: heartRateReadings
        )
        
        // Act
        let avgHR = exerciseData.averageHeartRate
        
        // Assert
        let expectedAvg = (140 + 150 + 160) / 3.0
        XCTAssertEqual(avgHR, expectedAvg, accuracy: 0.01)
    }
    
    func testAverageHeartRateCalculationWithLapsFallback() {
        // Arrange
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(600)
        let lap1 = CompletedLapData(lapNumber: 1, distance: 50, lapTime: 60, heartRate: 130, strokes: 20, timestamp: startTime)
        let lap2 = CompletedLapData(lapNumber: 2, distance: 50, lapTime: 65, heartRate: 150, strokes: 22, timestamp: startTime.addingTimeInterval(70))
        let laps = [lap1, lap2]
        
        let exerciseData = CompletedExerciseData(
            exerciseId: "ex-3",
            orderIndex: 2,
            description: "Test Exercise With Laps",
            style: 0,
            type: 1,
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0,
            meters: 100,
            repetitions: 1,
            startTime: startTime,
            endTime: endTime,
            laps: laps,
            heartRateReadings: []
        )
        
        // Act
        let avgHR = exerciseData.averageHeartRate
        
        // Assert
        let expectedAvg = (130 + 150) / 2.0
        XCTAssertEqual(avgHR, expectedAvg, accuracy: 0.01)
    }
    
    func testTotalStrokesCalculation() {
        // Arrange
        let lap1 = CompletedLapData(lapNumber: 1, distance: 50, lapTime: 60, heartRate: 130, strokes: 20, timestamp: Date())
        let lap2 = CompletedLapData(lapNumber: 2, distance: 50, lapTime: 65, heartRate: 150, strokes: 22, timestamp: Date().addingTimeInterval(70))
        let laps = [lap1, lap2]
        
        let exerciseData = CompletedExerciseData(
            exerciseId: "ex-4",
            orderIndex: 3,
            description: "Test Exercise Total Strokes",
            style: 0,
            type: 1,
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0,
            meters: 100,
            repetitions: 1,
            startTime: Date(),
            endTime: Date().addingTimeInterval(600),
            laps: laps,
            heartRateReadings: []
        )
        
        // Act
        let totalStrokes = exerciseData.totalStrokes
        
        // Assert
        let expectedStrokes = 20 + 22
        XCTAssertEqual(totalStrokes, expectedStrokes)
    }
}
