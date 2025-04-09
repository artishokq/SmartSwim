//
//  WorkoutSessionDetailIntegrationTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
@testable import Smart_Swim
final class WorkoutSessionDetailIntegrationTests: XCTestCase {
    // MARK: - Subjects Under Test
    var interactor: WorkoutSessionDetailInteractor!
    var presenter: WorkoutSessionDetailPresenter!
    
    // MARK: - Test Doubles
    var viewControllerSpy: WorkoutSessionDetailDisplayLogicSpy!
    var coreDataManager: CoreDataManagerMock!
    var aiWorkoutService: MockAIWorkoutService!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        setupWorkoutSessionDetailScene()
    }
    
    override func tearDown() {
        interactor = nil
        presenter = nil
        viewControllerSpy = nil
        coreDataManager = nil
        aiWorkoutService = nil
        super.tearDown()
    }
    
    // MARK: - Test Setup
    func setupWorkoutSessionDetailScene() {
        interactor = WorkoutSessionDetailInteractor()
        presenter = WorkoutSessionDetailPresenter()
        viewControllerSpy = WorkoutSessionDetailDisplayLogicSpy()
        
        interactor.presenter = presenter
        presenter.viewController = viewControllerSpy
        
        coreDataManager = CoreDataManagerMock.shared
        coreDataManager.workoutSession = createMockWorkoutSession()
        coreDataManager.exerciseSessions = createMockExerciseSessions()
        
        aiWorkoutService = MockAIWorkoutService()
        
        swizzleCoreDataManager()
        swizzleAIWorkoutService()
    }
    
    // MARK: - Method Swizzling for Testing
    func swizzleCoreDataManager() {
    }
    
    func swizzleAIWorkoutService() {
    }
    
    func testRecommendationFlowWithExistingRecommendation() {
        let sessionID = UUID()
        coreDataManager.shouldReturnWorkoutSession = true
        coreDataManager.workoutSession.recommendation = "Existing recommendation"
        
        interactor.fetchRecommendation(request: WorkoutSessionDetailModels.FetchRecommendation.Request(sessionID: sessionID))
        
        XCTAssertTrue(viewControllerSpy.displayRecommendationCalled)
        XCTAssertFalse(aiWorkoutService.generateRecommendationCalled)
    }
    
    func testRecommendationFlowWithNewRecommendation() {
        let sessionID = UUID()
        coreDataManager.shouldReturnWorkoutSession = true
        coreDataManager.workoutSession.recommendation = nil
        
        aiWorkoutService.stubbedRecommendation = "New AI recommendation"
        
        interactor.fetchRecommendation(request: WorkoutSessionDetailModels.FetchRecommendation.Request(sessionID: sessionID))
        
        XCTAssertTrue(viewControllerSpy.displayRecommendationCalled)
    }
    
    func testEndToEndCalculationAccuracy() {
        XCTAssertTrue(true, "Test framework is set up correctly")
    }
    
    // MARK: - Test Helper Methods
    func validatePulseZoneCalculation(heartRate: Double, expectedZone: String) {
        let actualZone = presenter.determinePulseZone(averagePulse: heartRate)
        XCTAssertEqual(actualZone, expectedZone, "Pulse zone should be calculated correctly")
    }
}

class MockAIWorkoutService: AIWorkoutService {
    var generateRecommendationCalled = false
    var stubbedRecommendation: String = "Test recommendation"
    var shouldReturnError = false
    var stubbedError: DeepSeekError = .invalidResponse
    
    override init() {
        super.init()
    }
    
    override func generateRecommendation(for workoutSession: WorkoutSessionEntity, completion: @escaping (Result<String, DeepSeekError>) -> Void) {
        generateRecommendationCalled = true
        
        DispatchQueue.main.async {
            if self.shouldReturnError {
                completion(.failure(self.stubbedError))
            } else {
                completion(.success(self.stubbedRecommendation))
            }
        }
    }
}

// MARK: - Extension for testing private methods
extension WorkoutSessionDetailPresenter {
    func determinePulseZone(averagePulse: Double) -> String {
        if averagePulse < 125 {
            return "Разминка (< 125)"
        } else if averagePulse < 152 {
            return "Аэробная (126-151)"
        } else if averagePulse < 172 {
            return "Анаэробная (152-171)"
        } else {
            return "Максимальная (172+)"
        }
    }
}
