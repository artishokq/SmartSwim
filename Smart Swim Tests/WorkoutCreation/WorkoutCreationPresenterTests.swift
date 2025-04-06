//
//  WorkoutCreationPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 05.04.2025.
//

import XCTest
@testable import Smart_Swim

final class WorkoutCreationPresenterTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: WorkoutCreationPresenter!
    
    // MARK: - Test Doubles
    class WorkoutCreationDisplayLogicSpy: WorkoutCreationDisplayLogic {
        var displayCreateWorkoutCalled = false
        var displayAddExerciseCalled = false
        var displayDeleteExerciseCalled = false
        var displayUpdateExerciseCalled = false
        
        var createWorkoutViewModel: WorkoutCreationModels.CreateWorkout.ViewModel?
        var addExerciseViewModel: WorkoutCreationModels.AddExercise.ViewModel?
        var deleteExerciseViewModel: WorkoutCreationModels.DeleteExercise.ViewModel?
        var updateExerciseViewModel: WorkoutCreationModels.UpdateExercise.ViewModel?
        
        func displayCreateWorkout(viewModel: WorkoutCreationModels.CreateWorkout.ViewModel) {
            displayCreateWorkoutCalled = true
            createWorkoutViewModel = viewModel
        }
        
        func displayAddExercise(viewModel: WorkoutCreationModels.AddExercise.ViewModel) {
            displayAddExerciseCalled = true
            addExerciseViewModel = viewModel
        }
        
        func displayDeleteExercise(viewModel: WorkoutCreationModels.DeleteExercise.ViewModel) {
            displayDeleteExerciseCalled = true
            deleteExerciseViewModel = viewModel
        }
        
        func displayUpdateExercise(viewModel: WorkoutCreationModels.UpdateExercise.ViewModel) {
            displayUpdateExerciseCalled = true
            updateExerciseViewModel = viewModel
        }
    }
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureWorkoutCreationPresenter()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureWorkoutCreationPresenter() {
        sut = WorkoutCreationPresenter()
    }
    
    // MARK: Create Workout
    func testPresentCreateWorkoutSuccess() {
        // Arrange
        let spy = WorkoutCreationDisplayLogicSpy()
        sut.viewController = spy
        
        let response = WorkoutCreationModels.CreateWorkout.Response(
            success: true,
            errorMessage: nil
        )
        
        // Act
        sut.presentCreateWorkout(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayCreateWorkoutCalled)
        XCTAssertTrue(spy.createWorkoutViewModel?.success ?? false)
        XCTAssertNil(spy.createWorkoutViewModel?.errorMessage)
    }
    
    func testPresentCreateWorkoutFailure() {
        // Arrange
        let spy = WorkoutCreationDisplayLogicSpy()
        sut.viewController = spy
        
        let errorMessage = "Error message"
        let response = WorkoutCreationModels.CreateWorkout.Response(
            success: false,
            errorMessage: errorMessage
        )
        
        // Act
        sut.presentCreateWorkout(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayCreateWorkoutCalled)
        XCTAssertFalse(spy.createWorkoutViewModel?.success ?? true)
        XCTAssertEqual(spy.createWorkoutViewModel?.errorMessage, errorMessage)
    }
    
    // MARK: Add Exercise
    func testPresentAddExercise() {
        // Arrange
        let spy = WorkoutCreationDisplayLogicSpy()
        sut.viewController = spy
        
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
        
        let response = WorkoutCreationModels.AddExercise.Response(exercises: [exercise])
        
        // Act
        sut.presentAddExercise(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayAddExerciseCalled)
        XCTAssertEqual(spy.addExerciseViewModel?.exercises.count, 1)
        
        let resultExercise = spy.addExerciseViewModel?.exercises.first
        XCTAssertEqual(resultExercise?.type, .warmup)
        XCTAssertEqual(resultExercise?.meters, 100)
        XCTAssertEqual(resultExercise?.repetitions, 2)
        XCTAssertFalse(resultExercise?.hasInterval ?? true)
        XCTAssertEqual(resultExercise?.style, .freestyle)
        XCTAssertEqual(resultExercise?.description, "Test exercise")
    }
    
    // MARK: Delete Exercise
    func testPresentDeleteExercise() {
        // Arrange
        let spy = WorkoutCreationDisplayLogicSpy()
        sut.viewController = spy
        
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
        
        let response = WorkoutCreationModels.DeleteExercise.Response(exercises: [exercise])
        
        // Act
        sut.presentDeleteExercise(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayDeleteExerciseCalled)
        XCTAssertEqual(spy.deleteExerciseViewModel?.exercises.count, 1)
    }
    
    func testPresentDeleteExerciseWithEmptyList() {
        // Arrange
        let spy = WorkoutCreationDisplayLogicSpy()
        sut.viewController = spy
        
        let response = WorkoutCreationModels.DeleteExercise.Response(exercises: [])
        
        // Act
        sut.presentDeleteExercise(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayDeleteExerciseCalled)
        XCTAssertEqual(spy.deleteExerciseViewModel?.exercises.count, 0)
    }
    
    // MARK: Update Exercise
    func testPresentUpdateExercise() {
        // Arrange
        let spy = WorkoutCreationDisplayLogicSpy()
        sut.viewController = spy
        
        let exercise = Exercise(
            type: .main,
            meters: 200,
            repetitions: 4,
            hasInterval: true,
            intervalMinutes: 1,
            intervalSeconds: 30,
            style: .backstroke,
            description: "Updated exercise"
        )
        
        let response = WorkoutCreationModels.UpdateExercise.Response(exercises: [exercise])
        
        // Act
        sut.presentUpdateExercise(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayUpdateExerciseCalled)
        XCTAssertEqual(spy.updateExerciseViewModel?.exercises.count, 1)
        
        let resultExercise = spy.updateExerciseViewModel?.exercises.first
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
