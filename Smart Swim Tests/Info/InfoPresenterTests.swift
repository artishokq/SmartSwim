//
//  InfoPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
@testable import Smart_Swim

final class InfoPresenterTests: XCTestCase {
    // MARK: - Properties
    var sut: InfoPresenter!
    var mockViewController: MockInfoViewController!
    
    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        
        sut = InfoPresenter()
        mockViewController = MockInfoViewController()
        sut.viewController = mockViewController
    }
    
    override func tearDown() {
        sut = nil
        mockViewController = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testPresentPools() {
        // Arrange
        let pools = [createMockPool()]
        let userLocation = (latitude: 55.7558, longitude: 37.6173)
        
        let response = InfoModels.GetPools.Response(
            pools: pools,
            userLocation: userLocation
        )
        
        // Act
        sut.presentPools(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayPoolsCalled)
        XCTAssertEqual(mockViewController.displayPoolsViewModel?.pools.count, 1)
        XCTAssertEqual(mockViewController.displayPoolsViewModel?.userLocation.latitude, userLocation.latitude)
        XCTAssertEqual(mockViewController.displayPoolsViewModel?.userLocation.longitude, userLocation.longitude)
        let poolVM = mockViewController.displayPoolsViewModel?.pools.first
        XCTAssertEqual(poolVM?.id, "test-id")
        XCTAssertEqual(poolVM?.name, "Test Pool")
        XCTAssertEqual(poolVM?.address, "Test Address")
        XCTAssertEqual(poolVM?.coordinate.latitude, 55.7558)
        XCTAssertEqual(poolVM?.coordinate.longitude, 37.6173)
    }
    
    func testPresentErrorMessage() {
        // Arrange
        let errorMessage = "Test error message"
        
        // Act
        sut.presentError(message: errorMessage)
        
        // Assert
        XCTAssertTrue(mockViewController.displayErrorCalled)
        XCTAssertEqual(mockViewController.displayErrorMessage, errorMessage)
    }
    
    func testPresentEmptyPools() {
        // Arrange
        let pools: [PoolLocation] = []
        let userLocation = (latitude: 55.7558, longitude: 37.6173)
        
        let response = InfoModels.GetPools.Response(
            pools: pools,
            userLocation: userLocation
        )
        
        // Act
        sut.presentPools(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayPoolsCalled)
        XCTAssertEqual(mockViewController.displayPoolsViewModel?.pools.count, 0)
    }
    
    func testPresentMultiplePools() {
        // Arrange
        let pools = [
            createMockPool(id: "pool-1", name: "Pool 1"),
            createMockPool(id: "pool-2", name: "Pool 2"),
            createMockPool(id: "pool-3", name: "Pool 3")
        ]
        let userLocation = (latitude: 55.7558, longitude: 37.6173)
        
        let response = InfoModels.GetPools.Response(
            pools: pools,
            userLocation: userLocation
        )
        
        // Act
        sut.presentPools(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayPoolsCalled)
        XCTAssertEqual(mockViewController.displayPoolsViewModel?.pools.count, 3)
        XCTAssertEqual(mockViewController.displayPoolsViewModel?.pools[0].name, "Pool 1")
        XCTAssertEqual(mockViewController.displayPoolsViewModel?.pools[1].name, "Pool 2")
        XCTAssertEqual(mockViewController.displayPoolsViewModel?.pools[2].name, "Pool 3")
    }
    
    // MARK: - Helper Methods
    private func createMockPool(id: String = "test-id", name: String = "Test Pool") -> PoolLocation {
        return PoolLocation(
            id: id,
            name: name,
            address: "Test Address",
            latitude: 55.7558,
            longitude: 37.6173
        )
    }
}

// MARK: - Mock Classes
class MockInfoViewController: InfoDisplayLogic {
    var displayPoolsCalled = false
    var displayPoolsViewModel: InfoModels.GetPools.ViewModel?
    
    var displayErrorCalled = false
    var displayErrorMessage: String?
    
    func displayPools(viewModel: InfoModels.GetPools.ViewModel) {
        displayPoolsCalled = true
        displayPoolsViewModel = viewModel
    }
    
    func displayError(message: String) {
        displayErrorCalled = true
        displayErrorMessage = message
    }
}
