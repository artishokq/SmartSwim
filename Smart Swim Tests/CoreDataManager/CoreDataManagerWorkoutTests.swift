//
//  CoreDataManagerWorkoutTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 05.04.2025.
//

import XCTest
import CoreData
@testable import Smart_Swim

final class CoreDataManagerWorkoutTests: XCTestCase {
    // MARK: - Subject Under Test
    var coreDataManager: CoreDataManager!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        coreDataManager = configureInMemoryCoreDataManager()
    }
    
    override func tearDown() {
        let allWorkouts = coreDataManager.fetchAllWorkouts()
        for workout in allWorkouts {
            coreDataManager.deleteWorkout(workout)
        }
        coreDataManager = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureInMemoryCoreDataManager() -> CoreDataManager {
        let persistentContainer = NSPersistentContainer(name: "CoreData")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { description, error in
            XCTAssertNil(error)
        }
        let manager = CoreDataManager.shared
        let mirror = Mirror(reflecting: manager)
        if let persistentContainerProperty = mirror.children.first(where: { $0.label == "persistentContainer" }) {
            if let persistentContainerPointer = persistentContainerProperty.value as? UnsafeMutablePointer<NSPersistentContainer> {
                persistentContainerPointer.pointee = persistentContainer
            }
        }
        return manager
    }
    
    // MARK: - Test Cases
    func testCreateWorkoutWithNameAndPoolSize() {
        // Arrange
        let name = "Test Workout"
        let poolSize: Int16 = 25
        
        // Act
        let workout = coreDataManager.createWorkout(name: name, poolSize: poolSize)
        
        // Assert
        XCTAssertNotNil(workout)
        XCTAssertEqual(workout?.name, name)
        XCTAssertEqual(workout?.poolSize, poolSize)
        XCTAssertEqual(workout?.exercises?.count, 0)
    }
    
    func testCreateWorkoutWithExercises() {
        // Arrange
        let name = "Test Workout with Exercises"
        let poolSize: Int16 = 50
        
        let exercise1 = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Warmup exercise"
        )
        
        let exercise2 = Exercise(
            type: .main,
            meters: 200,
            repetitions: 4,
            hasInterval: true,
            intervalMinutes: 1,
            intervalSeconds: 30,
            style: .backstroke,
            description: "Main exercise"
        )
        
        // Act
        let workout = coreDataManager.createWorkout(
            name: name,
            poolSize: poolSize,
            exercises: [exercise1, exercise2]
        )
        
        // Assert
        XCTAssertNotNil(workout)
        XCTAssertEqual(workout?.name, name)
        XCTAssertEqual(workout?.poolSize, poolSize)
        
        if let exercises = workout?.exercises {
            XCTAssertEqual(exercises.count, 2)
            
            let exerciseEntities = exercises.allObjects as! [ExerciseEntity]
            let sortedExercises = exerciseEntities.sorted { $0.orderIndex < $1.orderIndex }
            
            XCTAssertEqual(sortedExercises[0].type, exercise1.type.rawValue)
            XCTAssertEqual(sortedExercises[0].meters, exercise1.meters)
            XCTAssertEqual(sortedExercises[0].repetitions, exercise1.repetitions)
            XCTAssertEqual(sortedExercises[0].hasInterval, exercise1.hasInterval)
            XCTAssertEqual(sortedExercises[0].style, exercise1.style.rawValue)
            XCTAssertEqual(sortedExercises[0].exerciseDescription, exercise1.description)
            
            XCTAssertEqual(sortedExercises[1].type, exercise2.type.rawValue)
            XCTAssertEqual(sortedExercises[1].meters, exercise2.meters)
            XCTAssertEqual(sortedExercises[1].repetitions, exercise2.repetitions)
            XCTAssertEqual(sortedExercises[1].hasInterval, exercise2.hasInterval)
            XCTAssertEqual(sortedExercises[1].intervalMinutes, exercise2.intervalMinutes ?? 0)
            XCTAssertEqual(sortedExercises[1].intervalSeconds, exercise2.intervalSeconds ?? 0)
            XCTAssertEqual(sortedExercises[1].style, exercise2.style.rawValue)
            XCTAssertEqual(sortedExercises[1].exerciseDescription, exercise2.description)
        } else {
            XCTFail("Workout should have exercises")
        }
    }
    
    func testFetchAllWorkouts() {
        // Arrange
        _ = coreDataManager.createWorkout(name: "Workout 1", poolSize: 25)
        _ = coreDataManager.createWorkout(name: "Workout 2", poolSize: 50)
        
        // Act
        let fetchedWorkouts = coreDataManager.fetchAllWorkouts()
        
        // Assert
        XCTAssertEqual(fetchedWorkouts.count, 2)
        
        let workoutNames = fetchedWorkouts.map { $0.name }
        XCTAssertTrue(workoutNames.contains("Workout 1"))
        XCTAssertTrue(workoutNames.contains("Workout 2"))
    }
    
    func testDeleteWorkout() {
        // Arrange
        let workout = coreDataManager.createWorkout(name: "Workout to Delete", poolSize: 25)
        XCTAssertNotNil(workout)
        
        // Act
        coreDataManager.deleteWorkout(workout!)
        
        // Assert
        let fetchedWorkouts = coreDataManager.fetchAllWorkouts()
        XCTAssertEqual(fetchedWorkouts.count, 0)
    }
    
    func testCreateExerciseForWorkout() {
        // Arrange
        let workout = coreDataManager.createWorkout(name: "Workout with Added Exercise", poolSize: 25)
        XCTAssertNotNil(workout)
        
        // Act
        let exercise = coreDataManager.createExercise(
            for: workout!,
            description: "Test exercise",
            style: SwimStyle.freestyle.rawValue,
            type: ExerciseType.warmup.rawValue,
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0,
            meters: 100,
            orderIndex: 0,
            repetitions: 2
        )
        
        // Assert
        XCTAssertNotNil(exercise)
        XCTAssertEqual(exercise?.exerciseDescription, "Test exercise")
        XCTAssertEqual(exercise?.style, SwimStyle.freestyle.rawValue)
        XCTAssertEqual(exercise?.type, ExerciseType.warmup.rawValue)
        XCTAssertEqual(exercise?.meters, 100)
        XCTAssertEqual(exercise?.repetitions, 2)
        
        XCTAssertEqual(exercise?.workout, workout)
        XCTAssertEqual(workout?.exercises?.count, 1)
    }
    
    func testFetchAllExercises() {
        // Arrange
        let workout = coreDataManager.createWorkout(name: "Workout for Fetching Exercises", poolSize: 25)
        XCTAssertNotNil(workout)
        
        _ = coreDataManager.createExercise(
            for: workout!,
            description: "Exercise 1",
            style: SwimStyle.freestyle.rawValue,
            type: ExerciseType.warmup.rawValue,
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0,
            meters: 100,
            orderIndex: 0,
            repetitions: 2
        )
        
        _ = coreDataManager.createExercise(
            for: workout!,
            description: "Exercise 2",
            style: SwimStyle.backstroke.rawValue,
            type: ExerciseType.main.rawValue,
            hasInterval: true,
            intervalMinutes: 1,
            intervalSeconds: 30,
            meters: 200,
            orderIndex: 1,
            repetitions: 4
        )
        
        // Act
        let fetchedExercises = coreDataManager.fetchAllExercises()
        
        // Assert
        XCTAssertEqual(fetchedExercises.count, 2)
        
        let exerciseDescriptions = fetchedExercises.map { $0.exerciseDescription }
        XCTAssertTrue(exerciseDescriptions.contains("Exercise 1"))
        XCTAssertTrue(exerciseDescriptions.contains("Exercise 2"))
    }
    
    func testDeleteExercise() {
        // Arrange
        let workout = coreDataManager.createWorkout(name: "Workout for Exercise Deletion", poolSize: 25)
        XCTAssertNotNil(workout)
        
        let exercise = coreDataManager.createExercise(
            for: workout!,
            description: "Exercise to Delete",
            style: SwimStyle.freestyle.rawValue,
            type: ExerciseType.warmup.rawValue,
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0,
            meters: 100,
            orderIndex: 0,
            repetitions: 2
        )
        XCTAssertNotNil(exercise)
        
        // Act
        coreDataManager.deleteExercise(exercise!)
        
        // Assert
        let fetchedExercises = coreDataManager.fetchAllExercises()
        XCTAssertEqual(fetchedExercises.count, 0)
        XCTAssertEqual(workout?.exercises?.count, 0)
    }
}
