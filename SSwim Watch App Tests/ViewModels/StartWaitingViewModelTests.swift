//
//  StartWaitingViewModelTests.swift
//  SSwim Watch App Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
@testable import SSwim_Watch_App
class MockStartServiceForWaiting: StartService {
    var resetParametersCalled = false
    var resetCommandCalled = false

    override func resetParameters() {
        resetParametersCalled = true
    }
    
    override func resetCommand() {
        resetCommandCalled = true
        self.command = ""
    }
    
    override func resetAndRequestParameters() {
        self.isReadyToStart = true
        self.command = "начать"
    }
}

final class StartWaitingViewModelTests: XCTestCase {
    var viewModel: StartWaitingViewModel!
    var mockService: MockStartServiceForWaiting!

    override func setUp() {
        super.setUp()
        viewModel = StartWaitingViewModel()
        let dummyComm = DummyCommunicationService()
        let dummyStartKit = StartKit(communicationService: dummyComm, workoutKitManager: WorkoutKitManager.shared)
        mockService = MockStartServiceForWaiting(startKit: dummyStartKit, workoutKitManager: WorkoutKitManager.shared)
        viewModel.setupWithService(startService: mockService)
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        super.tearDown()
    }

    func testRequestParameters() {
        viewModel.requestParameters(startService: mockService)
        XCTAssertTrue(viewModel.isReadyToStart)
        XCTAssertEqual(viewModel.command, "")
    }

    func testResetParameters() {
        viewModel.resetParameters(startService: mockService)
        XCTAssertFalse(viewModel.isReadyToStart)
        XCTAssertTrue(mockService.resetParametersCalled, "Метод resetParameters стартового сервиса должен быть вызван")
    }

    func testResetCommand() {
        viewModel.command = "какая-то команда"
        viewModel.resetCommand()
        XCTAssertEqual(viewModel.command, "")
        XCTAssertTrue(mockService.resetCommandCalled)
    }

    func testIsReadySubscription() {
        mockService.isReadyToStart = true
        let expectation = self.expectation(description: "isReadyToStart обновлено через подписку")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.viewModel.isReadyToStart)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }
}
