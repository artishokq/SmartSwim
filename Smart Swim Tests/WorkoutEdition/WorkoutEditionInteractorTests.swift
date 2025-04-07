//
//  WorkoutEditionInteractorTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 06.04.2025.
//

import XCTest
@testable import Smart_Swim

class WorkoutEditionInteractorTests: XCTestCase {
    // MARK: - Properties
    var sut: WorkoutEditionInteractor!
    var mockPresenter: MockWorkoutEditionPresenter!
    var mockCoreDataManager: MockWorkoutEditionCoreDataManager!
    
    // MARK: - Configure
    override func setUp() {
        super.setUp()
        mockPresenter = MockWorkoutEditionPresenter()
        mockCoreDataManager = MockWorkoutEditionCoreDataManager()
        
        sut = WorkoutEditionInteractor(coreDataManager: mockCoreDataManager)
        sut.presenter = mockPresenter
        
        sut.workoutIndex = 0
        sut.workouts = [createMockWorkoutEntity()]
    }
    
    override func tearDown() {
        sut = nil
        mockPresenter = nil
        mockCoreDataManager = nil
        super.tearDown()
    }
    
    // MARK: - Load Workout Tests
    func testLoadWorkout() {
        // Arrange
        let request = WorkoutEditionModels.LoadWorkout.Request(workoutIndex: 0)
        
        // Act
        sut.loadWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentLoadWorkoutCalled)
        XCTAssertEqual(mockPresenter.loadWorkoutResponse?.name, "Test Workout")
        XCTAssertEqual(mockPresenter.loadWorkoutResponse?.poolSize, .poolSize25)
        XCTAssertEqual(mockPresenter.loadWorkoutResponse?.exercises.count, 1)
    }
    
    func testLoadWorkoutWithInvalidIndex() {
        // Arrange
        let request = WorkoutEditionModels.LoadWorkout.Request(workoutIndex: 999)
        
        // Act
        sut.loadWorkout(request: request)
        
        // Assert
        XCTAssertFalse(mockPresenter.presentLoadWorkoutCalled)
    }
    
    // MARK: - Update Workout Validation Tests
    func testUpdateWorkoutWithEmptyName() {
        // Arrange
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "",
            poolSize: .poolSize25,
            exercises: [createSampleExercise()]
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertFalse(mockPresenter.updateWorkoutResponse?.success ?? true)
        XCTAssertEqual(mockPresenter.updateWorkoutResponse?.errorMessage, "Название тренировки не может быть пустым или состоять только из пробелов.")
    }
    
    func testUpdateWorkoutWithWhitespaceName() {
        // Arrange
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "   ",
            poolSize: .poolSize25,
            exercises: [createSampleExercise()]
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertFalse(mockPresenter.updateWorkoutResponse?.success ?? true)
        XCTAssertEqual(mockPresenter.updateWorkoutResponse?.errorMessage, "Название тренировки не может быть пустым или состоять только из пробелов.")
    }
    
    func testUpdateWorkoutWithLongName() {
        // Arrange
        let longName = String(repeating: "a", count: 31) // 31 characters, exceeding 30 limit
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: longName,
            poolSize: .poolSize25,
            exercises: [createSampleExercise()]
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertFalse(mockPresenter.updateWorkoutResponse?.success ?? true)
        XCTAssertEqual(mockPresenter.updateWorkoutResponse?.errorMessage, "Название тренировки не может превышать 30 символов.")
    }
    
    func testUpdateWorkoutWithNoExercises() {
        // Arrange
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "Valid Name",
            poolSize: .poolSize25,
            exercises: []
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertFalse(mockPresenter.updateWorkoutResponse?.success ?? true)
        XCTAssertEqual(mockPresenter.updateWorkoutResponse?.errorMessage, "Добавьте хотя бы одно упражнение.")
    }
    
    func testUpdateWorkoutWithInvalidMeters() {
        // Arrange
        let invalidExercise = Exercise(
            type: .main,
            meters: 0,
            repetitions: 4,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Test exercise"
        )
        
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "Valid Name",
            poolSize: .poolSize25,
            exercises: [invalidExercise]
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertFalse(mockPresenter.updateWorkoutResponse?.success ?? true)
        XCTAssertEqual(mockPresenter.updateWorkoutResponse?.errorMessage, "Количество метров должно быть больше 0.")
    }
    
    func testUpdateWorkoutWithInvalidRepetitions() {
        // Arrange
        let invalidExercise = Exercise(
            type: .main,
            meters: 100,
            repetitions: 0,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Test exercise"
        )
        
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "Valid Name",
            poolSize: .poolSize25,
            exercises: [invalidExercise]
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertFalse(mockPresenter.updateWorkoutResponse?.success ?? true)
        XCTAssertEqual(mockPresenter.updateWorkoutResponse?.errorMessage, "Количество повторений должно быть больше 0.")
    }
    
    func testUpdateWorkoutWithMissingIntervalValues() {
        // Arrange
        let invalidExercise = Exercise(
            type: .main,
            meters: 100,
            repetitions: 4,
            hasInterval: true,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: "Test exercise"
        )
        
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "Valid Name",
            poolSize: .poolSize25,
            exercises: [invalidExercise]
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertFalse(mockPresenter.updateWorkoutResponse?.success ?? true)
        XCTAssertEqual(mockPresenter.updateWorkoutResponse?.errorMessage, "Укажите минуты и секунды для интервала.")
    }
    
    func testUpdateWorkoutWithNegativeIntervalValues() {
        // Arrange
        let invalidExercise = Exercise(
            type: .main,
            meters: 100,
            repetitions: 4,
            hasInterval: true,
            intervalMinutes: -1,
            intervalSeconds: 30,
            style: .freestyle,
            description: "Test exercise"
        )
        
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "Valid Name",
            poolSize: .poolSize25,
            exercises: [invalidExercise]
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertFalse(mockPresenter.updateWorkoutResponse?.success ?? true)
        XCTAssertEqual(mockPresenter.updateWorkoutResponse?.errorMessage, "Минуты и секунды интервала должны быть неотрицательными.")
    }
    
    func testUpdateWorkoutSuccess() {
        // Arrange
        let validExercise = createSampleExercise()
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "Valid Workout",
            poolSize: .poolSize25,
            exercises: [validExercise]
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertTrue(mockPresenter.updateWorkoutResponse?.success ?? false)
        XCTAssertNil(mockPresenter.updateWorkoutResponse?.errorMessage)
    }
    
    func testUpdateWorkoutWithMultipleExercises() {
        // Arrange
        let exercises = [
            createSampleExercise(type: .warmup, meters: 200, style: .freestyle),
            createSampleExercise(type: .main, meters: 300, style: .butterfly),
            createSampleExercise(type: .cooldown, meters: 100, hasInterval: false, style: .backstroke)
        ]
        
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "Complex Workout",
            poolSize: .poolSize50,
            exercises: exercises
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertTrue(mockPresenter.updateWorkoutResponse?.success ?? false)
        XCTAssertNil(mockPresenter.updateWorkoutResponse?.errorMessage)
    }
    
    func testUpdateWorkoutWithTrimmedName() {
        // Arrange
        let request = WorkoutEditionModels.UpdateWorkout.Request(
            workoutIndex: 0,
            name: "  Workout with Spaces  ",
            poolSize: .poolSize25,
            exercises: [createSampleExercise()]
        )
        
        // Act
        sut.updateWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateWorkoutCalled)
        XCTAssertTrue(mockPresenter.updateWorkoutResponse?.success ?? false)
        XCTAssertNil(mockPresenter.updateWorkoutResponse?.errorMessage)
    }
    
    // MARK: - Pool Size Validation Tests
    func testPoolSizeValidation() {
        let validSizes = [25, 50]
        
        XCTAssertTrue(validSizes.contains(Int(PoolSize.poolSize25.rawValue)))
        XCTAssertTrue(validSizes.contains(Int(PoolSize.poolSize50.rawValue)))
        
        func validatePoolSize(_ poolSize: PoolSize) -> Bool {
            let allowedPoolSizes = [25, 50]
            return allowedPoolSizes.contains(Int(poolSize.rawValue))
        }
        
        XCTAssertTrue(validatePoolSize(.poolSize25))
        XCTAssertTrue(validatePoolSize(.poolSize50))
    }
    
    // MARK: - Exercise Management Tests
    func testAddExercise() {
        // Arrange
        let exercise = createSampleExercise()
        let request = WorkoutEditionModels.AddExercise.Request(exercise: exercise)
        
        // Act
        sut.addExercise(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentAddExerciseCalled)
        XCTAssertEqual(mockPresenter.addExerciseResponse?.exercises.count, 1)
        XCTAssertEqual(sut.exercises.count, 1)
    }
    
    func testDeleteExercise() {
        let exercise = createSampleExercise()
        sut.exercises = [exercise]
        
        // Arrange
        let request = WorkoutEditionModels.DeleteExercise.Request(index: 0)
        
        // Act
        sut.deleteExercise(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentDeleteExerciseCalled)
        XCTAssertEqual(mockPresenter.deleteExerciseResponse?.exercises.count, 0)
        XCTAssertEqual(sut.exercises.count, 0)
    }
    
    func testDeleteExerciseWithInvalidIndex() {
        let exercise = createSampleExercise()
        sut.exercises = [exercise]
        
        // Arrange
        let request = WorkoutEditionModels.DeleteExercise.Request(index: 999)
        
        // Act
        sut.deleteExercise(request: request)
        
        // Assert
        XCTAssertFalse(mockPresenter.presentDeleteExerciseCalled)
        XCTAssertEqual(sut.exercises.count, 1)
    }
    
    func testUpdateExercise() {
        let exercise = createSampleExercise()
        sut.exercises = [exercise]
        
        // Arrange
        let updatedExercise = Exercise(
            type: .warmup,
            meters: 200,
            repetitions: 2,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .backstroke,
            description: "Updated exercise"
        )
        
        let request = WorkoutEditionModels.UpdateExercise.Request(
            exercise: updatedExercise,
            index: 0
        )
        
        // Act
        sut.updateExercise(request: request)
        
        // Assert
        XCTAssertTrue(mockPresenter.presentUpdateExerciseCalled)
        XCTAssertEqual(mockPresenter.updateExerciseResponse?.exercises.count, 1)
        XCTAssertEqual(sut.exercises[0].type, .warmup)
        XCTAssertEqual(sut.exercises[0].meters, 200)
        XCTAssertEqual(sut.exercises[0].style, .backstroke)
        XCTAssertEqual(sut.exercises[0].description, "Updated exercise")
    }
    
    // MARK: - Helper Methods
    private func createSampleExercise(
        type: ExerciseType = .main,
        meters: Int16 = 100,
        repetitions: Int16 = 4,
        hasInterval: Bool = true,
        intervalMinutes: Int16? = 1,
        intervalSeconds: Int16? = 30,
        style: SwimStyle = .freestyle,
        description: String = "Test exercise"
    ) -> Exercise {
        return Exercise(
            type: type,
            meters: meters,
            repetitions: repetitions,
            hasInterval: hasInterval,
            intervalMinutes: intervalMinutes,
            intervalSeconds: intervalSeconds,
            style: style,
            description: description
        )
    }
    
    private func createMockWorkoutEntity() -> WorkoutEntity {
        let workout = MockWorkoutEntity()
        workout.mockName = "Test Workout"
        workout.mockPoolSize = 25
        
        let exercise = MockExerciseEntity()
        exercise.mockDescription = "Test exercise"
        exercise.mockHasInterval = true
        exercise.mockIntervalMinutes = 1
        exercise.mockIntervalSeconds = 30
        exercise.mockMeters = 100
        exercise.mockOrderIndex = 0
        exercise.mockRepetitions = 4
        exercise.mockStyle = 0
        exercise.mockType = 1
        
        workout.mockExercises = [exercise]
        
        return workout
    }
}

