//
//  WorkoutCreationInteractorTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 05.04.2025.
//

import XCTest
@testable import Smart_Swim

final class WorkoutCreationInteractorTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: WorkoutCreationInteractor!
    
    // MARK: - Test Doubles
    class WorkoutCreationPresentationLogicSpy: WorkoutCreationPresentationLogic {
        var presentCreateWorkoutCalled = false
        var presentAddExerciseCalled = false
        var presentDeleteExerciseCalled = false
        var presentUpdateExerciseCalled = false
        
        var createWorkoutResponse: WorkoutCreationModels.CreateWorkout.Response?
        var addExerciseResponse: WorkoutCreationModels.AddExercise.Response?
        var deleteExerciseResponse: WorkoutCreationModels.DeleteExercise.Response?
        var updateExerciseResponse: WorkoutCreationModels.UpdateExercise.Response?
        
        func presentCreateWorkout(response: WorkoutCreationModels.CreateWorkout.Response) {
            presentCreateWorkoutCalled = true
            createWorkoutResponse = response
        }
        
        func presentAddExercise(response: WorkoutCreationModels.AddExercise.Response) {
            presentAddExerciseCalled = true
            addExerciseResponse = response
        }
        
        func presentDeleteExercise(response: WorkoutCreationModels.DeleteExercise.Response) {
            presentDeleteExerciseCalled = true
            deleteExerciseResponse = response
        }
        
        func presentUpdateExercise(response: WorkoutCreationModels.UpdateExercise.Response) {
            presentUpdateExerciseCalled = true
            updateExerciseResponse = response
        }
    }
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureWorkoutCreationInteractor()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureWorkoutCreationInteractor() {
        sut = WorkoutCreationInteractor()
    }
    
    
    // MARK: Create Workout
    func testCreateWorkoutWithValidData() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let validExercise = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Valid exercise"
        )
        
        let request = WorkoutCreationModels.CreateWorkout.Request(
            name: "Valid Workout",
            poolSize: .poolSize25,
            exercises: [validExercise]
        )
        _ = CoreDataManager.shared
        
        // Act
        sut.createWorkout(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCreateWorkoutCalled)
    }
    
    func testCreateWorkoutWithEmptyName() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let validExercise = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Valid exercise"
        )
        
        let request = WorkoutCreationModels.CreateWorkout.Request(
            name: "",
            poolSize: .poolSize25,
            exercises: [validExercise]
        )
        
        // Act
        sut.createWorkout(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCreateWorkoutCalled)
        XCTAssertNotNil(spy.createWorkoutResponse)
        XCTAssertFalse(spy.createWorkoutResponse!.success)
        XCTAssertEqual(
            spy.createWorkoutResponse!.errorMessage,
            "Название тренировки не может быть пустым или состоять только из пробелов."
        )
    }
    
    func testCreateWorkoutWithTooLongName() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let validExercise = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Valid exercise"
        )
        
        let longName = String(repeating: "A", count: 31)
        
        let request = WorkoutCreationModels.CreateWorkout.Request(
            name: longName,
            poolSize: .poolSize25,
            exercises: [validExercise]
        )
        
        // Act
        sut.createWorkout(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCreateWorkoutCalled)
        XCTAssertNotNil(spy.createWorkoutResponse)
        XCTAssertFalse(spy.createWorkoutResponse!.success)
        XCTAssertEqual(
            spy.createWorkoutResponse!.errorMessage,
            "Название тренировки не может превышать 30 символов."
        )
    }
    
    func testCreateWorkoutWithoutExercises() {
        // Arrsnge
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let request = WorkoutCreationModels.CreateWorkout.Request(
            name: "Valid Workout",
            poolSize: .poolSize25,
            exercises: []
        )
        
        // Act
        sut.createWorkout(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCreateWorkoutCalled)
        XCTAssertNotNil(spy.createWorkoutResponse)
        XCTAssertFalse(spy.createWorkoutResponse!.success)
        XCTAssertEqual(
            spy.createWorkoutResponse!.errorMessage,
            "Добавьте хотя бы одно упражнение."
        )
    }
    
    func testCreateWorkoutWithInvalidExerciseMeters() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let invalidExercise = Exercise(
            type: .warmup,
            meters: 0,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Invalid exercise"
        )
        
        let request = WorkoutCreationModels.CreateWorkout.Request(
            name: "Valid Workout",
            poolSize: .poolSize25,
            exercises: [invalidExercise]
        )
        
        // Act
        sut.createWorkout(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCreateWorkoutCalled)
        XCTAssertNotNil(spy.createWorkoutResponse)
        XCTAssertFalse(spy.createWorkoutResponse!.success)
        XCTAssertEqual(
            spy.createWorkoutResponse!.errorMessage,
            "Количество метров должно быть больше 0."
        )
    }
    
    func testCreateWorkoutWithInvalidExerciseRepetitions() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let invalidExercise = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 0,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Invalid exercise"
        )
        
        let request = WorkoutCreationModels.CreateWorkout.Request(
            name: "Valid Workout",
            poolSize: .poolSize25,
            exercises: [invalidExercise]
        )
        
        // Act
        sut.createWorkout(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCreateWorkoutCalled)
        XCTAssertNotNil(spy.createWorkoutResponse)
        XCTAssertFalse(spy.createWorkoutResponse!.success)
        XCTAssertEqual(
            spy.createWorkoutResponse!.errorMessage,
            "Количество повторений должно быть больше 0."
        )
    }
    
    func testCreateWorkoutWithInvalidIntervalParams() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let invalidExercise = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 2,
            hasInterval: true,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Invalid exercise"
        )
        
        let request = WorkoutCreationModels.CreateWorkout.Request(
            name: "Valid Workout",
            poolSize: .poolSize25,
            exercises: [invalidExercise]
        )
        
        // Act
        sut.createWorkout(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCreateWorkoutCalled)
        XCTAssertNotNil(spy.createWorkoutResponse)
        XCTAssertFalse(spy.createWorkoutResponse!.success)
        XCTAssertEqual(
            spy.createWorkoutResponse!.errorMessage,
            "Укажите минуты и секунды для интервала."
        )
    }
    
    // MARK: Add Exercise
    func testAddExercise() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let exercise = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Test exercise"
        )
        
        let request = WorkoutCreationModels.AddExercise.Request(exercise: exercise)
        
        // Act
        sut.addExercise(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentAddExerciseCalled)
        XCTAssertEqual(spy.addExerciseResponse?.exercises.count, 1)
        XCTAssertEqual(spy.addExerciseResponse?.exercises.first?.meters, 100)
    }
    
    // MARK: Delete Exercise
    func testDeleteExercise() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let exercise1 = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Exercise 1"
        )
        
        let exercise2 = Exercise(
            type: .main,
            meters: 200,
            repetitions: 4,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .backstroke,
            description: "Exercise 2"
        )
        
        sut.exercises = [exercise1, exercise2]
        let request = WorkoutCreationModels.DeleteExercise.Request(index: 0)
        
        // Act
        sut.deleteExercise(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentDeleteExerciseCalled)
        XCTAssertEqual(spy.deleteExerciseResponse?.exercises.count, 1)
        XCTAssertEqual(spy.deleteExerciseResponse?.exercises.first?.meters, 200)
    }
    
    func testDeleteExerciseWithInvalidIndex() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let exercise = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Exercise"
        )
        
        sut.exercises = [exercise]
        let request = WorkoutCreationModels.DeleteExercise.Request(index: 1)
        
        // Act
        sut.deleteExercise(request: request)
        
        // Assert
        XCTAssertFalse(spy.presentDeleteExerciseCalled)
        XCTAssertEqual(sut.exercises.count, 1)
    }
    
    // MARK: Update Exercise
    func testUpdateExercise() {
        // Arrange
        let spy = WorkoutCreationPresentationLogicSpy()
        sut.presenter = spy
        
        let exercise = Exercise(
            type: .warmup,
            meters: 100,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Original exercise"
        )
        
        sut.exercises = [exercise]
        
        let updatedExercise = Exercise(
            type: .main,
            meters: 200,
            repetitions: 4,
            hasInterval: true,
            intervalMinutes: 1,
            intervalSeconds: 30,
            style: .backstroke,
            description: "Updated exercise"
        )
        
        let request = WorkoutCreationModels.UpdateExercise.Request(
            exercise: updatedExercise,
            index: 0
        )
        
        // Act
        sut.updateExercise(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentUpdateExerciseCalled)
        XCTAssertEqual(spy.updateExerciseResponse?.exercises.count, 1)
        
        let resultExercise = spy.updateExerciseResponse?.exercises.first
        XCTAssertEqual(resultExercise?.type, .main)
        XCTAssertEqual(resultExercise?.meters, 200)
        XCTAssertEqual(resultExercise?.repetitions, 4)
        XCTAssertTrue(resultExercise?.hasInterval ?? false)
        XCTAssertEqual(resultExercise?.intervalMinutes, 1)
        XCTAssertEqual(resultExercise?.intervalSeconds, 30)
        XCTAssertEqual(resultExercise?.style, .backstroke)
        XCTAssertEqual(resultExercise?.description, "Updated exercise")
    }
}
