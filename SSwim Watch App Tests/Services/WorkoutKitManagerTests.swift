//
//  WorkoutKitManagerTests.swift
//  SSwim Watch App Tests
//
//  Created by Artem Tkachuk on 12.04.2025.
//

import XCTest
import Combine
@testable import SSwim_Watch_App

class TestWatchCommunicationService: WatchCommunicationService {
    override init() {
        super.init()
    }
    
    override func sendMessageWithReply(type: MessageType,
                                       data: [String: Any] = [:],
                                       timeout: TimeInterval = 3.0,
                                       completion: @escaping ([String: Any]?) -> Void) -> Bool {
        completion([:])
        return true
    }
    
    override var isReachable: Bool {
        get { return true }
        set { }
    }
}

final class WorkoutKitManagerTests: XCTestCase {
    var manager: TestWorkoutKitManager!
    var cancellables: Set<AnyCancellable> = []
    
    override func setUp() {
        super.setUp()
        manager = TestWorkoutKitManager()
    }
    
    override func tearDown() {
        manager = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testStartWorkoutPublishesRunningState() {
        let stateExpectation = expectation(description: "Паблишер состояния тренировки должен отправлять значение true")
        let dummyWorkout = SwimWorkoutModels.SwimWorkout(
            id: "workout1",
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
        manager.workoutStatePublisher
            .sink { isRunning in
                if isRunning {
                    stateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        manager.startWorkout(workout: dummyWorkout)
        wait(for: [stateExpectation], timeout: 1)
    }
    
    func testStopWorkoutPublishesStoppedState() {
        let stateExpectation = expectation(description: "Паблишер состояния тренировки должен отправлять значение false")
        let dummyWorkout = SwimWorkoutModels.SwimWorkout(
            id: "workout1",
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
        manager.startWorkout(workout: dummyWorkout)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.manager.stopWorkout()
        }
        manager.workoutStatePublisher
            .sink { isRunning in
                if isRunning == false {
                    stateExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        wait(for: [stateExpectation], timeout: 2)
    }
    
    func testHeartRatePublisher() {
        let heartExpectation = expectation(description: "Паблишер сердечного ритма должен отправлять какое-либо значение")
        var receivedHeartRate: Double?
        manager.heartRatePublisher
            .sink { heartRate in
                receivedHeartRate = heartRate
                heartExpectation.fulfill()
            }
            .store(in: &cancellables)
        manager.heartRatePublisher.send(80.0)
        wait(for: [heartExpectation], timeout: 1)
        XCTAssertEqual(receivedHeartRate, 80.0)
    }
    
    func testStrokeCountPublisher() {
        let strokeExpectation = expectation(description: "Паблишер количества гребков должен отправлять какое-либо значение")
        var receivedStrokeCount: Int?
        manager.strokeCountPublisher
            .sink { count in
                receivedStrokeCount = count
                strokeExpectation.fulfill()
            }
            .store(in: &cancellables)
        manager.strokeCountPublisher.send(25)
        wait(for: [strokeExpectation], timeout: 1)
        XCTAssertEqual(receivedStrokeCount, 25)
    }
    
    func testCaloriesPublisher() {
        let caloriesExpectation = expectation(description: "Паблишер калорий должен отправлять какое-либо значение")
        var receivedCalories: Double?
        manager.caloriesPublisher
            .sink { calories in
                receivedCalories = calories
                caloriesExpectation.fulfill()
            }
            .store(in: &cancellables)
        manager.caloriesPublisher.send(150.0)
        wait(for: [caloriesExpectation], timeout: 1)
        XCTAssertEqual(receivedCalories, 150.0)
    }
    
    func testLapCompletedPublisher() {
        let lapExpectation = expectation(description: "Паблишер завершения отрезка должен отправлять какое-либо значение")
        var receivedLap: Int?
        manager.lapCompletedPublisher
            .sink { lap in
                receivedLap = lap
                lapExpectation.fulfill()
            }
            .store(in: &cancellables)
        manager.lapCompletedPublisher.send(3)
        wait(for: [lapExpectation], timeout: 1)
        XCTAssertEqual(receivedLap, 3)
    }
}
