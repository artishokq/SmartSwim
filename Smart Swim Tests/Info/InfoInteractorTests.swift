//
//  InfoInteractorTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
import YandexMapsMobile
@testable import Smart_Swim

final class InfoInteractorTests: XCTestCase {
    // MARK: - Properties
    var sut: InfoInteractor!
    var mockLocationWorker: MockLocationWorker!
    var mockPoolSearchWorker: MockPoolSearchWorker!
    var mockPresenter: MockInfoPresenter!
    
    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        
        mockLocationWorker = MockLocationWorker()
        mockPoolSearchWorker = MockPoolSearchWorker()
        mockPresenter = MockInfoPresenter()
        
        sut = InfoInteractor(
            poolSearchWorker: mockPoolSearchWorker,
            locationWorker: mockLocationWorker
        )
        sut.presenter = mockPresenter
    }
    
    override func tearDown() {
        sut = nil
        mockLocationWorker = nil
        mockPoolSearchWorker = nil
        mockPresenter = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func testGetPoolsSuccessPath() {
        // Arrange
        let userLocation = Location(latitude: 55.7558, longitude: 37.6173)
        let pools = [createMockPool()]
        
        mockLocationWorker.mockLocationResult = .success(userLocation)
        mockPoolSearchWorker.mockSearchResult = .success(pools)
        
        let expectation = XCTestExpectation(description: "Present pools called")
        mockPresenter.onPresentPoolsCalled = { _ in
            expectation.fulfill()
        }
        
        // Act
        sut.getPools(request: InfoModels.GetPools.Request())
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockPresenter.presentPoolsCalled)
        XCTAssertEqual(mockPresenter.presentPoolsResponse?.pools.count, 1)
        XCTAssertEqual(mockPresenter.presentPoolsResponse?.userLocation.latitude, userLocation.latitude)
        XCTAssertEqual(mockPresenter.presentPoolsResponse?.userLocation.longitude, userLocation.longitude)
    }
    
    func testGetPoolsLocationFailureFallbackToDefault() {
        // Arrange
        let defaultLocation = Location(latitude: 55.7558, longitude: 37.6173)
        let pools = [createMockPool()]
        
        mockLocationWorker.mockLocationResult = .failure(.locationServicesDisabled)
        mockLocationWorker.mockDefaultLocation = defaultLocation
        mockPoolSearchWorker.mockSearchResult = .success(pools)
        
        let expectation = XCTestExpectation(description: "Present pools called with default location")
        mockPresenter.onPresentPoolsCalled = { _ in
            expectation.fulfill()
        }
        
        // Act
        sut.getPools(request: InfoModels.GetPools.Request())
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockPresenter.presentPoolsCalled)
        XCTAssertEqual(mockPresenter.presentPoolsResponse?.pools.count, 1)
        XCTAssertEqual(mockPresenter.presentPoolsResponse?.userLocation.latitude, defaultLocation.latitude)
        XCTAssertEqual(mockPresenter.presentPoolsResponse?.userLocation.longitude, defaultLocation.longitude)
    }
    
    func testGetPoolsSearchFailure() {
        // Arrange
        let userLocation = Location(latitude: 55.7558, longitude: 37.6173)
        let searchError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Search failed"])
        
        mockLocationWorker.mockLocationResult = .success(userLocation)
        mockPoolSearchWorker.mockSearchResult = .failure(searchError)
        
        let expectation = XCTestExpectation(description: "Present error called")
        mockPresenter.onPresentErrorCalled = { _ in
            expectation.fulfill()
        }
        
        // Act
        sut.getPools(request: InfoModels.GetPools.Request())
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockPresenter.presentErrorCalled)
        XCTAssertTrue(mockPresenter.presentErrorMessage?.contains("Search failed") ?? false)
    }
    
    func testGetPoolsLocationFailureAndSearchFailure() {
        // Arrange
        let defaultLocation = Location(latitude: 55.7558, longitude: 37.6173)
        let searchError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Search failed"])
        
        mockLocationWorker.mockLocationResult = .failure(.locationServicesDisabled)
        mockLocationWorker.mockDefaultLocation = defaultLocation
        mockPoolSearchWorker.mockSearchResult = .failure(searchError)
        
        let expectation = XCTestExpectation(description: "Present error called after location failure")
        mockPresenter.onPresentErrorCalled = { _ in
            expectation.fulfill()
        }
        
        // Act
        sut.getPools(request: InfoModels.GetPools.Request())
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(mockPresenter.presentErrorCalled)
        XCTAssertTrue(mockPresenter.presentErrorMessage?.contains("Search failed") ?? false)
    }
    
    // MARK: - Helper Methods
    private func createMockPool() -> PoolLocation {
        return PoolLocation(
            id: "test-id",
            name: "Test Pool",
            address: "Test Address",
            latitude: 55.7558,
            longitude: 37.6173
        )
    }
}

// MARK: - Mock Classes
class MockLocationWorker: LocationWorkerProtocol {
    var mockLocationResult: Result<Location, LocationError>?
    var mockDefaultLocation: Location = Location(latitude: 55.7558, longitude: 37.6173)
    var getCurrentLocationCalled = false
    
    func getCurrentLocation(completion: @escaping (Result<Location, LocationError>) -> Void) {
        getCurrentLocationCalled = true
        if let result = mockLocationResult {
            completion(result)
        }
    }
    
    func getDefaultLocation() -> Location {
        return mockDefaultLocation
    }
}

class MockPoolSearchWorker: PoolSearchWorkerProtocol {
    var mockSearchResult: Result<[PoolLocation], Error>?
    var searchPoolsCalled = false
    var lastSearchLocation: Location?
    var lastSearchRegion: YMKVisibleRegion?
    
    func searchPools(near location: Location, in region: YMKVisibleRegion, completion: @escaping (Result<[PoolLocation], Error>) -> Void) {
        searchPoolsCalled = true
        lastSearchLocation = location
        lastSearchRegion = region
        
        if let result = mockSearchResult {
            completion(result)
        }
    }
}

class MockInfoPresenter: InfoPresentationLogic {
    var presentPoolsCalled = false
    var presentPoolsResponse: InfoModels.GetPools.Response?
    var onPresentPoolsCalled: ((InfoModels.GetPools.Response) -> Void)?
    
    var presentErrorCalled = false
    var presentErrorMessage: String?
    var onPresentErrorCalled: ((String) -> Void)?
    
    func presentPools(response: InfoModels.GetPools.Response) {
        presentPoolsCalled = true
        presentPoolsResponse = response
        onPresentPoolsCalled?(response)
    }
    
    func presentError(message: String) {
        presentErrorCalled = true
        presentErrorMessage = message
        onPresentErrorCalled?(message)
    }
}
