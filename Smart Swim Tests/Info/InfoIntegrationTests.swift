//
//  InfoIntegrationTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
import YandexMapsMobile
@testable import Smart_Swim

final class InfoIntegrationTests: XCTestCase {
    // MARK: - Properties
    var viewController: InfoViewController!
    var interactor: InfoInteractor!
    var presenter: InfoPresenter!
    var router: InfoRouter!
    
    var mockLocationWorker: MockLocationWorker!
    var mockPoolSearchWorker: MockPoolSearchWorker!
    
    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        
        mockLocationWorker = MockLocationWorker()
        mockPoolSearchWorker = MockPoolSearchWorker()
        
        viewController = InfoViewController()
        interactor = InfoInteractor(
            poolSearchWorker: mockPoolSearchWorker,
            locationWorker: mockLocationWorker
        )
        presenter = InfoPresenter()
        router = InfoRouter()
        
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
    }
    
    override func tearDown() {
        viewController = nil
        interactor = nil
        presenter = nil
        router = nil
        mockLocationWorker = nil
        mockPoolSearchWorker = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testSuccessfulPoolSearch() {
        // Arrange
        let userLocation = Location(latitude: 55.7558, longitude: 37.6173)
        let pools = [
            PoolLocation(id: "pool-1", name: "Pool 1", address: "Address 1", latitude: 55.76, longitude: 37.62),
            PoolLocation(id: "pool-2", name: "Pool 2", address: "Address 2", latitude: 55.77, longitude: 37.63)
        ]
        
        mockLocationWorker.mockLocationResult = .success(userLocation)
        mockPoolSearchWorker.mockSearchResult = .success(pools)
        
        let spyViewController = InfoViewControllerSpy()
        presenter.viewController = spyViewController
        
        let expectation = XCTestExpectation(description: "Display pools called")
        spyViewController.onDisplayPoolsCalled = { _ in
            expectation.fulfill()
        }
        
        // Act
        interactor.getPools(request: InfoModels.GetPools.Request())
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(spyViewController.displayPoolsCalled)
        XCTAssertEqual(spyViewController.lastViewModel?.pools.count, 2)
        XCTAssertEqual(spyViewController.lastViewModel?.userLocation.latitude, userLocation.latitude)
        XCTAssertEqual(spyViewController.lastViewModel?.userLocation.longitude, userLocation.longitude)
        XCTAssertEqual(spyViewController.lastViewModel?.pools[0].id, "pool-1")
        XCTAssertEqual(spyViewController.lastViewModel?.pools[0].name, "Pool 1")
        XCTAssertEqual(spyViewController.lastViewModel?.pools[0].address, "Address 1")
        XCTAssertEqual(spyViewController.lastViewModel?.pools[0].coordinate.latitude, 55.76)
        XCTAssertEqual(spyViewController.lastViewModel?.pools[0].coordinate.longitude, 37.62)
    }
    
    func testLocationErrorFallbackToDefault() {
        // Arrange
        let defaultLocation = Location(latitude: 55.7558, longitude: 37.6173)
        let pools = [
            PoolLocation(id: "pool-1", name: "Pool 1", address: "Address 1", latitude: 55.76, longitude: 37.62)
        ]
        
        mockLocationWorker.mockLocationResult = .failure(.locationServicesDisabled)
        mockLocationWorker.mockDefaultLocation = defaultLocation
        mockPoolSearchWorker.mockSearchResult = .success(pools)
        
        let spyViewController = InfoViewControllerSpy()
        presenter.viewController = spyViewController
        
        let expectation = XCTestExpectation(description: "Display pools called with default location")
        spyViewController.onDisplayPoolsCalled = { _ in
            expectation.fulfill()
        }
        
        // Act
        interactor.getPools(request: InfoModels.GetPools.Request())
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(spyViewController.displayPoolsCalled)
        XCTAssertEqual(spyViewController.lastViewModel?.pools.count, 1)
        XCTAssertEqual(spyViewController.lastViewModel?.userLocation.latitude, defaultLocation.latitude)
        XCTAssertEqual(spyViewController.lastViewModel?.userLocation.longitude, defaultLocation.longitude)
    }
    
    func testPoolSearchError() {
        // Arrange
        let userLocation = Location(latitude: 55.7558, longitude: 37.6173)
        let searchError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Search failed"])
        
        mockLocationWorker.mockLocationResult = .success(userLocation)
        mockPoolSearchWorker.mockSearchResult = .failure(searchError)
        
        let spyViewController = InfoViewControllerSpy()
        presenter.viewController = spyViewController
        let expectation = XCTestExpectation(description: "Display error called")
        spyViewController.onDisplayErrorCalled = { _ in
            expectation.fulfill()
        }
        
        // Act
        interactor.getPools(request: InfoModels.GetPools.Request())
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(spyViewController.displayErrorCalled)
        XCTAssertTrue(spyViewController.lastErrorMessage?.contains("Search failed") ?? false)
    }
}

// MARK: - Helper Classes
class InfoViewControllerSpy: InfoDisplayLogic {
    var displayPoolsCalled = false
    var lastViewModel: InfoModels.GetPools.ViewModel?
    var onDisplayPoolsCalled: ((InfoModels.GetPools.ViewModel) -> Void)?
    
    var displayErrorCalled = false
    var lastErrorMessage: String?
    var onDisplayErrorCalled: ((String) -> Void)?
    
    func displayPools(viewModel: InfoModels.GetPools.ViewModel) {
        displayPoolsCalled = true
        lastViewModel = viewModel
        onDisplayPoolsCalled?(viewModel)
    }
    
    func displayError(message: String) {
        displayErrorCalled = true
        lastErrorMessage = message
        onDisplayErrorCalled?(message)
    }
}
