//
//  DiaryStartDetailIntegrationTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
import CoreData
@testable import Smart_Swim

final class DiaryStartDetailIntegrationTests: XCTestCase {
    // MARK: - Properties
    var viewController: DiaryStartDetailViewController!
    var interactor: DiaryStartDetailInteractor!
    var presenter: DiaryStartDetailPresenter!
    var router: DiaryStartDetailRouter!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureDiaryStartDetailScene()
    }
    
    override func tearDown() {
        viewController = nil
        interactor = nil
        presenter = nil
        router = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureDiaryStartDetailScene() {
        viewController = DiaryStartDetailViewController()
        interactor = DiaryStartDetailInteractor()
        presenter = DiaryStartDetailPresenter()
        router = DiaryStartDetailRouter()
        
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    // MARK: - Integration Tests
    
    func testFetchStartDetailsToDisplayFlow() {
        // Arrange
        let mockStartID = NSManagedObjectID()
        interactor.startID = mockStartID
        
        let spyViewController = DiaryStartDetailDisplayLogicSpy()
        presenter.viewController = spyViewController
        
        let lap = DiaryStartDetailModels.FetchStartDetails.Response.LapData(
            lapNumber: 1,
            lapTime: 30.0,
            pulse: 150,
            strokes: 20
        )
        
        let response = DiaryStartDetailModels.FetchStartDetails.Response(
            date: Date(),
            poolSize: 25,
            totalMeters: 50,
            swimmingStyle: 0,
            totalTime: 60.0,
            laps: [lap],
            bestTime: 60.0,
            bestTimeDate: Date(),
            isCurrentBest: true,
            hasRecommendation: true,
            recommendationText: "Great swimming!",
            isLoadingRecommendation: false
        )
        
        // Act
        presenter.presentStartDetails(response: response)
        
        // Assert
        XCTAssertTrue(spyViewController.displayStartDetailsCalled)
        XCTAssertNotNil(spyViewController.startDetailsViewModel)
        
        let viewModel = spyViewController.startDetailsViewModel
        XCTAssertEqual(viewModel?.headerInfo.totalTime, "01:00,00")
        XCTAssertEqual(viewModel?.lapDetails.count, 1)
        XCTAssertEqual(viewModel?.lapDetails.first?.time, "00:30,00")
        XCTAssertEqual(viewModel?.recommendationText, "Great swimming!")
    }
    
    func testRecommendationLoadingToDisplayFlow() {
        // Arrange
        let spyViewController = DiaryStartDetailDisplayLogicSpy()
        presenter.viewController = spyViewController
        
        // Act
        let loadingResponse = DiaryStartDetailModels.RecommendationLoading.Response(isLoading: true)
        presenter.presentRecommendationLoading(response: loadingResponse)
        
        // Assert
        XCTAssertTrue(spyViewController.displayRecommendationLoadingCalled)
        XCTAssertTrue(spyViewController.recommendationLoadingViewModel?.isLoading ?? false)
        
        // Act
        let recommendationResponse = DiaryStartDetailModels.RecommendationReceived.Response(
            recommendationText: "Your technique is improving!",
            startID: NSManagedObjectID()
        )
        presenter.presentRecommendationReceived(response: recommendationResponse)
        
        // Assert
        XCTAssertTrue(spyViewController.displayRecommendationReceivedCalled)
        XCTAssertEqual(spyViewController.recommendationReceivedViewModel?.recommendationText,
                       "Your technique is improving!")
    }
}

// MARK: - Helper Classes
class DiaryStartDetailDisplayLogicSpy: DiaryStartDetailDisplayLogic {
    var displayStartDetailsCalled = false
    var displayRecommendationLoadingCalled = false
    var displayRecommendationReceivedCalled = false
    
    var startDetailsViewModel: DiaryStartDetailModels.FetchStartDetails.ViewModel?
    var recommendationLoadingViewModel: DiaryStartDetailModels.RecommendationLoading.ViewModel?
    var recommendationReceivedViewModel: DiaryStartDetailModels.RecommendationReceived.ViewModel?
    
    func displayStartDetails(viewModel: DiaryStartDetailModels.FetchStartDetails.ViewModel) {
        displayStartDetailsCalled = true
        startDetailsViewModel = viewModel
    }
    
    func displayRecommendationLoading(viewModel: DiaryStartDetailModels.RecommendationLoading.ViewModel) {
        displayRecommendationLoadingCalled = true
        recommendationLoadingViewModel = viewModel
    }
    
    func displayRecommendationReceived(viewModel: DiaryStartDetailModels.RecommendationReceived.ViewModel) {
        displayRecommendationReceivedCalled = true
        recommendationReceivedViewModel = viewModel
    }
}
