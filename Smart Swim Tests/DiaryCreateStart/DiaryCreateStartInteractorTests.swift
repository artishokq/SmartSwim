//
//  DiaryCreateStartInteractorTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
@testable import Smart_Swim

final class DiaryCreateStartInteractorTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: DiaryCreateStartInteractor!
    
    // MARK: - Test Doubles
    class DiaryCreateStartPresentationLogicSpy: DiaryCreateStartPresentationLogic {
        var presentStartCreatedCalled = false
        var presentLapCountCalled = false
        var presentCollectedDataCalled = false
        
        var createStartResponse: DiaryCreateStartModels.Create.Response?
        var calculateLapsResponse: DiaryCreateStartModels.CalculateLaps.Response?
        var collectDataResponse: DiaryCreateStartModels.CollectData.Response?
        
        func presentStartCreated(response: DiaryCreateStartModels.Create.Response) {
            presentStartCreatedCalled = true
            createStartResponse = response
        }
        
        func presentLapCount(response: DiaryCreateStartModels.CalculateLaps.Response) {
            presentLapCountCalled = true
            calculateLapsResponse = response
        }
        
        func presentCollectedData(response: DiaryCreateStartModels.CollectData.Response) {
            presentCollectedDataCalled = true
            collectDataResponse = response
        }
    }
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureDiaryCreateStartInteractor()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureDiaryCreateStartInteractor() {
        sut = DiaryCreateStartInteractor()
    }
    
    // MARK: - Calculate Laps
    func testCalculateLapsWithCorrectInput() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CalculateLaps.Request(
            poolSize: 25,
            totalMeters: 50
        )
        
        // Act
        sut.calculateLaps(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentLapCountCalled)
        XCTAssertEqual(spy.calculateLapsResponse?.numberOfLaps, 2)
    }
    
    func testCalculateLapsWithSingleLap() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CalculateLaps.Request(
            poolSize: 25,
            totalMeters: 25
        )
        
        // Act
        sut.calculateLaps(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentLapCountCalled)
        XCTAssertEqual(spy.calculateLapsResponse?.numberOfLaps, 1)
    }
    
    func testCalculateLapsWithZeroLaps() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CalculateLaps.Request(
            poolSize: 25,
            totalMeters: 0
        )
        
        // Act
        sut.calculateLaps(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentLapCountCalled)
        XCTAssertEqual(spy.calculateLapsResponse?.numberOfLaps, 0)
    }
    
    // MARK: - Collect And Validate Data
    func testCollectAndValidateDataWithEmptyMeters() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMetersText: "",
            dateText: "07.04.2025",
            totalTimeText: "01:30,00",
            lapTimeTexts: ["01:30,00"]
        )
        
        // Act
        sut.collectAndValidateData(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCollectedDataCalled)
        XCTAssertFalse(spy.collectDataResponse?.success ?? true)
        XCTAssertNotNil(spy.collectDataResponse?.errorMessage)
        XCTAssertNil(spy.collectDataResponse?.createRequest)
    }
    
    func testCollectAndValidateDataWithInvalidMeters() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMetersText: "abc",
            dateText: "07.04.2025",
            totalTimeText: "01:30,00",
            lapTimeTexts: ["01:30,00"]
        )
        
        // Act
        sut.collectAndValidateData(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCollectedDataCalled)
        XCTAssertFalse(spy.collectDataResponse?.success ?? true)
        XCTAssertNotNil(spy.collectDataResponse?.errorMessage)
    }
    
    func testCollectAndValidateDataWithEmptyTime() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMetersText: "50",
            dateText: "07.04.2025",
            totalTimeText: "",
            lapTimeTexts: ["01:30,00"]
        )
        
        // Act
        sut.collectAndValidateData(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCollectedDataCalled)
        XCTAssertFalse(spy.collectDataResponse?.success ?? true)
        XCTAssertNotNil(spy.collectDataResponse?.errorMessage)
    }
    
    func testCollectAndValidateDataWithInvalidTime() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMetersText: "50",
            dateText: "07.04.2025",
            totalTimeText: "abc",
            lapTimeTexts: ["01:30,00"]
        )
        
        // Act
        sut.collectAndValidateData(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCollectedDataCalled)
        XCTAssertFalse(spy.collectDataResponse?.success ?? true)
        XCTAssertNotNil(spy.collectDataResponse?.errorMessage)
    }
    
    func testCollectAndValidateDataWithEmptyLapTime() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMetersText: "50",
            dateText: "07.04.2025",
            totalTimeText: "01:30,00",
            lapTimeTexts: ["", "01:30,00"]
        )
        
        // Act
        sut.collectAndValidateData(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCollectedDataCalled)
        XCTAssertFalse(spy.collectDataResponse?.success ?? true)
        XCTAssertNotNil(spy.collectDataResponse?.errorMessage)
    }
    
    func testCollectAndValidateDataWithInvalidLapTime() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMetersText: "50",
            dateText: "07.04.2025",
            totalTimeText: "01:30,00",
            lapTimeTexts: ["abc", "01:30,00"]
        )
        
        // Act
        sut.collectAndValidateData(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCollectedDataCalled)
        XCTAssertFalse(spy.collectDataResponse?.success ?? true)
        XCTAssertNotNil(spy.collectDataResponse?.errorMessage)
    }
    
    func testCollectAndValidateDataWithMismatchedTotalAndLapTimes() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMetersText: "50",
            dateText: "07.04.2025",
            totalTimeText: "01:30,00",
            lapTimeTexts: ["00:40,00", "00:40,00"]
        )
        
        // Act
        sut.collectAndValidateData(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCollectedDataCalled)
        XCTAssertFalse(spy.collectDataResponse?.success ?? true)
        XCTAssertNotNil(spy.collectDataResponse?.errorMessage)
    }
    
    func testCollectAndValidateDataWithValidInput() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMetersText: "50",
            dateText: "07.04.2025",
            totalTimeText: "01:30,00",
            lapTimeTexts: ["00:45,00", "00:45,00"]
        )
        
        // Act
        sut.collectAndValidateData(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentCollectedDataCalled)
        XCTAssertTrue(spy.collectDataResponse?.success ?? false)
        XCTAssertNil(spy.collectDataResponse?.errorMessage)
        XCTAssertNotNil(spy.collectDataResponse?.createRequest)
        
        let createRequest = spy.collectDataResponse?.createRequest
        XCTAssertEqual(createRequest?.poolSize, 25)
        XCTAssertEqual(createRequest?.swimmingStyle, 0)
        XCTAssertEqual(createRequest?.totalMeters, 50)
        XCTAssertEqual(createRequest?.totalTime, 90.0)
        XCTAssertEqual(createRequest?.laps.count, 2)
        XCTAssertEqual(createRequest?.laps[0].lapTime, 45.0)
        XCTAssertEqual(createRequest?.laps[1].lapTime, 45.0)
    }
    
    // MARK: - Create Start
    func testCreateStart() {
        // Arrange
        let spy = DiaryCreateStartPresentationLogicSpy()
        sut.presenter = spy
        
        let request = DiaryCreateStartModels.Create.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMeters: 50,
            date: Date(),
            totalTime: 90.0,
            laps: [LapDataDiary(lapTime: 45.0), LapDataDiary(lapTime: 45.0)]
        )
        
        // Act
        sut.createStart(request: request)
        
        // Assert
        XCTAssertTrue(spy.presentStartCreatedCalled)
    }
}
