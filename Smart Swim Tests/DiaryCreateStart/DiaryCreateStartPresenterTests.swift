//
//  DiaryCreateStartPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
@testable import Smart_Swim

final class DiaryCreateStartPresenterTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: DiaryCreateStartPresenter!
    
    // MARK: - Test Doubles
    class DiaryCreateStartDisplayLogicSpy: DiaryCreateStartDisplayLogic {
        var displayStartCreatedCalled = false
        var displayLapCountCalled = false
        var displayCollectedDataCalled = false
        
        var startCreatedViewModel: DiaryCreateStartModels.Create.ViewModel?
        var lapCountViewModel: DiaryCreateStartModels.CalculateLaps.ViewModel?
        var collectedDataViewModel: DiaryCreateStartModels.CollectData.ViewModel?
        
        func displayStartCreated(viewModel: DiaryCreateStartModels.Create.ViewModel) {
            displayStartCreatedCalled = true
            startCreatedViewModel = viewModel
        }
        
        func displayLapCount(viewModel: DiaryCreateStartModels.CalculateLaps.ViewModel) {
            displayLapCountCalled = true
            lapCountViewModel = viewModel
        }
        
        func displayCollectedData(viewModel: DiaryCreateStartModels.CollectData.ViewModel) {
            displayCollectedDataCalled = true
            collectedDataViewModel = viewModel
        }
    }
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureDiaryCreateStartPresenter()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureDiaryCreateStartPresenter() {
        sut = DiaryCreateStartPresenter()
    }
    
    // MARK: - Present Start Created
    func testPresentStartCreatedWithSuccess() {
        // Arrange
        let spy = DiaryCreateStartDisplayLogicSpy()
        sut.viewController = spy
        
        let response = DiaryCreateStartModels.Create.Response(success: true, errorMessage: nil)
        
        // Act
        sut.presentStartCreated(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayStartCreatedCalled)
        XCTAssertTrue(spy.startCreatedViewModel?.success ?? false)
        XCTAssertEqual(spy.startCreatedViewModel?.message, "Старт успешно создан")
    }
    
    func testPresentStartCreatedWithError() {
        // Arrange
        let spy = DiaryCreateStartDisplayLogicSpy()
        sut.viewController = spy
        
        let errorMessage = "Ошибка при сохранении"
        let response = DiaryCreateStartModels.Create.Response(success: false, errorMessage: errorMessage)
        
        // Act
        sut.presentStartCreated(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayStartCreatedCalled)
        XCTAssertFalse(spy.startCreatedViewModel?.success ?? true)
        XCTAssertEqual(spy.startCreatedViewModel?.message, errorMessage)
    }
    
    func testPresentStartCreatedWithFailureButNoErrorMessage() {
        // Arrange
        let spy = DiaryCreateStartDisplayLogicSpy()
        sut.viewController = spy
        
        let response = DiaryCreateStartModels.Create.Response(success: false, errorMessage: nil)
        
        // Act
        sut.presentStartCreated(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayStartCreatedCalled)
        XCTAssertFalse(spy.startCreatedViewModel?.success ?? true)
        XCTAssertEqual(spy.startCreatedViewModel?.message, "Ошибка при создании старта")
    }
    
    // MARK: - Present Lap Count
    func testPresentLapCount() {
        // Arrange
        let spy = DiaryCreateStartDisplayLogicSpy()
        sut.viewController = spy
        
        let response = DiaryCreateStartModels.CalculateLaps.Response(numberOfLaps: 2)
        
        // Act
        sut.presentLapCount(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayLapCountCalled)
        XCTAssertEqual(spy.lapCountViewModel?.numberOfLaps, 2)
    }
    
    // MARK: - Present Collected Data
    func testPresentCollectedDataWithSuccess() {
        // Arrange
        let spy = DiaryCreateStartDisplayLogicSpy()
        sut.viewController = spy
        
        let createRequest = DiaryCreateStartModels.Create.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMeters: 50,
            date: Date(),
            totalTime: 90.0,
            laps: [LapDataDiary(lapTime: 45.0), LapDataDiary(lapTime: 45.0)]
        )
        
        let response = DiaryCreateStartModels.CollectData.Response(
            success: true,
            errorMessage: nil,
            createRequest: createRequest
        )
        
        // Act
        sut.presentCollectedData(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayCollectedDataCalled)
        XCTAssertTrue(spy.collectedDataViewModel?.success ?? false)
        XCTAssertNil(spy.collectedDataViewModel?.errorMessage)
        XCTAssertNotNil(spy.collectedDataViewModel?.createRequest)
    }
    
    func testPresentCollectedDataWithError() {
        // Arrange
        let spy = DiaryCreateStartDisplayLogicSpy()
        sut.viewController = spy
        
        let errorMessage = "Неверные данные"
        let response = DiaryCreateStartModels.CollectData.Response(
            success: false,
            errorMessage: errorMessage,
            createRequest: nil
        )
        
        // Act
        sut.presentCollectedData(response: response)
        
        // Assert
        XCTAssertTrue(spy.displayCollectedDataCalled)
        XCTAssertFalse(spy.collectedDataViewModel?.success ?? true)
        XCTAssertEqual(spy.collectedDataViewModel?.errorMessage, errorMessage)
        XCTAssertNil(spy.collectedDataViewModel?.createRequest)
    }
}
