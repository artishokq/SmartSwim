//
//  StartInteractorTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
@testable import Smart_Swim

final class StartInteractorTests: XCTestCase {
    // MARK: - Properties
    var sut: StartInteractor!
    var mockPresenter: MockStartPresenter!
    
    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        
        sut = StartInteractor()
        mockPresenter = MockStartPresenter()
        sut.presenter = mockPresenter
    }
    
    override func tearDown() {
        sut = nil
        mockPresenter = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testContinueAction() {
        // Arrange
        let request = StartModels.Continue.Request(
            totalMeters: 1000,
            poolSize: 25,
            swimmingStyle: "freestyle"
        )
        
        // Act
        sut.continueAction(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentContinueCalled)
        XCTAssertEqual(sut.totalMeters, 1000)
        XCTAssertEqual(sut.poolSize, 25)
        XCTAssertEqual(sut.swimmingStyle, "freestyle")
    }
    
    func testContinueActionWithZeroValues() {
        // Arrange
        let request = StartModels.Continue.Request(
            totalMeters: 0,
            poolSize: 0,
            swimmingStyle: ""
        )
        
        // Act
        sut.continueAction(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentContinueCalled)
        XCTAssertEqual(sut.totalMeters, 0)
        XCTAssertEqual(sut.poolSize, 0)
        XCTAssertEqual(sut.swimmingStyle, "")
    }
    
    func testContinueActionWithMaxValues() {
        // Arrange
        let request = StartModels.Continue.Request(
            totalMeters: Int.max,
            poolSize: Int.max,
            swimmingStyle: String(repeating: "a", count: 1000)
        )
        
        // Act
        sut.continueAction(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentContinueCalled)
        XCTAssertEqual(sut.totalMeters, Int.max)
        XCTAssertEqual(sut.poolSize, Int.max)
        XCTAssertEqual(sut.swimmingStyle, String(repeating: "a", count: 1000))
    }
    
    func testDataStoreRetainsValues() {
        // Arrange
        sut.totalMeters = 500
        sut.poolSize = 50
        sut.swimmingStyle = "backstroke"
        
        let dataStore: StartDataStore = sut
        
        // Assert
        XCTAssertEqual(dataStore.totalMeters, 500)
        XCTAssertEqual(dataStore.poolSize, 50)
        XCTAssertEqual(dataStore.swimmingStyle, "backstroke")
    }
}

// MARK: - Mock Classes
class MockStartPresenter: StartPresentationLogic {
    var presentContinueCalled = false
    var lastResponse: StartModels.Continue.Response?
    
    func presentContinue(response: StartModels.Continue.Response) {
        presentContinueCalled = true
        lastResponse = response
    }
}
