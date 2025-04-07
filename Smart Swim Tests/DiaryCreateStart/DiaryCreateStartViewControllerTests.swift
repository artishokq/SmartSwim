//
//  DiaryCreateStartViewControllerTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 07.04.2025.
//

import XCTest
@testable import Smart_Swim

final class DiaryCreateStartViewControllerTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: DiaryCreateStartViewController!
    var interactorSpy: DiaryCreateStartBusinessLogicSpy!
    var routerSpy: DiaryCreateStartRouterSpy!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        setupDiaryCreateStartViewController()
    }
    
    override func tearDown() {
        sut = nil
        interactorSpy = nil
        routerSpy = nil
        super.tearDown()
    }
    
    // MARK: - Test Setup
    func setupDiaryCreateStartViewController() {
        sut = DiaryCreateStartViewController()
        
        interactorSpy = DiaryCreateStartBusinessLogicSpy()
        sut.interactor = interactorSpy
        
        routerSpy = DiaryCreateStartRouterSpy()
        sut.router = routerSpy
        
        _ = sut.view
    }
    
    // MARK: - Test Doubles
    class DiaryCreateStartBusinessLogicSpy: DiaryCreateStartBusinessLogic {
        var calculateLapsCalled = false
        var collectAndValidateDataCalled = false
        var createStartCalled = false
        
        var calculateLapsRequest: DiaryCreateStartModels.CalculateLaps.Request?
        var collectDataRequest: DiaryCreateStartModels.CollectData.Request?
        var createStartRequest: DiaryCreateStartModels.Create.Request?
        
        func calculateLaps(request: DiaryCreateStartModels.CalculateLaps.Request) {
            calculateLapsCalled = true
            calculateLapsRequest = request
        }
        
        func collectAndValidateData(request: DiaryCreateStartModels.CollectData.Request) {
            collectAndValidateDataCalled = true
            collectDataRequest = request
        }
        
        func createStart(request: DiaryCreateStartModels.Create.Request) {
            createStartCalled = true
            createStartRequest = request
        }
    }
    
    class DiaryCreateStartRouterSpy: NSObject, DiaryCreateStartRoutingLogic, DiaryCreateStartDataPassing {
        var routeToDiaryCalled = false
        var dataStore: DiaryCreateStartDataStore?
        
        func routeToDiary() {
            routeToDiaryCalled = true
        }
    }
    
    // MARK: - Helper Methods to Access Private Methods
    private func parseTime(_ timeString: String) -> Double? {
        let components = timeString.components(separatedBy: CharacterSet(charactersIn: ":,"))
        guard components.count == 3,
              let minutes = Double(components[0]),
              let seconds = Double(components[1]),
              let milliseconds = Double(components[2]) else {
            return nil
        }
        
        return minutes * 60 + seconds + milliseconds / 100
    }
    
    private func calculateLaps() {
        guard let metersTextField = sut.value(forKey: "metersTextField") as? UITextField,
              let metersText = metersTextField.text, !metersText.isEmpty,
              let totalMeters = Int16(metersText) else {
            return
        }
        
        let poolSizeSegmentControl = sut.value(forKey: "poolSizeSegmentControl") as! UISegmentedControl
        let poolSize: Int16 = poolSizeSegmentControl.selectedSegmentIndex == 0 ? 25 : 50
        
        let request = DiaryCreateStartModels.CalculateLaps.Request(
            poolSize: poolSize,
            totalMeters: totalMeters
        )
        
        sut.interactor?.calculateLaps(request: request)
    }
    
    private func simulateSaveButtonTapped() {
        let poolSizeSegmentControl = sut.value(forKey: "poolSizeSegmentControl") as! UISegmentedControl
        let styleSegmentControl = sut.value(forKey: "styleSegmentControl") as! UISegmentedControl
        let metersTextField = sut.value(forKey: "metersTextField") as! UITextField
        let dateTextField = sut.value(forKey: "dateTextField") as! UITextField
        let timeTextField = sut.value(forKey: "timeTextField") as! UITextField
        let lapTextFields = sut.value(forKey: "lapTextFields") as! [UITextField]
        
        let poolSize: Int16 = poolSizeSegmentControl.selectedSegmentIndex == 0 ? 25 : 50
        let swimmingStyle: Int16 = Int16(styleSegmentControl.selectedSegmentIndex)
        
        var lapTimeTexts: [String] = []
        for textField in lapTextFields {
            if let text = textField.text {
                lapTimeTexts.append(text)
            } else {
                lapTimeTexts.append("")
            }
        }
        
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: poolSize,
            swimmingStyle: swimmingStyle,
            totalMetersText: metersTextField.text ?? "",
            dateText: dateTextField.text ?? "",
            totalTimeText: timeTextField.text ?? "",
            lapTimeTexts: lapTimeTexts
        )
        
        sut.interactor?.collectAndValidateData(request: request)
    }
    
    func setMetersText(_ text: String) {
        let metersTextFieldProperty = sut.value(forKey: "metersTextField") as? UITextField
        metersTextFieldProperty?.text = text
    }
    
    func setTimeText(_ text: String) {
        let timeTextFieldProperty = sut.value(forKey: "timeTextField") as? UITextField
        timeTextFieldProperty?.text = text
    }
    
    func setDateText(_ text: String) {
        let dateTextFieldProperty = sut.value(forKey: "dateTextField") as? UITextField
        dateTextFieldProperty?.text = text
    }
    
    func setPoolSizeSegmentIndex(_ index: Int) {
        let segmentControl = sut.value(forKey: "poolSizeSegmentControl") as? UISegmentedControl
        segmentControl?.selectedSegmentIndex = index
    }
    
    func setStyleSegmentIndex(_ index: Int) {
        let segmentControl = sut.value(forKey: "styleSegmentControl") as? UISegmentedControl
        segmentControl?.selectedSegmentIndex = index
    }
    
    func getLapTextFields() -> [UITextField]? {
        return sut.value(forKey: "lapTextFields") as? [UITextField]
    }
    
    func setLapTextFields(with texts: [String]) {
        guard let textFields = getLapTextFields() else { return }
        
        for (index, text) in texts.enumerated() {
            if index < textFields.count {
                textFields[index].text = text
            }
        }
    }
    
    func setNumberOfLaps(_ count: Int) {
        sut.setValue(count, forKey: "numberOfLaps")
        let lapsStackView = sut.value(forKey: "lapsStackView") as! UIStackView
        for view in lapsStackView.arrangedSubviews {
            lapsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        var lapTextFields: [UITextField] = []
        for _ in 1...count {
            let textField = UITextField()
            lapTextFields.append(textField)
        }
        
        sut.setValue(lapTextFields, forKey: "lapTextFields")
    }
    
    // MARK: - Tests for Parse Time
    func testParseTimeWithValidFormat() {
        let result = parseTime("01:30,50")
        
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 90.5, accuracy: 0.001)
    }
    
    func testParseTimeWithZeroValues() {
        let result = parseTime("00:00,00")
        XCTAssertNotNil(result)
        XCTAssertEqual(result!, 0.0, accuracy: 0.001)
    }
    
    // MARK: - Tests for Display Logic
    func testDisplayStartCreatedWithSuccess() {
        // Arrange
        let viewModel = DiaryCreateStartModels.Create.ViewModel(success: true, message: "Success")
        
        // Act
        sut.displayStartCreated(viewModel: viewModel)
        
        // Assert
        XCTAssertTrue(routerSpy.routeToDiaryCalled)
    }
    
    func testDisplayStartCreatedWithError() {
        // Arrange
        let viewModel = DiaryCreateStartModels.Create.ViewModel(success: false, message: "Error message")
        
        // Act
        sut.displayStartCreated(viewModel: viewModel)
        
        // Assert
        XCTAssertFalse(routerSpy.routeToDiaryCalled)
    }
    
    func testDisplayCollectedDataWithSuccess() {
        // Arrange
        let createRequest = DiaryCreateStartModels.Create.Request(
            poolSize: 25,
            swimmingStyle: 0,
            totalMeters: 50,
            date: Date(),
            totalTime: 90.0,
            laps: [LapDataDiary(lapTime: 45.0), LapDataDiary(lapTime: 45.0)]
        )
        
        let viewModel = DiaryCreateStartModels.CollectData.ViewModel(
            success: true,
            errorMessage: nil,
            createRequest: createRequest
        )
        
        // Act
        sut.displayCollectedData(viewModel: viewModel)
        
        // Assert
        XCTAssertTrue(interactorSpy.createStartCalled)
        XCTAssertNotNil(interactorSpy.createStartRequest)
    }
    
    func testDisplayCollectedDataWithError() {
        // Arrange
        let viewModel = DiaryCreateStartModels.CollectData.ViewModel(
            success: false,
            errorMessage: "Validation error",
            createRequest: nil
        )
        
        // Act
        sut.displayCollectedData(viewModel: viewModel)
        
        // Assert
        XCTAssertFalse(interactorSpy.createStartCalled)
    }
}
