//
//  WorkoutInteractorTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 05.04.2025.
//

import XCTest
import CoreData
@testable import Smart_Swim

final class WorkoutInteractorTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: WorkoutInteractor!
    
    // MARK: - Test Doubles
    class WorkoutPresentationLogicSpy: WorkoutPresentationLogic {
        var presentWorkoutCreationCalled = false
        var presentInfoCalled = false
        var presentWorkoutsCalled = false
        var presentDeleteWorkoutCalled = false
        var presentEditWorkoutCalled = false
        
        var workoutCreationResponse: WorkoutModels.Create.Response?
        var infoResponse: WorkoutModels.Info.Response?
        var workoutsResponse: WorkoutModels.FetchWorkouts.Response?
        var deleteWorkoutResponse: WorkoutModels.DeleteWorkout.Response?
        var editWorkoutResponse: WorkoutModels.EditWorkout.Response?
        
        func presentWorkoutCreation(response: WorkoutModels.Create.Response) {
            presentWorkoutCreationCalled = true
            workoutCreationResponse = response
        }
        
        func presentInfo(response: WorkoutModels.Info.Response) {
            presentInfoCalled = true
            infoResponse = response
        }
        
        func presentWorkouts(response: WorkoutModels.FetchWorkouts.Response) {
            presentWorkoutsCalled = true
            workoutsResponse = response
        }
        
        func presentDeleteWorkout(response: WorkoutModels.DeleteWorkout.Response) {
            presentDeleteWorkoutCalled = true
            deleteWorkoutResponse = response
        }
        
        func presentEditWorkout(response: WorkoutModels.EditWorkout.Response) {
            presentEditWorkoutCalled = true
            editWorkoutResponse = response
        }
    }
    
    // MARK: Mock Core Data Manager
    class CoreDataManagerMock: CoreDataManagerProtocol {
        var mockWorkouts: [WorkoutEntity] = []
        var fetchAllWorkoutsCalled = false
        var deleteWorkoutCalled = false
        var deletedWorkout: WorkoutEntity?
        
        func fetchAllWorkouts() -> [WorkoutEntity] {
            fetchAllWorkoutsCalled = true
            return mockWorkouts
        }
        
        func deleteWorkout(_ workout: WorkoutEntity) {
            deleteWorkoutCalled = true
            deletedWorkout = workout
            
            if let index = mockWorkouts.firstIndex(where: { $0 === workout }) {
                mockWorkouts.remove(at: index)
            }
        }
    }
    
    // MARK: Mock WorkoutEntity and ExerciseEntity
    class MockWorkoutEntity: WorkoutEntity {
        var mockName: String?
        var mockPoolSize: Int16 = 0
        var mockExercises: NSSet?
        
        override var name: String? {
            get { return mockName }
            set { mockName = newValue }
        }
        
        override var poolSize: Int16 {
            get { return mockPoolSize }
            set { mockPoolSize = newValue }
        }
        
        override var exercises: NSSet? {
            get { return mockExercises }
            set { mockExercises = newValue }
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
    
    var mockCoreDataManager: CoreDataManagerMock!
    var presentationLogicSpy: WorkoutPresentationLogicSpy!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        
        mockCoreDataManager = CoreDataManagerMock()
        presentationLogicSpy = WorkoutPresentationLogicSpy()
        configureWorkoutInteractor()
    }
    
    override func tearDown() {
        sut = nil
        mockCoreDataManager = nil
        presentationLogicSpy = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureWorkoutInteractor() {
        sut = WorkoutInteractor(coreDataManager: mockCoreDataManager)
        sut.presenter = presentationLogicSpy
    }
    
    // MARK: - Mock Data Creation
    func createMockWorkoutEntities() -> [WorkoutEntity] {
        let workout1 = MockWorkoutEntity()
        workout1.mockName = "Test Workout 1"
        workout1.mockPoolSize = 25
        
        let exercise1 = MockExerciseEntity()
        exercise1.mockDescription = "First exercise"
        exercise1.mockMeters = 100
        exercise1.mockRepetitions = 2
        exercise1.mockStyle = SwimStyle.freestyle.rawValue
        exercise1.mockType = ExerciseType.warmup.rawValue
        exercise1.mockOrderIndex = 0
        exercise1.mockWorkout = workout1
        
        let exercise2 = MockExerciseEntity()
        exercise2.mockDescription = "Second exercise"
        exercise2.mockMeters = 200
        exercise2.mockRepetitions = 4
        exercise2.mockStyle = SwimStyle.backstroke.rawValue
        exercise2.mockType = ExerciseType.main.rawValue
        exercise2.mockHasInterval = true
        exercise2.mockIntervalMinutes = 1
        exercise2.mockIntervalSeconds = 30
        exercise2.mockOrderIndex = 1
        exercise2.mockWorkout = workout1
        
        workout1.mockExercises = NSSet(array: [exercise1, exercise2])
        
        let workout2 = MockWorkoutEntity()
        workout2.mockName = "Test Workout 2"
        workout2.mockPoolSize = 50
        
        let exercise3 = MockExerciseEntity()
        exercise3.mockDescription = "Cooldown exercise"
        exercise3.mockMeters = 50
        exercise3.mockRepetitions = 1
        exercise3.mockStyle = SwimStyle.breaststroke.rawValue
        exercise3.mockType = ExerciseType.cooldown.rawValue
        exercise3.mockOrderIndex = 0
        exercise3.mockWorkout = workout2
        
        workout2.mockExercises = NSSet(array: [exercise3])
        
        return [workout1, workout2]
    }
    
    
    // MARK: Create Workout
    func testCreateWorkout() {
        // Arrange
        let request = WorkoutModels.Create.Request()
        
        // Act
        sut.createWorkout(request: request)
        
        // Assert
        XCTAssertTrue(presentationLogicSpy.presentWorkoutCreationCalled)
    }
    
    // MARK: Show Info
    func testShowInfo() {
        // Arrange
        let request = WorkoutModels.Info.Request()
        
        // Act
        sut.showInfo(request: request)
        
        // Assert
        XCTAssertTrue(presentationLogicSpy.presentInfoCalled)
    }
    
    // MARK: Fetch Workouts
    func testFetchWorkoutsWithEmptyList() {
        // Arrange
        mockCoreDataManager.mockWorkouts = []
        let request = WorkoutModels.FetchWorkouts.Request()
        
        // Act
        sut.fetchWorkouts(request: request)
        
        // Assert
        XCTAssertTrue(mockCoreDataManager.fetchAllWorkoutsCalled)
        XCTAssertTrue(presentationLogicSpy.presentWorkoutsCalled)
        XCTAssertEqual(presentationLogicSpy.workoutsResponse?.workouts.count, 0)
    }
    
    func testFetchWorkoutsWithMultipleWorkouts() {
        // Arrange
        let mockWorkouts = createMockWorkoutEntities()
        mockCoreDataManager.mockWorkouts = mockWorkouts
        let request = WorkoutModels.FetchWorkouts.Request()
        
        // Act
        sut.fetchWorkouts(request: request)
        
        // Assert
        XCTAssertTrue(mockCoreDataManager.fetchAllWorkoutsCalled)
        XCTAssertTrue(presentationLogicSpy.presentWorkoutsCalled)
        XCTAssertEqual(presentationLogicSpy.workoutsResponse?.workouts.count, 2)
        
        let firstWorkout = presentationLogicSpy.workoutsResponse?.workouts.first
        XCTAssertEqual(firstWorkout?.name, "Test Workout 1")
        XCTAssertEqual(firstWorkout?.exercises.count, 2)
        
        let secondWorkout = presentationLogicSpy.workoutsResponse?.workouts.last
        XCTAssertEqual(secondWorkout?.name, "Test Workout 2")
        XCTAssertEqual(secondWorkout?.exercises.count, 1)
        
        XCTAssertEqual(firstWorkout?.totalVolume, 1000)
    }
    
    // MARK: Delete Workout
    func testDeleteWorkout() {
        // Arrange
        let mockWorkouts = createMockWorkoutEntities()
        sut.workouts = mockWorkouts
        mockCoreDataManager.mockWorkouts = mockWorkouts
        
        let request = WorkoutModels.DeleteWorkout.Request(index: 0)
        
        // Act
        sut.deleteWorkout(request: request)
        
        // Assert
        XCTAssertTrue(mockCoreDataManager.deleteWorkoutCalled)
        XCTAssertTrue(presentationLogicSpy.presentDeleteWorkoutCalled)
        XCTAssertEqual(presentationLogicSpy.deleteWorkoutResponse?.deletedIndex, 0)
        XCTAssertEqual(sut.workouts?.count, 1)
    }
    
    func testDeleteWorkoutWithInvalidIndex() {
        // Arrange
        let mockWorkouts = createMockWorkoutEntities()
        sut.workouts = mockWorkouts
        mockCoreDataManager.mockWorkouts = mockWorkouts
        
        let request = WorkoutModels.DeleteWorkout.Request(index: 5)
        
        // Act
        sut.deleteWorkout(request: request)
        
        // Assert
        XCTAssertFalse(mockCoreDataManager.deleteWorkoutCalled)
        XCTAssertFalse(presentationLogicSpy.presentDeleteWorkoutCalled)
        XCTAssertEqual(sut.workouts?.count, 2)
    }
    
    // MARK: Edit Workout
    func testEditWorkout() {
        // Arrange
        let request = WorkoutModels.EditWorkout.Request(index: 1)
        
        // Act
        sut.editWorkout(request: request)
        
        // Assert
        XCTAssertTrue(presentationLogicSpy.presentEditWorkoutCalled)
        XCTAssertEqual(presentationLogicSpy.editWorkoutResponse?.index, 1)
    }
    
    // MARK: Helper Methods
    func testGetStyleDescription() {
        // Arrange
        let styles: [SwimStyle] = [.freestyle, .breaststroke, .backstroke, .butterfly, .medley, .any]
        let expected = ["кроль", "брасс", "на спине", "баттерфляй", "комплекс", "любой стиль"]
        
        // Act and Assert
        for (index, style) in styles.enumerated() {
            let mirror = Mirror(reflecting: sut as Any)
            if let getStyleDescriptionMethod = mirror.children.first(where: { $0.label == "getStyleDescription" }) {
                if let method = getStyleDescriptionMethod.value as? (SwimStyle) -> String {
                    let result = method(style)
                    XCTAssertEqual(result, expected[index])
                }
            }
        }
    }
    
    func testGetTypeDescription() {
        // Arrange
        let types: [ExerciseType] = [.warmup, .main, .cooldown]
        let expected: [String?] = ["Разминка", nil, "Заминка"]
        
        // Act and Assert
        for (index, type) in types.enumerated() {
            let mirror = Mirror(reflecting: sut as Any)
            if let getTypeDescriptionMethod = mirror.children.first(where: { $0.label == "getTypeDescription" }) {
                if let method = getTypeDescriptionMethod.value as? (ExerciseType) -> String? {
                    let result = method(type)
                    XCTAssertEqual(result, expected[index])
                }
            }
        }
    }
    
    func testFormatExercise() {
        // Arrange
        let exercise = MockExerciseEntity()
        exercise.mockDescription = "Test description"
        exercise.mockMeters = 100
        exercise.mockRepetitions = 2
        exercise.mockStyle = SwimStyle.freestyle.rawValue
        exercise.mockType = ExerciseType.warmup.rawValue
        exercise.mockHasInterval = true
        exercise.mockIntervalMinutes = 1
        exercise.mockIntervalSeconds = 30
        exercise.mockOrderIndex = 0
        
        // Act
        let mirror = Mirror(reflecting: sut as Any)
        if let formatExerciseMethod = mirror.children.first(where: { $0.label == "formatExercise" }) {
            if let method = formatExerciseMethod.value as? (ExerciseEntity, Int) -> String {
                let result = method(exercise, 0)
                
                // Assert
                XCTAssertTrue(result.contains("1. "))
                XCTAssertTrue(result.contains("Разминка"))
                XCTAssertTrue(result.contains("2x100м"))
                XCTAssertTrue(result.contains("кроль"))
                XCTAssertTrue(result.contains("Режим 1 мин 30 сек"))
                XCTAssertTrue(result.contains("Test description"))
            }
        }
    }
}
