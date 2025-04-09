//
//  WorkoutSessionDetailPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
@testable import Smart_Swim

final class WorkoutSessionDetailPresenterTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: WorkoutSessionDetailPresenter!
    
    // MARK: - Test Doubles
    var viewControllerSpy: WorkoutSessionDetailDisplayLogicSpy!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        setupWorkoutSessionDetailPresenter()
    }
    
    override func tearDown() {
        sut = nil
        viewControllerSpy = nil
        super.tearDown()
    }
    
    // MARK: - Test Setup
    func setupWorkoutSessionDetailPresenter() {
        sut = WorkoutSessionDetailPresenter()
        viewControllerSpy = WorkoutSessionDetailDisplayLogicSpy()
        sut.viewController = viewControllerSpy
    }
    
    // MARK: - Present Session Details Tests
    func testPresentSessionDetailsFormatsDataCorrectly() {
        let response = createSampleSessionDetailsResponse()
        
        sut.presentSessionDetails(response: response)
        
        XCTAssertTrue(viewControllerSpy.displaySessionDetailsCalled)
        
        guard let viewModel = viewControllerSpy.displaySessionDetailsViewModel else {
            XCTFail("ViewModel should not be nil")
            return
        }
        
        XCTAssertTrue(viewModel.summaryData.dateString.contains("25.03.2025"))
        XCTAssertEqual(viewModel.summaryData.totalTimeString, "1:00:00")
        XCTAssertEqual(viewModel.summaryData.totalMetersString, "1000м")
        XCTAssertEqual(viewModel.summaryData.totalCaloriesString, "500 ккал")
        XCTAssertEqual(viewModel.summaryData.averageHeartRateString, "150 уд/м")
        XCTAssertEqual(viewModel.summaryData.poolSizeString, "Бассейн 25м")
        
        XCTAssertEqual(viewModel.exercises.count, 2)
        
        let firstExercise = viewModel.exercises.first!
        XCTAssertEqual(firstExercise.description, "Разминка")
        XCTAssertEqual(firstExercise.styleString, "вольный стиль")
        XCTAssertEqual(firstExercise.typeString, "разминка")
        XCTAssertEqual(firstExercise.timeString, "0:30:00")
        XCTAssertEqual(firstExercise.metersString, "500м")
        XCTAssertTrue(firstExercise.hasInterval)
        XCTAssertEqual(firstExercise.intervalString, "1:30")
    }
    
    // MARK: - Present Recommendation Tests
    func testPresentRecommendationWhileLoading() {
        let response = WorkoutSessionDetailModels.FetchRecommendation.Response(
            recommendationText: nil,
            isLoading: true
        )
        
        sut.presentRecommendation(response: response)
        
        XCTAssertTrue(viewControllerSpy.displayRecommendationCalled)
        
        guard let viewModel = viewControllerSpy.displayRecommendationViewModel else {
            XCTFail("ViewModel should not be nil")
            return
        }
        
        XCTAssertEqual(viewModel.recommendationText, "Загрузка рекомендации...")
        XCTAssertTrue(viewModel.isLoading)
    }
    
    func testPresentRecommendationWithData() {
        let response = WorkoutSessionDetailModels.FetchRecommendation.Response(
            recommendationText: "This is a recommendation",
            isLoading: false
        )
        
        sut.presentRecommendation(response: response)
        
        XCTAssertTrue(viewControllerSpy.displayRecommendationCalled)
        
        guard let viewModel = viewControllerSpy.displayRecommendationViewModel else {
            XCTFail("ViewModel should not be nil")
            return
        }
        
        XCTAssertEqual(viewModel.recommendationText, "This is a recommendation")
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Test Helper Methods
    func testFormatTime() {
        XCTAssertEqual(formatTime(0), "0:00:00")
        XCTAssertEqual(formatTime(30), "0:00:30")
        XCTAssertEqual(formatTime(65), "0:01:05")
        XCTAssertEqual(formatTime(3665), "1:01:05")
    }
    
    func testDeterminePulseZone() {
        XCTAssertEqual(determinePulseZone(120), "Разминка (< 125)")
        XCTAssertEqual(determinePulseZone(130), "Аэробная (126-151)")
        XCTAssertEqual(determinePulseZone(160), "Анаэробная (152-171)")
        XCTAssertEqual(determinePulseZone(180), "Максимальная (172+)")
    }
    
    // MARK: - Helper Functions
    func formatTime(_ totalSeconds: Double) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60
        
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    
    func determinePulseZone(_ averagePulse: Double) -> String {
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
    
    // MARK: - Test Data Helpers
    private func createSampleSessionDetailsResponse() -> WorkoutSessionDetailModels.FetchSessionDetails.Response {
        let date = Calendar.current.date(from: DateComponents(year: 2025, month: 3, day: 25, hour: 10, minute: 30))!
        
        let headerData = WorkoutSessionDetailModels.FetchSessionDetails.Response.HeaderData(
            date: date,
            totalTime: 3600,
            totalMeters: 1000,
            totalCalories: 500,
            averageHeartRate: 150,
            poolSize: 25,
            workoutName: "Тренировка"
        )
        
        let lap1_1 = WorkoutSessionDetailModels.FetchSessionDetails.Response.LapData(
            id: UUID(),
            lapNumber: 1,
            distance: 50,
            lapTime: 30.0,
            heartRate: 140,
            strokes: 20,
            timestamp: date
        )
        
        let lap1_2 = WorkoutSessionDetailModels.FetchSessionDetails.Response.LapData(
            id: UUID(),
            lapNumber: 2,
            distance: 50,
            lapTime: 30.0,
            heartRate: 160,
            strokes: 22,
            timestamp: date.addingTimeInterval(30)
        )
        
        let hr1_1 = WorkoutSessionDetailModels.FetchSessionDetails.Response.HeartRateData(
            value: 140,
            timestamp: date
        )
        
        let hr1_2 = WorkoutSessionDetailModels.FetchSessionDetails.Response.HeartRateData(
            value: 150,
            timestamp: date.addingTimeInterval(15)
        )
        
        let hr1_3 = WorkoutSessionDetailModels.FetchSessionDetails.Response.HeartRateData(
            value: 160,
            timestamp: date.addingTimeInterval(30)
        )
        
        let exercise1 = WorkoutSessionDetailModels.FetchSessionDetails.Response.ExerciseData(
            id: UUID(),
            orderIndex: 0,
            description: "Разминка",
            style: 0,
            type: 0,
            startTime: date,
            endTime: date.addingTimeInterval(1800),
            hasInterval: true,
            intervalMinutes: 1,
            intervalSeconds: 30,
            meters: 500,
            repetitions: 1,
            laps: [lap1_1, lap1_2],
            heartRateReadings: [hr1_1, hr1_2, hr1_3],
            totalTime: 1800,
            averageHeartRate: 150,
            totalStrokes: 42
        )
        
        let lap2_1 = WorkoutSessionDetailModels.FetchSessionDetails.Response.LapData(
            id: UUID(),
            lapNumber: 1,
            distance: 50,
            lapTime: 30.0,
            heartRate: 170,
            strokes: 25,
            timestamp: date.addingTimeInterval(1800)
        )
        
        let lap2_2 = WorkoutSessionDetailModels.FetchSessionDetails.Response.LapData(
            id: UUID(),
            lapNumber: 2,
            distance: 50,
            lapTime: 30.0,
            heartRate: 180,
            strokes: 27,
            timestamp: date.addingTimeInterval(1830)
        )
        
        let hr2_1 = WorkoutSessionDetailModels.FetchSessionDetails.Response.HeartRateData(
            value: 170,
            timestamp: date.addingTimeInterval(1800)
        )
        
        let hr2_2 = WorkoutSessionDetailModels.FetchSessionDetails.Response.HeartRateData(
            value: 180,
            timestamp: date.addingTimeInterval(1830)
        )
        
        let exercise2 = WorkoutSessionDetailModels.FetchSessionDetails.Response.ExerciseData(
            id: UUID(),
            orderIndex: 1,
            description: "Основное",
            style: 1,
            type: 1,
            startTime: date.addingTimeInterval(1800),
            endTime: date.addingTimeInterval(3600),
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0,
            meters: 500,
            repetitions: 1,
            laps: [lap2_1, lap2_2],
            heartRateReadings: [hr2_1, hr2_2],
            totalTime: 1800,
            averageHeartRate: 175,
            totalStrokes: 52
        )
        
        return WorkoutSessionDetailModels.FetchSessionDetails.Response(
            headerData: headerData,
            exercises: [exercise1, exercise2]
        )
    }
}
