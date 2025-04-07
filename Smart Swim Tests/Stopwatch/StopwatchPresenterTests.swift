//
//  StopwatchPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
@testable import Smart_Swim

final class StopwatchPresenterTests: XCTestCase {
    // MARK: - Properties
    var sut: StopwatchPresenter!
    var mockViewController: MockStopwatchDisplayLogic!
    
    // MARK: - Setup and Teardown
    override func setUp() {
        super.setUp()
        sut = StopwatchPresenter()
        mockViewController = MockStopwatchDisplayLogic()
        sut.viewController = mockViewController
    }
    
    override func tearDown() {
        sut = nil
        mockViewController = nil
        super.tearDown()
    }
    
    // MARK: - Tests for Timer Tick
    func testPresentTimerTickFormatsTimeCorrectly() {
        // Arrange
        let response = StopwatchModels.TimerTick.Response(
            globalTime: 65.42,
            lapTime: 12.76
        )
        
        // Act
        sut.presentTimerTick(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayTimerTickCalled)
        XCTAssertEqual(mockViewController.timerTickViewModel?.formattedGlobalTime, "01:05,42")
        XCTAssertEqual(mockViewController.timerTickViewModel?.formattedActiveLapTime, "00:12,76")
    }
    
    func testPresentTimerTickWithZeroValues() {
        // Arrange
        let response = StopwatchModels.TimerTick.Response(
            globalTime: 0.0,
            lapTime: 0.0
        )
        
        // Act
        sut.presentTimerTick(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayTimerTickCalled)
        XCTAssertEqual(mockViewController.timerTickViewModel?.formattedGlobalTime, "00:00,00")
        XCTAssertEqual(mockViewController.timerTickViewModel?.formattedActiveLapTime, "00:00,00")
    }
    
    func testPresentTimerTickWithLargeValues() {
        // Arrange
        let response = StopwatchModels.TimerTick.Response(
            globalTime: 3723.99,
            lapTime: 123.45
        )
        
        // Act
        sut.presentTimerTick(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayTimerTickCalled)
        XCTAssertEqual(mockViewController.timerTickViewModel?.formattedGlobalTime, "62:03,99")
        XCTAssertEqual(mockViewController.timerTickViewModel?.formattedActiveLapTime, "02:03,45")
    }
    
    // MARK: - Tests for Main Button Action
    func testPresentMainButtonActionForTurn() {
        // Arrange
        let response = StopwatchModels.MainButtonAction.Response(
            nextButtonTitle: "Поворот",
            nextButtonColor: .systemBlue
        )
        
        // Act
        sut.presentMainButtonAction(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayMainButtonActionCalled)
        XCTAssertEqual(mockViewController.mainButtonActionViewModel?.buttonTitle, "Поворот")
        XCTAssertEqual(mockViewController.mainButtonActionViewModel?.buttonColor, .systemBlue)
    }
    
    func testPresentMainButtonActionForFinish() {
        // Arrange
        let response = StopwatchModels.MainButtonAction.Response(
            nextButtonTitle: "Финиш",
            nextButtonColor: .systemRed
        )
        
        // Act
        sut.presentMainButtonAction(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayMainButtonActionCalled)
        XCTAssertEqual(mockViewController.mainButtonActionViewModel?.buttonTitle, "Финиш")
        XCTAssertEqual(mockViewController.mainButtonActionViewModel?.buttonColor, .systemRed)
    }
    
    // MARK: - Tests for Lap Recording
    func testPresentLapRecording() {
        // Arrange
        let response = StopwatchModels.LapRecording.Response(
            lapNumber: 3,
            lapTime: 45.67
        )
        
        // Act
        sut.presentLapRecording(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayLapRecordingCalled)
        XCTAssertEqual(mockViewController.lapRecordingViewModel?.lapNumber, 3)
        XCTAssertEqual(mockViewController.lapRecordingViewModel?.lapTimeString, "00:45,67")
    }
    
    // MARK: - Tests for Finish
    func testPresentFinishWithSuccessfulSave() {
        // Arrange
        let response = StopwatchModels.Finish.Response(
            finalButtonTitle: "Финиш",
            finalButtonColor: .systemGray,
            dataSaved: true
        )
        
        // Act
        sut.presentFinish(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayFinishCalled)
        XCTAssertEqual(mockViewController.finishViewModel?.buttonTitle, "Финиш")
        XCTAssertEqual(mockViewController.finishViewModel?.buttonColor, .systemGray)
        XCTAssertEqual(mockViewController.finishViewModel?.showSaveSuccessAlert, true)
    }
    
