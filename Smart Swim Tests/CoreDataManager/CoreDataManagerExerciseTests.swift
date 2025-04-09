//
//  CoreDataManagerExerciseTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
@testable import Smart_Swim

final class CoreDataManagerExerciseTests: XCTestCase {
    var coreDataManager: CoreDataManager!
    var workout: WorkoutEntity!
    
    override func setUp() {
        super.setUp()
        coreDataManager = CoreDataManager.shared
        workout = coreDataManager.createWorkout(name: "Exercise Test Workout", poolSize: 25)
        XCTAssertNotNil(workout)
    }
    
    override func tearDown() {
        let exercises = coreDataManager.fetchAllExercises()
        exercises.forEach { coreDataManager.deleteExercise($0) }
        if let workout = workout {
            coreDataManager.deleteWorkout(workout)
        }
        coreDataManager = nil
        super.tearDown()
    }
    
    func testCreateExercise() {
        // Arrange
        let description = "Test Exercise"
        let style: Int16 = 0
        let type: Int16 = 1
        let hasInterval = true
        let intervalMinutes: Int16 = 1
        let intervalSeconds: Int16 = 30
        let meters: Int16 = 50
        let orderIndex: Int16 = 0
        let repetitions: Int16 = 2
        
        // Act
        let exercise = coreDataManager.createExercise(for: workout,
                                                      description: description,
                                                      style: style,
                                                      type: type,
                                                      hasInterval: hasInterval,
                                                      intervalMinutes: intervalMinutes,
                                                      intervalSeconds: intervalSeconds,
                                                      meters: meters,
                                                      orderIndex: orderIndex,
                                                      repetitions: repetitions)
        // Assert
        XCTAssertNotNil(exercise)
        XCTAssertEqual(exercise?.exerciseDescription, description)
        XCTAssertEqual(exercise?.style, style)
        XCTAssertEqual(exercise?.type, type)
        XCTAssertEqual(exercise?.hasInterval, hasInterval)
        XCTAssertEqual(exercise?.intervalMinutes, intervalMinutes)
        XCTAssertEqual(exercise?.intervalSeconds, intervalSeconds)
        XCTAssertEqual(exercise?.meters, meters)
        XCTAssertEqual(exercise?.orderIndex, orderIndex)
        XCTAssertEqual(exercise?.repetitions, repetitions)
        XCTAssertNotNil(exercise?.workout)
    }
    
    func testFetchAndDeleteExercise() {
        // Arrange
        let description = "Exercise to Delete"
        let exercise = coreDataManager.createExercise(for: workout,
                                                      description: description,
                                                      style: 0,
                                                      type: 1,
                                                      hasInterval: false,
                                                      intervalMinutes: 0,
                                                      intervalSeconds: 0,
                                                      meters: 100,
                                                      orderIndex: 0,
                                                      repetitions: 1)
        XCTAssertNotNil(exercise)
        
        // Act
        var exercises = coreDataManager.fetchAllExercises()
        XCTAssertTrue(exercises.contains(where: { $0 === exercise }))
        
        if let exercise = exercise {
            coreDataManager.deleteExercise(exercise)
        }
        exercises = coreDataManager.fetchAllExercises()
        XCTAssertFalse(exercises.contains(where: { $0 === exercise }))
    }
}
