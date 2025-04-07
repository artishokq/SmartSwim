//
//  DiaryStartDetailPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
import UIKit
@testable import Smart_Swim
import CoreData

final class DiaryStartDetailPresenterTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: DiaryStartDetailPresenter!
    
    // MARK: - Test Doubles
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
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureDiaryStartDetailPresenter()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureDiaryStartDetailPresenter() {
        sut = DiaryStartDetailPresenter()
    }
    
    // MARK: - Present Start Details
    func testPresentStartDetailsWithPersonalBest() {
        // Arrange
        let spy = DiaryStartDetailDisplayLogicSpy()
        sut.viewController = spy
        
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
        sut.presentStartDetails(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayStartDetailsCalled)
        
        let viewModel = spy.startDetailsViewModel
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel?.headerInfo.distanceWithStyle, "50м Вольный стиль")
        XCTAssertEqual(viewModel?.headerInfo.totalTime, "01:00,00")
        XCTAssertEqual(viewModel?.headerInfo.timeComparisonString, "лучший результат")
        
        let greenColor = UIColor(hexString: "#4CD964") ?? .green
        XCTAssertEqual(viewModel?.headerInfo.comparisonColor.hexString(), greenColor.hexString())
        
        XCTAssertEqual(viewModel?.lapDetails.count, 1)
        XCTAssertEqual(viewModel?.lapDetails.first?.title, "Отрезок 1")
        XCTAssertEqual(viewModel?.lapDetails.first?.pulse, "150 уд/мин")
        XCTAssertEqual(viewModel?.lapDetails.first?.strokes, "20")
        XCTAssertEqual(viewModel?.lapDetails.first?.time, "00:30,00")
        
        XCTAssertEqual(viewModel?.recommendationText, "Great swimming!")
        XCTAssertFalse(viewModel?.isLoadingRecommendation ?? true)
    }
    
    func testPresentStartDetailsWithSlowerTime() {
        // Arrange
        let spy = DiaryStartDetailDisplayLogicSpy()
        sut.viewController = spy
        
        let lap = DiaryStartDetailModels.FetchStartDetails.Response.LapData(
            lapNumber: 1,
            lapTime: 35.0,
            pulse: 150,
            strokes: 20
        )
        
        let response = DiaryStartDetailModels.FetchStartDetails.Response(
            date: Date(),
            poolSize: 25,
            totalMeters: 50,
            swimmingStyle: 0,
            totalTime: 70.0,
            laps: [lap],
            bestTime: 60.0,
            bestTimeDate: Date(),
            isCurrentBest: false,
            hasRecommendation: false,
            recommendationText: nil,
            isLoadingRecommendation: true
        )
        
        // Act
        sut.presentStartDetails(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayStartDetailsCalled)
        
        let viewModel = spy.startDetailsViewModel
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel?.headerInfo.totalTime, "01:10,00")
        XCTAssertEqual(viewModel?.headerInfo.timeComparisonString, "+00:10,00")
        
        let redColor = UIColor(hexString: "#FF4F4F") ?? .red
        XCTAssertEqual(viewModel?.headerInfo.comparisonColor.hexString(), redColor.hexString())
        
        XCTAssertEqual(viewModel?.recommendationText, "Загрузка рекомендации...")
        XCTAssertTrue(viewModel?.isLoadingRecommendation ?? false)
    }
    
    func testPresentStartDetailsWithLoadingRecommendation() {
        // Arrange
        let spy = DiaryStartDetailDisplayLogicSpy()
        sut.viewController = spy
        
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
            hasRecommendation: false,
            recommendationText: nil,
            isLoadingRecommendation: true
        )
        
        // Act
        sut.presentStartDetails(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayStartDetailsCalled)
        
        let viewModel = spy.startDetailsViewModel
        XCTAssertEqual(viewModel?.recommendationText, "Загрузка рекомендации...")
        XCTAssertTrue(viewModel?.isLoadingRecommendation ?? false)
    }
    
    // MARK: - Present Recommendation Loading
    func testPresentRecommendationLoading() {
        // Arrange
        let spy = DiaryStartDetailDisplayLogicSpy()
        sut.viewController = spy
        
        // Act
        let loadingResponse = DiaryStartDetailModels.RecommendationLoading.Response(isLoading: true)
        sut.presentRecommendationLoading(response: loadingResponse)
        
        // Assert
        XCTAssertTrue(spy.displayRecommendationLoadingCalled)
        XCTAssertTrue(spy.recommendationLoadingViewModel?.isLoading ?? false)
        
        spy.displayRecommendationLoadingCalled = false
        let notLoadingResponse = DiaryStartDetailModels.RecommendationLoading.Response(isLoading: false)
        sut.presentRecommendationLoading(response: notLoadingResponse)
        
        XCTAssertTrue(spy.displayRecommendationLoadingCalled)
        XCTAssertFalse(spy.recommendationLoadingViewModel?.isLoading ?? true)
    }
    
    // MARK: - Present Recommendation Received
    func testPresentRecommendationReceived() {
        // Arrange
        let spy = DiaryStartDetailDisplayLogicSpy()
        sut.viewController = spy
        
        let mockRecommendation = "Your swimming technique is good, but you could improve your turns."
        let mockStartID = NSManagedObjectID()
        
        let response = DiaryStartDetailModels.RecommendationReceived.Response(
            recommendationText: mockRecommendation,
            startID: mockStartID
        )
        
        // Act
        sut.presentRecommendationReceived(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayRecommendationReceivedCalled)
        XCTAssertEqual(spy.recommendationReceivedViewModel?.recommendationText, mockRecommendation)
    }
    
    // MARK: - Helper Methods for Testing
    func testFormatTimeFormatsCorrectly() {
        // Arrange
        let spy = DiaryStartDetailDisplayLogicSpy()
        sut.viewController = spy
        
        let response = DiaryStartDetailModels.FetchStartDetails.Response(
            date: Date(),
            poolSize: 25,
            totalMeters: 50,
            swimmingStyle: 0,
            totalTime: 123.45,
            laps: [],
            bestTime: 123.45,
            bestTimeDate: Date(),
            isCurrentBest: true,
            hasRecommendation: false,
            recommendationText: nil,
            isLoadingRecommendation: false
        )
        
        // Act
        sut.presentStartDetails(response: response)
        
        // Assert
        XCTAssertEqual(spy.startDetailsViewModel?.headerInfo.totalTime, "02:03,45")
    }
    
    func testGetSwimStyleDescriptionReturnsCorrectStyles() {
        // Arrange
        let spy = DiaryStartDetailDisplayLogicSpy()
        sut.viewController = spy
        
        let styles: [(Int16, String)] = [
            (0, "Вольный стиль"),
            (1, "Брасс"),
            (2, "На спине"),
            (3, "Баттерфляй"),
            (4, "Комплекс")
        ]
        
        for (styleRawValue, expectedDescription) in styles {
            let response = DiaryStartDetailModels.FetchStartDetails.Response(
                date: Date(),
                poolSize: 25,
                totalMeters: 50,
                swimmingStyle: styleRawValue,
                totalTime: 60.0,
                laps: [],
                bestTime: 60.0,
                bestTimeDate: Date(),
                isCurrentBest: true,
                hasRecommendation: false,
                recommendationText: nil,
                isLoadingRecommendation: false
            )
            
            // Act
            sut.presentStartDetails(response: response)
            
            // Assert
            XCTAssertTrue(spy.startDetailsViewModel?.headerInfo.distanceWithStyle.contains(expectedDescription) ?? false)
        }
    }
}

// MARK: - Extensions for Testing
extension UIColor {
    func hexString() -> String {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