// MARK: - Mock Classes
class MockWorkoutEditionPresenter: WorkoutEditionPresentationLogic {
    var presentLoadWorkoutCalled = false
    var presentUpdateWorkoutCalled = false
    var presentAddExerciseCalled = false
    var presentDeleteExerciseCalled = false
    var presentUpdateExerciseCalled = false
    
    var loadWorkoutResponse: WorkoutEditionModels.LoadWorkout.Response?
    var updateWorkoutResponse: WorkoutEditionModels.UpdateWorkout.Response?
    var addExerciseResponse: WorkoutEditionModels.AddExercise.Response?
    var deleteExerciseResponse: WorkoutEditionModels.DeleteExercise.Response?
    var updateExerciseResponse: WorkoutEditionModels.UpdateExercise.Response?
    
    func presentLoadWorkout(response: WorkoutEditionModels.LoadWorkout.Response) {
        presentLoadWorkoutCalled = true
        loadWorkoutResponse = response
    }
    
    func presentUpdateWorkout(response: WorkoutEditionModels.UpdateWorkout.Response) {
        presentUpdateWorkoutCalled = true
        updateWorkoutResponse = response
    }
    
    func presentAddExercise(response: WorkoutEditionModels.AddExercise.Response) {
        presentAddExerciseCalled = true
        addExerciseResponse = response
    }
    
