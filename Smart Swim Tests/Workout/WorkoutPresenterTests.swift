//
//  WorkoutPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 05.04.2025.
//

import XCTest
@testable import Smart_Swim

final class WorkoutPresenterTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: WorkoutPresenter!
    
    // MARK: - Test Doubles
    class WorkoutDisplayLogicSpy: WorkoutDisplayLogic {
        var displayWorkoutCreationCalled = false
        var displayInfoCalled = false
        var displayWorkoutsCalled = false
        var displayDeleteWorkoutCalled = false
        var displayEditWorkoutCalled = false
        
        var workoutCreationViewModel: WorkoutModels.Create.ViewModel?
        var infoViewModel: WorkoutModels.Info.ViewModel?
        var workoutsViewModel: WorkoutModels.FetchWorkouts.ViewModel?
        var deleteWorkoutViewModel: WorkoutModels.DeleteWorkout.ViewModel?
        var editWorkoutViewModel: WorkoutModels.EditWorkout.ViewModel?
        
        func displayWorkoutCreation(viewModel: WorkoutModels.Create.ViewModel) {
            displayWorkoutCreationCalled = true
            workoutCreationViewModel = viewModel
        }
        
        func displayInfo(viewModel: WorkoutModels.Info.ViewModel) {
            displayInfoCalled = true
            infoViewModel = viewModel
        }
        
        func displayWorkouts(viewModel: WorkoutModels.FetchWorkouts.ViewModel) {
            displayWorkoutsCalled = true
            workoutsViewModel = viewModel
        }
        
        func displayDeleteWorkout(viewModel: WorkoutModels.DeleteWorkout.ViewModel) {
            displayDeleteWorkoutCalled = true
            deleteWorkoutViewModel = viewModel
        }
        
        func displayEditWorkout(viewModel: WorkoutModels.EditWorkout.ViewModel) {
            displayEditWorkoutCalled = true
            editWorkoutViewModel = viewModel
        }
    }
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureWorkoutPresenter()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureWorkoutPresenter() {
        sut = WorkoutPresenter()
    }
    
    // MARK: Present Workout Creation
    func testPresentWorkoutCreation() {
        // Arrange
        let spy = WorkoutDisplayLogicSpy()
        sut.viewController = spy
        
        let response = WorkoutModels.Create.Response()
        
        // Act
        sut.presentWorkoutCreation(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayWorkoutCreationCalled)
    }
    
    // MARK: Present Info
    func testPresentInfo() {
        // Arrange
        let spy = WorkoutDisplayLogicSpy()
        sut.viewController = spy
        
        let response = WorkoutModels.Info.Response()
        
        // Act
        sut.presentInfo(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayInfoCalled)
    }
    
    // MARK: Present Workouts
    func testPresentWorkoutsWithEmptyList() {
        // Arrange
        let spy = WorkoutDisplayLogicSpy()
        sut.viewController = spy
        
        let response = WorkoutModels.FetchWorkouts.Response(workouts: [])
        
        // Act
        sut.presentWorkouts(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayWorkoutsCalled)
        XCTAssertEqual(spy.workoutsViewModel?.workouts.count, 0)
    }
    
    func testPresentWorkoutsWithMultipleWorkouts() {
        // Arrange
        let spy = WorkoutDisplayLogicSpy()
        sut.viewController = spy
        
        let workout1 = WorkoutModels.FetchWorkouts.Response.WorkoutData(
            name: "Test Workout 1",
            exercises: [
                createExerciseData(
                    meters: 100,
                    styleDescription: "кроль",
                    type: .warmup,
                    description: "Warm up exercise",
                    formattedString: "1. Разминка 100м кроль\n  Warm up exercise",
                    repetitions: 1
                ),
                createExerciseData(
                    meters: 200,
                    styleDescription: "на спине",
                    type: .main,
                    description: "Main exercise",
                    formattedString: "2. 200м на спине\n  Main exercise",
                    repetitions: 2
                )
            ],
            totalVolume: 500
        )
        
        let workout2 = WorkoutModels.FetchWorkouts.Response.WorkoutData(
            name: "Test Workout 2",
            exercises: [
                createExerciseData(
                    meters: 50,
                    styleDescription: "брасс",
                    type: .cooldown,
                    description: "Cool down exercise",
                    formattedString: "1. Заминка 50м брасс\n  Cool down exercise",
                    repetitions: 1
                )
            ],
            totalVolume: 50
        )
        
        let response = WorkoutModels.FetchWorkouts.Response(workouts: [workout1, workout2])
        
        // Act
        sut.presentWorkouts(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayWorkoutsCalled)
        XCTAssertEqual(spy.workoutsViewModel?.workouts.count, 2)
        
        let firstWorkout = spy.workoutsViewModel?.workouts.first
        XCTAssertEqual(firstWorkout?.name, "Test Workout 1")
        XCTAssertEqual(firstWorkout?.totalVolume, 500, "First workout should have correct total volume")
        XCTAssertEqual(firstWorkout?.exercises.count, 2)
        XCTAssertEqual(firstWorkout?.exercises.first, "1. Разминка 100м кроль\n  Warm up exercise")
        
        let secondWorkout = spy.workoutsViewModel?.workouts.last
        XCTAssertEqual(secondWorkout?.name, "Test Workout 2")
        XCTAssertEqual(secondWorkout?.totalVolume, 50)
        XCTAssertEqual(secondWorkout?.exercises.count, 1)
        XCTAssertEqual(secondWorkout?.exercises.first, "1. Заминка 50м брасс\n  Cool down exercise")
    }
    
    // MARK: Present Delete Workout
    func testPresentDeleteWorkout() {
        // Arrange
        let spy = WorkoutDisplayLogicSpy()
        sut.viewController = spy
        
        let response = WorkoutModels.DeleteWorkout.Response(deletedIndex: 1)
        
        // Act
        sut.presentDeleteWorkout(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayDeleteWorkoutCalled)
        XCTAssertEqual(spy.deleteWorkoutViewModel?.deletedIndex, 1)
    }
    
    // MARK: Present Edit Workout
    func testPresentEditWorkout() {
        // Arrange
        let spy = WorkoutDisplayLogicSpy()
        sut.viewController = spy
        
        let response = WorkoutModels.EditWorkout.Response(index: 0)
        
        // Act
        sut.presentEditWorkout(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayEditWorkoutCalled)
        XCTAssertEqual(spy.editWorkoutViewModel?.index, 0)
    }
    
    // MARK: - Helper Methods
    private func createExerciseData(
        meters: Int16,
        styleDescription: String,
        type: ExerciseType,
        description: String?,
        formattedString: String,
        repetitions: Int16
    ) -> WorkoutModels.FetchWorkouts.Response.ExerciseData {
        return WorkoutModels.FetchWorkouts.Response.ExerciseData(
            meters: meters,
            styleDescription: styleDescription,
            type: type,
            exerciseDescription: description,
            formattedString: formattedString,
            repetitions: repetitions
        )
    }
}
