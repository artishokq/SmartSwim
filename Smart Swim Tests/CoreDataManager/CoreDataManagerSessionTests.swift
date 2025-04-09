//
//  CoreDataManagerSessionTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
@testable import Smart_Swim

final class CoreDataManagerSessionTests: XCTestCase {
    var coreDataManager: CoreDataManager!
    
    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager.shared
    }
    
    override func tearDown() {
        let sessions = coreDataManager.fetchAllWorkoutSessions()
        sessions.forEach { coreDataManager.deleteWorkoutSession($0) }
        coreDataManager = nil
        super.tearDown()
    }
    
    func testCreateWorkoutSession() {
        // Arrange
        let date = Date()
        let totalTime: Double = 1800
        let totalCalories: Double = 400
        let poolSize: Int16 = 25
        let workoutOriginalId = "orig-123"
        let workoutName = "Workout Session Test"
        
        let lapData1 = CompletedLapData(lapNumber: 1, distance: 50, lapTime: 60, heartRate: 140, strokes: 20, timestamp: date)
        let lapData2 = CompletedLapData(lapNumber: 2, distance: 50, lapTime: 65, heartRate: 145, strokes: 22, timestamp: date.addingTimeInterval(70))
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
            startTime: date,
            endTime: date.addingTimeInterval(600),
            laps: [lapData1, lapData2],
            heartRateReadings: [(value: 140, timestamp: date), (value: 145, timestamp: date.addingTimeInterval(70))]
        )
        
        // Act
        let session = coreDataManager.createWorkoutSession(
            date: date,
            totalTime: totalTime,
            totalCalories: totalCalories,
            poolSize: poolSize,
            workoutOriginalId: workoutOriginalId,
            workoutName: workoutName,
            exercisesData: [exerciseData]
        )
        
        // Assert
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.workoutName, workoutName)
        XCTAssertEqual(session?.totalTime, totalTime)
        XCTAssertEqual(session?.totalCalories, totalCalories)
        
        let exercises = coreDataManager.fetchExerciseSessions(for: session!)
        XCTAssertEqual(exercises.count, 1)
        
        if let exerciseSession = exercises.first {
            let laps = coreDataManager.fetchLapSessions(for: exerciseSession)
            XCTAssertEqual(laps.count, 2)
        }
    }
    
    func testFetchWorkoutSessionByID() {
        // Arrange
        let date = Date()
        let session = coreDataManager.createWorkoutSession(
            date: date,
            totalTime: 1800,
            totalCalories: 400,
            poolSize: 25,
            workoutOriginalId: "orig-456",
            workoutName: "Session By ID",
            exercisesData: []
        )
        XCTAssertNotNil(session)
        let sessionID = session!.id!
        
        // Act
        let fetchedSession = coreDataManager.fetchWorkoutSession(byID: sessionID)
        
        // Assert
        XCTAssertNotNil(fetchedSession)
        XCTAssertEqual(fetchedSession?.id, sessionID)
    }
    
    func testGetWorkoutSessionsStats() {
        // Arrange
        _ = coreDataManager.createWorkoutSession(
            date: Date(),
            totalTime: 1800,
            totalCalories: 400,
            poolSize: 25,
            workoutOriginalId: "sess-1",
            workoutName: "Session One",
            exercisesData: []
        )
        _ = coreDataManager.createWorkoutSession(
            date: Date(),
            totalTime: 3600,
            totalCalories: 800,
            poolSize: 25,
            workoutOriginalId: "sess-2",
            workoutName: "Session Two",
            exercisesData: []
        )
        
        // Act
        let stats = coreDataManager.getWorkoutSessionsStats()
        
        // Assert
        XCTAssertEqual(stats.count, 2)
        XCTAssertEqual(stats.totalTime, 1800 + 3600, accuracy: 0.1)
        XCTAssertEqual(stats.totalCalories, 400 + 800, accuracy: 0.1)
    }
    
    func testUpdateAndDeleteWorkoutSession() {
        // Arrange
        let session = coreDataManager.createWorkoutSession(
            date: Date(),
            totalTime: 1800,
            totalCalories: 400,
            poolSize: 25,
            workoutOriginalId: "sess-del",
            workoutName: "Session To Delete",
            exercisesData: []
        )
        XCTAssertNotNil(session)
        
        // Act
        coreDataManager.updateWorkoutSessionRecommendation(session!, recommendation: "Updated Recommendation")
        XCTAssertTrue(coreDataManager.workoutSessionHasRecommendation(session!), "Session should have a recommendation")
        
        // Act
        coreDataManager.deleteWorkoutSession(session!)
        let fetchedSessions = coreDataManager.fetchAllWorkoutSessions()
        XCTAssertFalse(fetchedSessions.contains(where: { $0 === session }))
    }
}