    func presentDeleteExercise(response: WorkoutEditionModels.DeleteExercise.Response) {
        presentDeleteExerciseCalled = true
        deleteExerciseResponse = response
    }
    
    func presentUpdateExercise(response: WorkoutEditionModels.UpdateExercise.Response) {
        presentUpdateExerciseCalled = true
        updateExerciseResponse = response
    }
}

class MockWorkoutEditionCoreDataManager: WorkoutEditionCoreDataManagerProtocol {
    func fetchAllWorkouts() -> [WorkoutEntity] {
        return []
    }
    
    func saveContext() -> Bool {
        return true
    }
    
    func deleteExercise(_ exercise: ExerciseEntity) {
    }
    
    func createExercise(for workout: WorkoutEntity,
                        description: String?,
                        style: Int16,
                        type: Int16,
                        hasInterval: Bool,
                        intervalMinutes: Int16,
                        intervalSeconds: Int16,
                        meters: Int16,
                        orderIndex: Int16,
                        repetitions: Int16) -> ExerciseEntity? {
        return MockExerciseEntity()
    }
}

class MockWorkoutEntity: WorkoutEntity {
    var mockName: String?
    var mockPoolSize: Int16 = 0
    var mockExercises: [ExerciseEntity] = []
    
    override var name: String? {
        get { return mockName }
        set { mockName = newValue }
    }
    
