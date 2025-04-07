//
//  DiaryStartDetailInteractorTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
import CoreData
@testable import Smart_Swim

final class DiaryStartDetailInteractorTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: DiaryStartDetailInteractor!
    
    // MARK: - Test Doubles
    class DiaryStartDetailPresentationLogicSpy: DiaryStartDetailPresentationLogic {
        var presentStartDetailsCalled = false
        var presentRecommendationLoadingCalled = false
        var presentRecommendationReceivedCalled = false
        
        var startDetailsResponse: DiaryStartDetailModels.FetchStartDetails.Response?
        var recommendationLoadingResponse: DiaryStartDetailModels.RecommendationLoading.Response?
        var recommendationReceivedResponse: DiaryStartDetailModels.RecommendationReceived.Response?
        
        func presentStartDetails(response: DiaryStartDetailModels.FetchStartDetails.Response) {
            presentStartDetailsCalled = true
            startDetailsResponse = response
        }
        
        func presentRecommendationLoading(response: DiaryStartDetailModels.RecommendationLoading.Response) {
            presentRecommendationLoadingCalled = true
            recommendationLoadingResponse = response
        }
        
        func presentRecommendationReceived(response: DiaryStartDetailModels.RecommendationReceived.Response) {
            presentRecommendationReceivedCalled = true
            recommendationReceivedResponse = response
        }
    }
    
    class MockCoreDataManager: CoreDataManagerType {
        var fetchStartCalled = false
        var fetchStartsWithCriteriaCalled = false
        var startHasRecommendationCalled = false
        var updateStartRecommendationCalled = false
        
        var mockStart: MockStartEntity?
        var mockStartsForCriteria: [StartEntity] = []
        var hasRecommendation = false
        
        func fetchStart(byID id: NSManagedObjectID) -> StartEntity? {
            fetchStartCalled = true
            return mockStart
        }
        
        func fetchStartsWithCriteria(totalMeters: Int16, swimmingStyle: Int16, poolSize: Int16) -> [StartEntity] {
            fetchStartsWithCriteriaCalled = true
            return mockStartsForCriteria
        }
        
        func startHasRecommendation(_ start: StartEntity) -> Bool {
            startHasRecommendationCalled = true
            return hasRecommendation
        }
        
        func updateStartRecommendation(_ start: StartEntity, recommendation: String) {
            updateStartRecommendationCalled = true
            if let mockStart = start as? MockStartEntity {
                mockStart.recommendation = recommendation
            }
        }
    }
    
    class MockAIStartService: AIStartServiceType {
        var generateRecommendationCalled = false
        var shouldSucceed = true
        var mockRecommendation = "Test recommendation"
        var mockError = DeepSeekError.networkError(NSError(domain: "test", code: 0))
        
        func generateRecommendation(for start: StartEntity, completion: @escaping (Result<String, DeepSeekError>) -> Void) {
            generateRecommendationCalled = true
            
            if shouldSucceed {
                completion(.success(mockRecommendation))
            } else {
                completion(.failure(mockError))
            }
        }
    }
    
    class MockStartEntity: StartEntity {
        var mockDate: Date = Date()
        var mockPoolSize: Int16 = 25
        var mockTotalMeters: Int16 = 50
        var mockSwimmingStyle: Int16 = 0
        var mockTotalTime: Double = 60.0
        var mockRecommendation: String?
        var mockLaps: NSSet?
        var mockObjectID = MockManagedObjectID()
        
        override var date: Date {
            get { return mockDate }
            set { mockDate = newValue }
        }
        
        override var poolSize: Int16 {
            get { return mockPoolSize }
            set { mockPoolSize = newValue }
        }
        
        override var totalMeters: Int16 {
            get { return mockTotalMeters }
            set { mockTotalMeters = newValue }
        }
        
        override var swimmingStyle: Int16 {
            get { return mockSwimmingStyle }
            set { mockSwimmingStyle = newValue }
        }
        
        override var totalTime: Double {
            get { return mockTotalTime }
            set { mockTotalTime = newValue }
        }
        
        override var recommendation: String? {
            get { return mockRecommendation }
            set { mockRecommendation = newValue }
        }
        
        override var laps: NSSet? {
            get { return mockLaps }
            set { mockLaps = newValue }
        }
        
        override var objectID: NSManagedObjectID {
            return mockObjectID
        }
    }
    
    class MockLapEntity: LapEntity {
        var mockLapNumber: Int16 = 1
        var mockLapTime: Double = 30.0
        var mockPulse: Int16 = 150
        var mockStrokes: Int16 = 20
        
        override var lapNumber: Int16 {
            get { return mockLapNumber }
            set { mockLapNumber = newValue }
        }
        
        override var lapTime: Double {
            get { return mockLapTime }
            set { mockLapTime = newValue }
        }
        
        override var pulse: Int16 {
            get { return mockPulse }
            set { mockPulse = newValue }
        }
        
        override var strokes: Int16 {
            get { return mockStrokes }
            set { mockStrokes = newValue }
        }
    }
    
    class MockManagedObjectID: NSManagedObjectID, @unchecked Sendable {
        override func isEqual(_ object: Any?) -> Bool {
            return object is MockManagedObjectID
        }
    }
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Helpers
    private func createMockStart() -> MockStartEntity {
        let mockStart = MockStartEntity()
        let mockLap = MockLapEntity()
        mockStart.mockLaps = NSSet(array: [mockLap])
        return mockStart
    }
    
    // MARK: - Fetch Start Details Tests
    func testFetchStartDetailsWithExistingStart() {
        // Arrange
        let mockCoreDataManager = MockCoreDataManager()
        let mockAIService = MockAIStartService()
        let mockStart = createMockStart()
        
        mockCoreDataManager.mockStart = mockStart
        mockCoreDataManager.mockStartsForCriteria = [mockStart]
        mockCoreDataManager.hasRecommendation = true
        
        sut = DiaryStartDetailInteractor(
            coreDataManager: mockCoreDataManager,
            aiStartService: mockAIService
        )
        
        let spy = DiaryStartDetailPresentationLogicSpy()
        sut.presenter = spy
        let mockStartID = MockManagedObjectID()
        
        // Act
        let request = DiaryStartDetailModels.FetchStartDetails.Request(startID: mockStartID)
        sut.fetchStartDetails(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentStartDetailsCalled)
        XCTAssertTrue(mockCoreDataManager.fetchStartCalled)
        XCTAssertTrue(mockCoreDataManager.fetchStartsWithCriteriaCalled)
        XCTAssertTrue(mockCoreDataManager.startHasRecommendationCalled)
        
        // Verify response data
        XCTAssertEqual(spy.startDetailsResponse?.totalMeters, 50)
        XCTAssertEqual(spy.startDetailsResponse?.poolSize, 25)
        XCTAssertEqual(spy.startDetailsResponse?.swimmingStyle, 0)
        XCTAssertEqual(spy.startDetailsResponse?.totalTime, 60.0)
        XCTAssertEqual(spy.startDetailsResponse?.laps.count, 1)
        XCTAssertEqual(spy.startDetailsResponse?.laps.first?.lapNumber, 1)
    }
    
    func testFetchStartDetailsWithNoStart() {
        // Arrange
        let mockCoreDataManager = MockCoreDataManager()
        let mockAIService = MockAIStartService()
        mockCoreDataManager.mockStart = nil
        
        sut = DiaryStartDetailInteractor(
            coreDataManager: mockCoreDataManager,
            aiStartService: mockAIService
        )
        
        let spy = DiaryStartDetailPresentationLogicSpy()
        sut.presenter = spy
        let mockStartID = MockManagedObjectID()
        
        // Act
        let request = DiaryStartDetailModels.FetchStartDetails.Request(startID: mockStartID)
        sut.fetchStartDetails(request: request)
        
        // Assert
        XCTAssertFalse(spy.presentStartDetailsCalled)
        XCTAssertTrue(mockCoreDataManager.fetchStartCalled)
    }
    
    func testFetchStartDetailsWithNoLaps() {
        // Arrange
        let mockCoreDataManager = MockCoreDataManager()
        let mockAIService = MockAIStartService()
        let mockStart = MockStartEntity()
        mockStart.mockLaps = nil
        mockCoreDataManager.mockStart = mockStart
        
        sut = DiaryStartDetailInteractor(
            coreDataManager: mockCoreDataManager,
            aiStartService: mockAIService
        )
        
        let spy = DiaryStartDetailPresentationLogicSpy()
        sut.presenter = spy
        let mockStartID = MockManagedObjectID()
        
        // Act
        let request = DiaryStartDetailModels.FetchStartDetails.Request(startID: mockStartID)
        sut.fetchStartDetails(request: request)
        
        // Assert
        XCTAssertFalse(spy.presentStartDetailsCalled)
        XCTAssertTrue(mockCoreDataManager.fetchStartCalled)
    }
    
    func testFetchStartDetailsStartsRecommendationLoadingWhenNoRecommendation() {
        // Arrange
        let mockCoreDataManager = MockCoreDataManager()
        let mockAIService = MockAIStartService()
        let mockStart = createMockStart()
        
        mockCoreDataManager.mockStart = mockStart
        mockCoreDataManager.mockStartsForCriteria = [mockStart]
        mockCoreDataManager.hasRecommendation = false
        
        sut = DiaryStartDetailInteractor(
            coreDataManager: mockCoreDataManager,
            aiStartService: mockAIService
        )
        
        let spy = DiaryStartDetailPresentationLogicSpy()
        sut.presenter = spy
        let mockStartID = MockManagedObjectID()
        
        // Act
        let request = DiaryStartDetailModels.FetchStartDetails.Request(startID: mockStartID)
        sut.fetchStartDetails(request: request)
        let expectation = self.expectation(description: "Wait for async call")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertTrue(spy.presentStartDetailsCalled)
        XCTAssertTrue(spy.presentRecommendationLoadingCalled)
        XCTAssertTrue(mockAIService.generateRecommendationCalled)
    }
    
    // MARK: - Load Recommendation Tests
    func testLoadRecommendationSuccess() {
        // Arrange
        let mockCoreDataManager = MockCoreDataManager()
        let mockAIService = MockAIStartService()
        let mockStart = createMockStart()
        mockAIService.shouldSucceed = true
        mockAIService.mockRecommendation = "Great swimming!"
        
        sut = DiaryStartDetailInteractor(
            coreDataManager: mockCoreDataManager,
            aiStartService: mockAIService
        )
        
        let spy = DiaryStartDetailPresentationLogicSpy()
        sut.presenter = spy
        let mockStartID = MockManagedObjectID()
        
        // Act
        sut.loadRecommendation(for: mockStart, startID: mockStartID)
        
        let expectation = self.expectation(description: "Wait for async call")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertTrue(spy.presentRecommendationLoadingCalled)
        XCTAssertTrue(spy.presentRecommendationReceivedCalled)
        XCTAssertTrue(mockAIService.generateRecommendationCalled)
        XCTAssertTrue(mockCoreDataManager.updateStartRecommendationCalled)
        XCTAssertEqual(spy.recommendationReceivedResponse?.recommendationText, "Great swimming!")
    }
    
    func testLoadRecommendationFailure() {
        // Arrange
        let mockCoreDataManager = MockCoreDataManager()
        let mockAIService = MockAIStartService()
        let mockStart = createMockStart()
        mockAIService.shouldSucceed = false
        
        sut = DiaryStartDetailInteractor(
            coreDataManager: mockCoreDataManager,
            aiStartService: mockAIService
        )
        
        let spy = DiaryStartDetailPresentationLogicSpy()
        sut.presenter = spy
        let mockStartID = MockManagedObjectID()
        
        // Act
        sut.loadRecommendation(for: mockStart, startID: mockStartID)
        
        let expectation = self.expectation(description: "Wait for async call")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertTrue(spy.presentRecommendationLoadingCalled)
        XCTAssertTrue(spy.presentRecommendationReceivedCalled)
        XCTAssertTrue(mockAIService.generateRecommendationCalled)
        XCTAssertFalse(mockCoreDataManager.updateStartRecommendationCalled)
        XCTAssertTrue(spy.recommendationReceivedResponse?.recommendationText.contains("Не удалось получить рекомендацию") ?? false)
    }
}
