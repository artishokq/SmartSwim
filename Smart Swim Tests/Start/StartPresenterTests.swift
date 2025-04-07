//
//  StartPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
@testable import Smart_Swim

final class StartPresenterTests: XCTestCase {
    
    // MARK: - Properties
    var sut: StartPresenter!
    var mockViewController: MockStartViewController!
    
    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        
        sut = StartPresenter()
        mockViewController = MockStartViewController()
        sut.viewController = mockViewController
    }
    
    override func tearDown() {
        sut = nil
        mockViewController = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testPresentContinue() {
        // Arrange
        let response = StartModels.Continue.Response()
        
        // Act
        sut.presentContinue(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayContinueCalled)
        XCTAssertNotNil(mockViewController.lastViewModel)
    }
    
    func testPresentContinueWithEmptyResponse() {
        // Arrange
        let response = StartModels.Continue.Response()
        
        // Act
        sut.presentContinue(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayContinueCalled)
        XCTAssertNotNil(mockViewController.lastViewModel)
    }
    
    func testViewControllerReferenceIsWeak() {
        // Arrange
        var viewController: MockStartViewController? = MockStartViewController()
        sut.viewController = viewController
        
        // Act
        weak var weakViewController = viewController
        viewController = nil
        
        // Assert
        XCTAssertNil(weakViewController)
        
        let response = StartModels.Continue.Response()
        sut.presentContinue(response: response)
    }
}

// MARK: - Mock Classes
class MockStartViewController: StartDisplayLogic {
    var displayContinueCalled = false
    var lastViewModel: StartModels.Continue.ViewModel?
    
    func displayContinue(viewModel: StartModels.Continue.ViewModel) {
        displayContinueCalled = true
        lastViewModel = viewModel
    }
}
