//
//  DiaryPresenterTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 06.04.2025.
//

import XCTest
import CoreData
@testable import Smart_Swim

final class DiaryPresenterTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: DiaryPresenter!
    
    // MARK: - Test Doubles
    class DiaryDisplayLogicSpy: DiaryDisplayLogic {
        var displayStartsCalled = false
        var displayDeleteStartCalled = false
        var displayStartDetailCalled = false
        var displayCreateStartCalled = false
        var displayWorkoutSessionsCalled = false
        var displayDeleteWorkoutSessionCalled = false
        var displayWorkoutSessionDetailCalled = false
        
        var startsViewModel: DiaryModels.FetchStarts.ViewModel?
        var deleteStartViewModel: DiaryModels.DeleteStart.ViewModel?
        var startDetailViewModel: DiaryModels.ShowStartDetail.ViewModel?
        var createStartViewModel: DiaryModels.CreateStart.ViewModel?
        var workoutSessionsViewModel: DiaryModels.FetchWorkoutSessions.ViewModel?
        var deleteWorkoutSessionViewModel: DiaryModels.DeleteWorkoutSession.ViewModel?
        var workoutSessionDetailViewModel: DiaryModels.ShowWorkoutSessionDetail.ViewModel?
        
        func displayStarts(viewModel: DiaryModels.FetchStarts.ViewModel) {
            displayStartsCalled = true
            startsViewModel = viewModel
        }
        
        func displayDeleteStart(viewModel: DiaryModels.DeleteStart.ViewModel) {
            displayDeleteStartCalled = true
            deleteStartViewModel = viewModel
        }
        
        func displayStartDetail(viewModel: DiaryModels.ShowStartDetail.ViewModel) {
            displayStartDetailCalled = true
            startDetailViewModel = viewModel
        }
        
        func displayCreateStart(viewModel: DiaryModels.CreateStart.ViewModel) {
            displayCreateStartCalled = true
            createStartViewModel = viewModel
        }
        
        func displayWorkoutSessions(viewModel: DiaryModels.FetchWorkoutSessions.ViewModel) {
            displayWorkoutSessionsCalled = true
            workoutSessionsViewModel = viewModel
        }
        
        func displayDeleteWorkoutSession(viewModel: DiaryModels.DeleteWorkoutSession.ViewModel) {
            displayDeleteWorkoutSessionCalled = true
            deleteWorkoutSessionViewModel = viewModel
        }
        
        func displayWorkoutSessionDetail(viewModel: DiaryModels.ShowWorkoutSessionDetail.ViewModel) {
            displayWorkoutSessionDetailCalled = true
            workoutSessionDetailViewModel = viewModel
        }
    }
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureDiaryPresenter()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureDiaryPresenter() {
        sut = DiaryPresenter()
    }
    
    // MARK: Present Starts
    func testPresentStarts() {
        // Arrange
        let displayLogicSpy = DiaryDisplayLogicSpy()
        sut.viewController = displayLogicSpy
        
        let date = Date()
        let startID = NSManagedObjectID()
        let response = DiaryModels.FetchStarts.Response(starts: [
            DiaryModels.FetchStarts.Response.StartData(
                id: startID,
                date: date,
                totalMeters: 1000,
                swimmingStyle: SwimStyle.freestyle.rawValue,
                totalTime: 720.5
            )
        ])
        
        // Act
        sut.presentStarts(response: response)
        
        // Assert
        XCTAssertTrue(displayLogicSpy.displayStartsCalled)
        XCTAssertEqual(displayLogicSpy.startsViewModel?.starts.count, 1)
        
        let formattedStart = displayLogicSpy.startsViewModel?.starts.first
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let expectedDateString = dateFormatter.string(from: date)
        
        XCTAssertEqual(formattedStart?.dateString, expectedDateString)
        XCTAssertEqual(formattedStart?.metersString, "1000м")
        XCTAssertEqual(formattedStart?.styleString, "вольный стиль")
        XCTAssertEqual(formattedStart?.timeString, "12:00,50")
    }
    
    // MARK: Present Delete Start
    func testPresentDeleteStart() {
        // Arrange
        let displayLogicSpy = DiaryDisplayLogicSpy()
        sut.viewController = displayLogicSpy
        
        let response = DiaryModels.DeleteStart.Response(index: 1)
        
        // Act
        sut.presentDeleteStart(response: response)
        
        // Assert
        XCTAssertTrue(displayLogicSpy.displayDeleteStartCalled)
        XCTAssertEqual(displayLogicSpy.deleteStartViewModel?.index, 1)
    }
    
    // MARK: Present Start Detail
    func testPresentStartDetail() {
        // Arrange
        let displayLogicSpy = DiaryDisplayLogicSpy()
        sut.viewController = displayLogicSpy
        
        let startID = NSManagedObjectID()
        let response = DiaryModels.ShowStartDetail.Response(startID: startID)
        
        // Act
        sut.presentStartDetail(response: response)
        
        // Assert
        XCTAssertTrue(displayLogicSpy.displayStartDetailCalled)
        XCTAssertEqual(displayLogicSpy.startDetailViewModel?.startID, startID)
    }
    
    // MARK: Present Create Start
    func testPresentCreateStart() {
        // Arrange
        let displayLogicSpy = DiaryDisplayLogicSpy()
        sut.viewController = displayLogicSpy
        
        let response = DiaryModels.CreateStart.Response()
        
        // Act
        sut.presentCreateStart(response: response)
        
        // Assert
        XCTAssertTrue(displayLogicSpy.displayCreateStartCalled)
    }
    
    // MARK: Present Workout Sessions
    func testPresentWorkoutSessions() {
        // Arrange
        let displayLogicSpy = DiaryDisplayLogicSpy()
        sut.viewController = displayLogicSpy
        
        let date = Date()
        let sessionID = UUID()
        
        let exercise1 = DiaryModels.FetchWorkoutSessions.Response.WorkoutSessionData.ExerciseData(
            orderIndex: 0,
            description: "Warmup",
            style: SwimStyle.freestyle.rawValue,
            type: ExerciseType.warmup.rawValue,
            meters: 100,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: 0,
            intervalSeconds: 0
        )
        
        let exercise2 = DiaryModels.FetchWorkoutSessions.Response.WorkoutSessionData.ExerciseData(
            orderIndex: 1,
            description: "Main set",
            style: SwimStyle.backstroke.rawValue,
            type: ExerciseType.main.rawValue,
            meters: 200,
            repetitions: 4,
            hasInterval: true,
            intervalMinutes: 1,
            intervalSeconds: 30
        )
        
        let response = DiaryModels.FetchWorkoutSessions.Response(workoutSessions: [
            DiaryModels.FetchWorkoutSessions.Response.WorkoutSessionData(
                id: sessionID,
                date: date,
                totalMeters: 1000,
                totalTime: 3665,
                poolSize: 25,
                workoutName: "Test Workout",
                exercises: [exercise1, exercise2]
            )
        ])
        
        // Act
        sut.presentWorkoutSessions(response: response)
        
        // Assert
        XCTAssertTrue(displayLogicSpy.displayWorkoutSessionsCalled)
        XCTAssertEqual(displayLogicSpy.workoutSessionsViewModel?.workoutSessions.count, 1)
        
        let formattedSession = displayLogicSpy.workoutSessionsViewModel?.workoutSessions.first
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let expectedDateString = dateFormatter.string(from: date)
        
        XCTAssertEqual(formattedSession?.dateString, expectedDateString)
        XCTAssertEqual(formattedSession?.totalMeters, "1000м")
        XCTAssertEqual(formattedSession?.totalTimeString, "01:01:05")
        XCTAssertEqual(formattedSession?.rawTotalSeconds, 3665)
        XCTAssertEqual(formattedSession?.exercises.count, 2)
    }
    
    // MARK: Present Delete Workout Session
    func testPresentDeleteWorkoutSession() {
        // Arrange
        let displayLogicSpy = DiaryDisplayLogicSpy()
        sut.viewController = displayLogicSpy
        
        let response = DiaryModels.DeleteWorkoutSession.Response(index: 2)
        
        // Act
        sut.presentDeleteWorkoutSession(response: response)
        
        // Assert
        XCTAssertTrue(displayLogicSpy.displayDeleteWorkoutSessionCalled)
        XCTAssertEqual(displayLogicSpy.deleteWorkoutSessionViewModel?.index, 2)
    }
    
    // MARK: Present Workout Session Detail
    func testPresentWorkoutSessionDetail() {
        // Arrange
        let displayLogicSpy = DiaryDisplayLogicSpy()
        sut.viewController = displayLogicSpy
        
        let sessionID = UUID()
        let response = DiaryModels.ShowWorkoutSessionDetail.Response(sessionID: sessionID)
        
        // Act
        sut.presentWorkoutSessionDetail(response: response)
        
        // Assert
        XCTAssertTrue(displayLogicSpy.displayWorkoutSessionDetailCalled)
        XCTAssertEqual(displayLogicSpy.workoutSessionDetailViewModel?.sessionID, sessionID)
    }
}