    override var poolSize: Int16 {
        get { return mockPoolSize }
        set { mockPoolSize = newValue }
    }
    
    override var exercises: NSSet? {
        get { return NSSet(array: mockExercises) }
        set { }
    }
}

class MockExerciseEntity: ExerciseEntity {
    var mockDescription: String?
    var mockHasInterval: Bool = false
    var mockIntervalMinutes: Int16 = 0
    var mockIntervalSeconds: Int16 = 0
    var mockMeters: Int16 = 0
    var mockOrderIndex: Int16 = 0
    var mockRepetitions: Int16 = 0
    var mockStyle: Int16 = 0
    var mockType: Int16 = 0
    var mockWorkout: WorkoutEntity?
    
    override var exerciseDescription: String? {
        get { return mockDescription }
        set { mockDescription = newValue }
    }
    
    override var hasInterval: Bool {
        get { return mockHasInterval }
        set { mockHasInterval = newValue }
    }
    
    override var intervalMinutes: Int16 {
        get { return mockIntervalMinutes }
        set { mockIntervalMinutes = newValue }
    }
    
    override var intervalSeconds: Int16 {
        get { return mockIntervalSeconds }
        set { mockIntervalSeconds = newValue }
    }
    
    override var meters: Int16 {
        get { return mockMeters }
        set { mockMeters = newValue }
    }
    
    override var orderIndex: Int16 {
        get { return mockOrderIndex }
        set { mockOrderIndex = newValue }
    }
    
    override var repetitions: Int16 {
        get { return mockRepetitions }
        set { mockRepetitions = newValue }
    }
    
    override var style: Int16 {
        get { return mockStyle }
        set { mockStyle = newValue }
    }
    
    override var type: Int16 {
        get { return mockType }
        set { mockType = newValue }
    }
    
    override var workout: WorkoutEntity? {
        get { return mockWorkout }
        set { mockWorkout = newValue }
    }
}
