//
//  ActiveSwimmingViewModelTests.swift
//  SSwim Watch App Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
@testable import SSwim_Watch_App

class DummyCommunicationService: WatchCommunicationService {
    override init() {
        super.init()
    }

    override func subscribe(to type: MessageType, handler: @escaping ([String: Any]) -> Void) -> UUID {
        return UUID()
    }
    
    override func sendMessage(type: MessageType, data: [String: Any]) -> Bool {
        return true
    }
    
    override func sendMessageWithReply(type: MessageType, data: [String: Any], timeout: TimeInterval, completion replyHandler: @escaping ([String: Any]?) -> Void) -> Bool {
        replyHandler([:])
        return true
    }
    
    override var isReachable: Bool {
        get {
            return true
        }
        set {
        }
    }
}

class MockStartService: StartService {
    var startWorkoutCalled = false
    var stopWorkoutCalled = false
    var resetCommandCalled = false

    override func startWorkout() {
        startWorkoutCalled = true
    }
    override func stopWorkout() {
        stopWorkoutCalled = true
    }
    override func resetCommand() {
        resetCommandCalled = true
        self.command = ""
    }
}

final class ActiveSwimmingViewModelTests: XCTestCase {
    var viewModel: ActiveSwimmingViewModel!
    var mockService: MockStartService!

    override func setUp() {
        super.setUp()
        viewModel = ActiveSwimmingViewModel()
        let dummyComm = DummyCommunicationService()
        let dummyStartKit = StartKit(communicationService: dummyComm, workoutKitManager: WorkoutKitManager.shared)
        mockService = MockStartService(startKit: dummyStartKit, workoutKitManager: WorkoutKitManager.shared)
        viewModel.setupWithService(startService: mockService)
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    func testStartWorkout() {
        viewModel.startWorkout()
        XCTAssertTrue(viewModel.isWorkoutActive)
        XCTAssertTrue(mockService.startWorkoutCalled)
    }

    func testStopWorkout() {
        viewModel.stopWorkout()
        XCTAssertFalse(viewModel.isWorkoutActive)
        XCTAssertTrue(mockService.stopWorkoutCalled)
    }

    func testClearCommands() {
        viewModel.command = "тестовая команда"
        viewModel.clearCommands()
        XCTAssertEqual(viewModel.command, "")
        XCTAssertTrue(mockService.resetCommandCalled)
    }

    func testCommandSubscription() {
        mockService.command = "новая команда"
        let expectation = self.expectation(description: "Команда обновлена")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(self.viewModel.command, "новая команда")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testSessionSubscription() {
        var session = SwimSession()
        session.isActive = true
        mockService.session = session
        let expectation = self.expectation(description: "isWorkoutActive обновлено через session")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.viewModel.isWorkoutActive)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}