    func testPresentFinishWithFailedSave() {
        // Arrange
        let response = StopwatchModels.Finish.Response(
            finalButtonTitle: "Финиш",
            finalButtonColor: .systemGray,
            dataSaved: false
        )
        
        // Act
        sut.presentFinish(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayFinishCalled)
        XCTAssertEqual(mockViewController.finishViewModel?.buttonTitle, "Финиш")
        XCTAssertEqual(mockViewController.finishViewModel?.buttonColor, .systemGray)
        XCTAssertEqual(mockViewController.finishViewModel?.showSaveSuccessAlert, false)
    }
    
    // MARK: - Tests for Pulse Update
    func testPresentPulseUpdate() {
        // Arrange
        let response = StopwatchModels.PulseUpdate.Response(pulse: 150)
        
        // Act
        sut.presentPulseUpdate(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayPulseUpdateCalled)
        XCTAssertEqual(mockViewController.pulseUpdateViewModel?.pulse, 150)
    }
    
    // MARK: - Tests for Stroke Update
    func testPresentStrokeUpdate() {
        // Arrange
        let response = StopwatchModels.StrokeUpdate.Response(strokes: 25)
        
        // Act
        sut.presentStrokeUpdate(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayStrokeUpdateCalled)
        XCTAssertEqual(mockViewController.strokeUpdateViewModel?.strokes, 25)
    }
    
    // MARK: - Tests for Watch Status Update
    func testPresentWatchStatusUpdate() {
        // Arrange
        let response = StopwatchModels.WatchStatusUpdate.Response(status: "connected")
        
        // Act
        sut.presentWatchStatusUpdate(response: response)
        
        // Assert
        XCTAssertTrue(mockViewController.displayWatchStatusUpdateCalled)
        XCTAssertEqual(mockViewController.watchStatusUpdateViewModel?.status, "connected")
    }
}

// MARK: - Mock Classes
class MockStopwatchDisplayLogic: StopwatchDisplayLogic {
    var displayTimerTickCalled = false
    var displayMainButtonActionCalled = false
    var displayLapRecordingCalled = false
    var displayFinishCalled = false
    var displayPulseUpdateCalled = false
    var displayStrokeUpdateCalled = false
    var displayWatchStatusUpdateCalled = false
    
    var timerTickViewModel: StopwatchModels.TimerTick.ViewModel?
    var mainButtonActionViewModel: StopwatchModels.MainButtonAction.ViewModel?
    var lapRecordingViewModel: StopwatchModels.LapRecording.ViewModel?
    var finishViewModel: StopwatchModels.Finish.ViewModel?
    var pulseUpdateViewModel: StopwatchModels.PulseUpdate.ViewModel?
    var strokeUpdateViewModel: StopwatchModels.StrokeUpdate.ViewModel?
    var watchStatusUpdateViewModel: StopwatchModels.WatchStatusUpdate.ViewModel?
    
    func displayTimerTick(viewModel: StopwatchModels.TimerTick.ViewModel) {
        displayTimerTickCalled = true
        timerTickViewModel = viewModel
    }
    
    func displayMainButtonAction(viewModel: StopwatchModels.MainButtonAction.ViewModel) {
        displayMainButtonActionCalled = true
        mainButtonActionViewModel = viewModel
    }
    
    func displayLapRecording(viewModel: StopwatchModels.LapRecording.ViewModel) {
        displayLapRecordingCalled = true
        lapRecordingViewModel = viewModel
    }
    
    func displayFinish(viewModel: StopwatchModels.Finish.ViewModel) {
        displayFinishCalled = true
        finishViewModel = viewModel
    }
    
    func displayPulseUpdate(viewModel: StopwatchModels.PulseUpdate.ViewModel) {
        displayPulseUpdateCalled = true
        pulseUpdateViewModel = viewModel
    }
    
    func displayStrokeUpdate(viewModel: StopwatchModels.StrokeUpdate.ViewModel) {
        displayStrokeUpdateCalled = true
        strokeUpdateViewModel = viewModel
    }
    
    func displayWatchStatusUpdate(viewModel: StopwatchModels.WatchStatusUpdate.ViewModel) {
        displayWatchStatusUpdateCalled = true
        watchStatusUpdateViewModel = viewModel
    }
}
