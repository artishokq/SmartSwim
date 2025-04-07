//
//  StartIntegrationTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
@testable import Smart_Swim

final class StartIntegrationTests: XCTestCase {
    // MARK: - Properties
    var interactor: StartInteractor!
    var presenter: StartPresenter!
    var mockViewController: MockStartViewController!
    
    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        
        interactor = StartInteractor()
        presenter = StartPresenter()
        mockViewController = MockStartViewController()
        
        interactor.presenter = presenter
        presenter.viewController = mockViewController
    }
    
    override func tearDown() {
        interactor = nil
        presenter = nil
        mockViewController = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testContinueActionVIPCycle() {
        // Arrange
        let request = StartModels.Continue.Request(
            totalMeters: 1000,
            poolSize: 25,
            swimmingStyle: "freestyle"
        )
        
        // Act
        interactor.continueAction(request: request)
        
        // Assert
        XCTAssertTrue(mockViewController.displayContinueCalled)
        XCTAssertNotNil(mockViewController.lastViewModel)
        XCTAssertEqual(interactor.totalMeters, 1000)
        XCTAssertEqual(interactor.poolSize, 25)
        XCTAssertEqual(interactor.swimmingStyle, "freestyle")
    }
    
    func testDataStorePersistenceInVIPCycle() {
        // Arrange
        interactor.totalMeters = 800
        interactor.poolSize = 50
        interactor.swimmingStyle = "butterfly"
        
        // Act
        interactor.continueAction(request: StartModels.Continue.Request(
            totalMeters: interactor.totalMeters!,
            poolSize: interactor.poolSize!,
            swimmingStyle: interactor.swimmingStyle!
        ))
        
        // Assert
        XCTAssertTrue(mockViewController.displayContinueCalled)
        XCTAssertEqual(interactor.totalMeters, 800)
        XCTAssertEqual(interactor.poolSize, 50)
        XCTAssertEqual(interactor.swimmingStyle, "butterfly")
    }
}

// MARK: - Mock Classes
extension StartIntegrationTests {
    class MockStartViewController: StartDisplayLogic {
        var displayContinueCalled = false
        var lastViewModel: StartModels.Continue.ViewModel?
        
        func displayContinue(viewModel: StartModels.Continue.ViewModel) {
            displayContinueCalled = true
            lastViewModel = viewModel
        }
    }
}
