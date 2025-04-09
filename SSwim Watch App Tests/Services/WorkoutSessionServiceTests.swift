//
//  WorkoutSessionServiceTests.swift
//  SSwim Watch App Tests
//
//  Created by Artem Tkachuk on 12.04.2025.
//

import XCTest
import Combine
@testable import SSwim_Watch_App

class TestWorkoutKitManager: WorkoutKitManager {
    override init() {
        super.init()
    }
    
    override func startWorkout(workout: SwimWorkoutModels.SwimWorkout) {
        DispatchQueue.main.async {
            self.workoutStatePublisher.send(true)
        }
    }
    
    override func stopWorkout() {
        DispatchQueue.main.async {
            self.workoutStatePublisher.send(false)
        }
    }
}

final class WorkoutSessionServiceTests: XCTestCase {
    var service: WorkoutSessionService!
    var dummyWorkout: SwimWorkoutModels.SwimWorkout!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        let exercise = SwimWorkoutModels.SwimExercise(
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
        dummyWorkout = SwimWorkoutModels.SwimWorkout(
            id: "workout1",
            name: "Test Workout",
            poolSize: 25,
            exercises: [exercise]
        )
        let testManager = TestWorkoutKitManager()
        let testComm = TestWatchCommunicationService()
        service = WorkoutSessionService(workout: dummyWorkout,
                                        workoutKitManager: testManager,
                                        communicationService: testComm)
    }
    
    override func tearDown() {
        service = nil
        dummyWorkout = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testStartSession() {
        let expectation1 = expectation(description: "Состояние сессии должно измениться на previewingExercise")
        service.startSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.service.sessionState, .previewingExercise)
            expectation1.fulfill()
        }
        wait(for: [expectation1], timeout: 1)
    }
    
    func testHeartRateSubscription() {
        let previewData = SwimWorkoutModels.ActiveExerciseData(from: dummyWorkout.exercises[0],
                                                               index: 1,
                                                               totalExercises: 1)
        service.currentExercise = previewData
        
        let heartExpectation = expectation(description: "Сердечный ритм должен обновлять значение currentExercise")
        if let testManager = service.workoutKitManager as? TestWorkoutKitManager {
            testManager.heartRatePublisher.send(75.0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.service.currentExercise?.heartRate, 75.0)
            heartExpectation.fulfill()
        }
        wait(for: [heartExpectation], timeout: 1)
    }
}
