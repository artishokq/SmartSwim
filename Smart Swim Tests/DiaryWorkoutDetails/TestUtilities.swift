//
//  TestUtilities.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 11.04.2025.
//

import XCTest
import CoreData
@testable import Smart_Swim

// MARK: - Mock Entities
class MockWorkoutSessionEntity: WorkoutSessionEntity {
    private var _date: Date? = Date()
    override var date: Date? {
        get { return _date }
        set { _date = newValue }
    }
    
    private var _totalTime: Double = 0.0
    override var totalTime: Double {
        get { return _totalTime }
        set { _totalTime = newValue }
    }
    
    private var _totalCalories: Double = 0.0
    override var totalCalories: Double {
        get { return _totalCalories }
        set { _totalCalories = newValue }
    }
    
    private var _poolSize: Int16 = 25
    override var poolSize: Int16 {
        get { return _poolSize }
        set { _poolSize = newValue }
    }
    
    private var _workoutName: String? = "Test Workout"
    override var workoutName: String? {
        get { return _workoutName }
        set { _workoutName = newValue }
    }
    
    private var _recommendation: String?
    override var recommendation: String? {
        get { return _recommendation }
        set { _recommendation = newValue }
    }
    
    var mockExerciseSessions: [MockExerciseSessionEntity] = []
    override var exerciseSessions: NSSet? {
        get { return NSSet(array: mockExerciseSessions) }
        set {
            if let array = newValue?.allObjects as? [MockExerciseSessionEntity] {
                mockExerciseSessions = array
            }
        }
    }
}

class MockExerciseSessionEntity: ExerciseSessionEntity {
    private var _orderIndex: Int16 = 0
    override var orderIndex: Int16 {
        get { return _orderIndex }
        set { _orderIndex = newValue }
    }
    
    private var _meters: Int16 = 0
    override var meters: Int16 {
        get { return _meters }
        set { _meters = newValue }
    }
    
    private var _repetitions: Int16 = 1
    override var repetitions: Int16 {
        get { return _repetitions }
        set { _repetitions = newValue }
    }
    
    private var _hasInterval: Bool = false
    override var hasInterval: Bool {
        get { return _hasInterval }
        set { _hasInterval = newValue }
    }
    
    private var _intervalMinutes: Int16 = 0
    override var intervalMinutes: Int16 {
        get { return _intervalMinutes }
        set { _intervalMinutes = newValue }
    }
    
    private var _intervalSeconds: Int16 = 0
    override var intervalSeconds: Int16 {
        get { return _intervalSeconds }
        set { _intervalSeconds = newValue }
    }
    
    private var _type: Int16 = 0
    override var type: Int16 {
        get { return _type }
        set { _type = newValue }
    }
    
    private var _style: Int16 = 0
    override var style: Int16 {
        get { return _style }
        set { _style = newValue }
    }
    
    var mockLaps: [MockLapSessionEntity] = []
    override var laps: NSSet? {
        get { return NSSet(array: mockLaps) }
        set {
            if let lapsArray = newValue?.allObjects as? [MockLapSessionEntity] {
                mockLaps = lapsArray
            }
        }
    }
}

class MockLapSessionEntity: LapSessionEntity {
    private var _lapNumber: Int16 = 0
    override var lapNumber: Int16 {
        get { return _lapNumber }
        set { _lapNumber = newValue }
    }
    
    private var _heartRate: Double = 0.0
    override var heartRate: Double {
        get { return _heartRate }
        set { _heartRate = newValue }
    }
    
    private var _strokes: Int16 = 0
    override var strokes: Int16 {
        get { return _strokes }
        set { _strokes = newValue }
    }
}

class MockHeartRateEntity: HeartRateEntity {
    private var _value: Double = 0.0
    override var value: Double {
        get { return _value }
        set { _value = newValue }
    }
    
    private var _timestamp: Date? = Date()
    override var timestamp: Date? {
        get { return _timestamp }
        set { _timestamp = newValue }
    }
}

// MARK: - Spy Classes
class WorkoutSessionDetailPresentationLogicSpy: WorkoutSessionDetailPresentationLogic {
    var presentSessionDetailsCalled = false
    var presentSessionDetailsResponse: WorkoutSessionDetailModels.FetchSessionDetails.Response?
    
    var presentRecommendationCalled = false
    var presentRecommendationResponse: WorkoutSessionDetailModels.FetchRecommendation.Response?
    
    func presentSessionDetails(response: WorkoutSessionDetailModels.FetchSessionDetails.Response) {
        presentSessionDetailsCalled = true
        presentSessionDetailsResponse = response
    }
    
    func presentRecommendation(response: WorkoutSessionDetailModels.FetchRecommendation.Response) {
        presentRecommendationCalled = true
        presentRecommendationResponse = response
    }
}

