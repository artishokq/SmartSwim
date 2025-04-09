//
//  WorkoutSessionViewModelTests.swift
//  SSwim Watch App Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
@testable import SSwim_Watch_App

final class WorkoutSessionViewModelTests: XCTestCase {
    var viewModel: WorkoutSessionViewModel!
    var dummyWorkout: SwimWorkoutModels.SwimWorkout!

    override func setUp() {
        super.setUp()
        dummyWorkout = SwimWorkoutModels.SwimWorkout(
            id: "test_workout",
            name: "Test Workout",
            poolSize: 25,
            exercises: [
                SwimWorkoutModels.SwimExercise(
                    id: "ex1",
                    description: "Test Exercise",
                    style: 0,
                    type: 1,
                    hasInterval: false,
                    intervalMinutes: 0,
                    intervalSeconds: 0,
                    meters: 100,
                    orderIndex: 0,
                    repetitions: 1
                )
            ]
        )
        viewModel = WorkoutSessionViewModel(workout: dummyWorkout)
    }

    override func tearDown() {
        viewModel = nil
        dummyWorkout = nil
        super.tearDown()
    }
    
    func testStartSessionSetsPreviewingState() {
        viewModel.startSession()
        XCTAssertEqual(viewModel.sessionState, SwimWorkoutModels.WorkoutSessionState.notStarted)
    }
    
    func testCompleteSessionViaCompleteCurrentExercise() {
        viewModel.startSession()
        viewModel.completeCurrentExercise()
        
        let expectation = self.expectation(description: "Сессия завершается")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.sessionState, SwimWorkoutModels.WorkoutSessionState.previewingExercise)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}

