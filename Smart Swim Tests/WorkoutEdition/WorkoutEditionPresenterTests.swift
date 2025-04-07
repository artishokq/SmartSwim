//
//  WorkoutEditionPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 06.04.2025.
//

import XCTest
@testable import Smart_Swim

final class WorkoutEditionPresenterTests: XCTestCase {
    // MARK: - Properties
    var sut: WorkoutEditionPresenter!
    var mockViewController: MockWorkoutEditionViewController!
    
    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        sut = WorkoutEditionPresenter()
        mockViewController = MockWorkoutEditionViewController()
        sut.viewController = mockViewController
    }
    
    override func tearDown() {
        sut = nil
        mockViewController = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testPresentLoadWorkout() {
        // Arrange
        let response = WorkoutEditionModels.LoadWorkout.Response(
            name: "Test Workout",
            poolSize: .poolSize25,
            exercises: [createSampleExercise()]
        )
        
        // Act
        sut.presentLoadWorkout(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayLoadWorkoutCalled)
        XCTAssertEqual(mockViewController.loadWorkoutViewModel?.name, "Test Workout")
        XCTAssertEqual(mockViewController.loadWorkoutViewModel?.poolSize, .poolSize25)
        XCTAssertEqual(mockViewController.loadWorkoutViewModel?.exercises.count, 1)
    }
    
    func testPresentUpdateWorkoutSuccess() {
        // Arrange
        let response = WorkoutEditionModels.UpdateWorkout.Response(
            success: true,
            errorMessage: nil
        )
        
        // Act
        sut.presentUpdateWorkout(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayUpdateWorkoutCalled)
        XCTAssertTrue(mockViewController.updateWorkoutViewModel?.success ?? false)
        XCTAssertNil(mockViewController.updateWorkoutViewModel?.errorMessage)
    }
    
    func testPresentUpdateWorkoutFailure() {
        // Arrange
        let response = WorkoutEditionModels.UpdateWorkout.Response(
            success: false,
            errorMessage: "Error message"
        )
        
        // Act
        sut.presentUpdateWorkout(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayUpdateWorkoutCalled)
        XCTAssertFalse(mockViewController.updateWorkoutViewModel?.success ?? true)
        XCTAssertEqual(mockViewController.updateWorkoutViewModel?.errorMessage, "Error message")
    }
    
    func testPresentAddExercise() {
        // Arrange
        let exercises = [createSampleExercise()]
        let response = WorkoutEditionModels.AddExercise.Response(exercises: exercises)
        
        // Act
        sut.presentAddExercise(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayAddExerciseCalled)
        XCTAssertEqual(mockViewController.addExerciseViewModel?.exercises.count, 1)
    }
    
    func testPresentDeleteExercise() {
        // Arrange
        let exercises = [createSampleExercise()]
        let response = WorkoutEditionModels.DeleteExercise.Response(exercises: exercises)
        
        // Act
        sut.presentDeleteExercise(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayDeleteExerciseCalled)
        XCTAssertEqual(mockViewController.deleteExerciseViewModel?.exercises.count, 1)
    }
    
    func testPresentUpdateExercise() {
        // Arrange
        let exercises = [createSampleExercise()]
        let response = WorkoutEditionModels.UpdateExercise.Response(exercises: exercises)
        
        // Act
        sut.presentUpdateExercise(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayUpdateExerciseCalled)
        XCTAssertEqual(mockViewController.updateExerciseViewModel?.exercises.count, 1)
    }
    
    // MARK: - Helper Methods
    private func createSampleExercise() -> Exercise {
        return Exercise(
            type: .main,
            meters: 100,
            repetitions: 4,
            hasInterval: true,
            intervalMinutes: 1,
            intervalSeconds: 30,
            style: .freestyle,
            description: "Test exercise"
        )
    }
}

// MARK: - Mock Classes
class MockWorkoutEditionViewController: WorkoutEditionDisplayLogic {
    var displayLoadWorkoutCalled = false
    var displayUpdateWorkoutCalled = false
    var displayAddExerciseCalled = false
    var displayDeleteExerciseCalled = false
    var displayUpdateExerciseCalled = false
    
    var loadWorkoutViewModel: WorkoutEditionModels.LoadWorkout.ViewModel?
    var updateWorkoutViewModel: WorkoutEditionModels.UpdateWorkout.ViewModel?
    var addExerciseViewModel: WorkoutEditionModels.AddExercise.ViewModel?
    var deleteExerciseViewModel: WorkoutEditionModels.DeleteExercise.ViewModel?
    var updateExerciseViewModel: WorkoutEditionModels.UpdateExercise.ViewModel?
    
    func displayLoadWorkout(viewModel: WorkoutEditionModels.LoadWorkout.ViewModel) {
        displayLoadWorkoutCalled = true
        loadWorkoutViewModel = viewModel
    }
    
    func displayUpdateWorkout(viewModel: WorkoutEditionModels.UpdateWorkout.ViewModel) {
        displayUpdateWorkoutCalled = true
        updateWorkoutViewModel = viewModel
    }
    
    func displayAddExercise(viewModel: WorkoutEditionModels.AddExercise.ViewModel) {
        displayAddExerciseCalled = true
        addExerciseViewModel = viewModel
    }
    
    func displayDeleteExercise(viewModel: WorkoutEditionModels.DeleteExercise.ViewModel) {
        displayDeleteExerciseCalled = true
        deleteExerciseViewModel = viewModel
    }
    
    func displayUpdateExercise(viewModel: WorkoutEditionModels.UpdateExercise.ViewModel) {
        displayUpdateExerciseCalled = true
        updateExerciseViewModel = viewModel
    }
}