class WorkoutSessionDetailDisplayLogicSpy: WorkoutSessionDetailDisplayLogic {
    var displaySessionDetailsCalled = false
    var displaySessionDetailsViewModel: WorkoutSessionDetailModels.FetchSessionDetails.ViewModel?
    
    var displayRecommendationCalled = false
    var displayRecommendationViewModel: WorkoutSessionDetailModels.FetchRecommendation.ViewModel?
    
    func displaySessionDetails(viewModel: WorkoutSessionDetailModels.FetchSessionDetails.ViewModel) {
        displaySessionDetailsCalled = true
        displaySessionDetailsViewModel = viewModel
    }
    
    func displayRecommendation(viewModel: WorkoutSessionDetailModels.FetchRecommendation.ViewModel) {
        displayRecommendationCalled = true
        displayRecommendationViewModel = viewModel
    }
}

// MARK: - Core Data Manager Mock
class CoreDataManagerMock {
    static let shared = CoreDataManagerMock()
    
    var shouldReturnWorkoutSession = true
    var workoutSession: MockWorkoutSessionEntity = MockWorkoutSessionEntity()
    var exerciseSessions: [MockExerciseSessionEntity] = []
    
    var fetchWorkoutSessionCalled = false
    var fetchExerciseSessionsCalled = false
    var fetchLapSessionsCalled = false
    var fetchHeartRateReadingsCalled = false
    var updateWorkoutSessionRecommendationCalled = false
    
    func toWorkoutSessionEntity(_ mock: MockWorkoutSessionEntity) -> WorkoutSessionEntity? {
        return mock
    }
    
    func fetchWorkoutSession(byID id: UUID) -> WorkoutSessionEntity? {
        fetchWorkoutSessionCalled = true
        return shouldReturnWorkoutSession ? toWorkoutSessionEntity(workoutSession) : nil
    }
    
    func fetchExerciseSessions(for session: WorkoutSessionEntity) -> [ExerciseSessionEntity] {
        fetchExerciseSessionsCalled = true
        return session.exerciseSessions?.allObjects as? [ExerciseSessionEntity] ?? []
    }
    
    func fetchLapSessions(for exercise: ExerciseSessionEntity) -> [LapSessionEntity] {
        fetchLapSessionsCalled = true
        return exercise.laps?.allObjects as? [LapSessionEntity] ?? []
    }
    
    func fetchHeartRateReadings(for exercise: ExerciseSessionEntity) -> [HeartRateEntity] {
        fetchHeartRateReadingsCalled = true
        return []
    }
    
    func updateWorkoutSessionRecommendation(_ session: WorkoutSessionEntity, recommendation: String) {
        updateWorkoutSessionRecommendationCalled = true
    }
}

// MARK: - Test Helper Functions
func createMockWorkoutSession() -> MockWorkoutSessionEntity {
    let session = MockWorkoutSessionEntity()
    session.mockExerciseSessions = []
    session.date = Date()
    session.totalTime = 3600
    session.totalCalories = 500
    session.poolSize = 25
    session.workoutName = "Test Workout"
    session.recommendation = nil
    return session
}

func createMockExerciseSessions() -> [MockExerciseSessionEntity] {
    let exercise1 = MockExerciseSessionEntity()
    exercise1.orderIndex = 0
    exercise1.meters = 500
    exercise1.repetitions = 1
    exercise1.hasInterval = true
    exercise1.intervalMinutes = 1
    exercise1.intervalSeconds = 30
    exercise1.type = 0
    exercise1.style = 0
    exercise1.mockLaps = createMockLapSessions(count: 2, startingHeartRate: 150, startingStrokes: 20)
    
    let exercise2 = MockExerciseSessionEntity()
    exercise2.orderIndex = 1
    exercise2.meters = 500
    exercise2.repetitions = 1
    exercise2.hasInterval = false
    exercise2.type = 1
    exercise2.style = 1
    exercise2.mockLaps = createMockLapSessions(count: 2, startingHeartRate: 170, startingStrokes: 25)
    
    return [exercise1, exercise2]
}

func createMockLapSessions(count: Int, startingHeartRate: Double, startingStrokes: Int16) -> [MockLapSessionEntity] {
    var laps: [MockLapSessionEntity] = []
    for i in 0..<count {
        let lap = MockLapSessionEntity()
        lap.lapNumber = Int16(i + 1)
        lap.heartRate = startingHeartRate + Double(i * 10)
        lap.strokes = startingStrokes + Int16(i * 5)
        laps.append(lap)
    }
    return laps
}

func createHeartRateReadings(count: Int, startingValue: Double) -> [MockHeartRateEntity] {
    var readings: [MockHeartRateEntity] = []
    for i in 0..<count {
        let reading = MockHeartRateEntity()
        reading.value = startingValue + Double(i)
        readings.append(reading)
    }
    return readings
}
