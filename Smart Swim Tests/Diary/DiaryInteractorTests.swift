//
//  DiaryInteractorTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 06.04.2025.
//

import XCTest
import CoreData
@testable import Smart_Swim

final class DiaryInteractorTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: DiaryInteractor!
    
    // MARK: - Test Doubles
    class DiaryPresentationLogicSpy: DiaryPresentationLogic {
        var presentStartsCalled = false
        var presentDeleteStartCalled = false
        var presentStartDetailCalled = false
        var presentCreateStartCalled = false
        var presentWorkoutSessionsCalled = false
        var presentDeleteWorkoutSessionCalled = false
        var presentWorkoutSessionDetailCalled = false
        
        var startsResponse: DiaryModels.FetchStarts.Response?
        var deleteStartResponse: DiaryModels.DeleteStart.Response?
        var startDetailResponse: DiaryModels.ShowStartDetail.Response?
        var createStartResponse: DiaryModels.CreateStart.Response?
        var workoutSessionsResponse: DiaryModels.FetchWorkoutSessions.Response?
        var deleteWorkoutSessionResponse: DiaryModels.DeleteWorkoutSession.Response?
        var workoutSessionDetailResponse: DiaryModels.ShowWorkoutSessionDetail.Response?
        
        func presentStarts(response: DiaryModels.FetchStarts.Response) {
            presentStartsCalled = true
            startsResponse = response
        }
        
        func presentDeleteStart(response: DiaryModels.DeleteStart.Response) {
            presentDeleteStartCalled = true
            deleteStartResponse = response
        }
        
        func presentStartDetail(response: DiaryModels.ShowStartDetail.Response) {
            presentStartDetailCalled = true
            startDetailResponse = response
        }
        
        func presentCreateStart(response: DiaryModels.CreateStart.Response) {
            presentCreateStartCalled = true
            createStartResponse = response
        }
        
        func presentWorkoutSessions(response: DiaryModels.FetchWorkoutSessions.Response) {
            presentWorkoutSessionsCalled = true
            workoutSessionsResponse = response
        }
        
        func presentDeleteWorkoutSession(response: DiaryModels.DeleteWorkoutSession.Response) {
            presentDeleteWorkoutSessionCalled = true
            deleteWorkoutSessionResponse = response
        }
        
        func presentWorkoutSessionDetail(response: DiaryModels.ShowWorkoutSessionDetail.Response) {
            presentWorkoutSessionDetailCalled = true
            workoutSessionDetailResponse = response
        }
    }
    
    class CoreDataManagerMock: DiaryCoreDataManagerProtocol {
        var mockStarts: [StartEntity] = []
        var mockWorkoutSessions: [WorkoutSessionEntity] = []
        var mockExerciseSessions: [ExerciseSessionEntity] = []
        
        var fetchAllStartsCalled = false
        var fetchStartByIDCalled = false
        var deleteStartCalled = false
        var fetchAllWorkoutSessionsCalled = false
        var fetchWorkoutSessionByIDCalled = false
        var deleteWorkoutSessionCalled = false
        var fetchExerciseSessionsCalled = false
        
        var fetchStartByIDArgument: NSManagedObjectID?
        var deleteStartArgument: StartEntity?
        var fetchWorkoutSessionByIDArgument: UUID?
        var deleteWorkoutSessionArgument: WorkoutSessionEntity?
        var fetchExerciseSessionsArgument: WorkoutSessionEntity?
        
        func fetchAllStarts() -> [StartEntity] {
            fetchAllStartsCalled = true
            return mockStarts
        }
        
        func fetchStart(byID id: NSManagedObjectID) -> StartEntity? {
            fetchStartByIDCalled = true
            fetchStartByIDArgument = id
            return mockStarts.first { $0.objectID == id }
        }
        
        func deleteStart(_ start: StartEntity) {
            deleteStartCalled = true
            deleteStartArgument = start
            if let index = mockStarts.firstIndex(where: { $0 === start }) {
                mockStarts.remove(at: index)
            }
        }
        
        func fetchAllWorkoutSessions() -> [WorkoutSessionEntity] {
            fetchAllWorkoutSessionsCalled = true
            return mockWorkoutSessions
        }
        
        func fetchWorkoutSession(byID id: UUID) -> WorkoutSessionEntity? {
            fetchWorkoutSessionByIDCalled = true
            fetchWorkoutSessionByIDArgument = id
            return mockWorkoutSessions.first { $0.id == id }
        }
        
        func deleteWorkoutSession(_ session: WorkoutSessionEntity) {
            deleteWorkoutSessionCalled = true
            deleteWorkoutSessionArgument = session
            if let index = mockWorkoutSessions.firstIndex(where: { $0 === session }) {
                mockWorkoutSessions.remove(at: index)
            }
        }
        
        func fetchExerciseSessions(for session: WorkoutSessionEntity) -> [ExerciseSessionEntity] {
            fetchExerciseSessionsCalled = true
            fetchExerciseSessionsArgument = session
            return mockExerciseSessions.filter { $0.workoutSession === session }
        }
    }
    
    class MockStartEntity: StartEntity {
        var mockObjectID: NSManagedObjectID!
        var mockDate: Date!
        var mockTotalMeters: Int16 = 0
        var mockSwimmingStyle: Int16 = 0
        var mockTotalTime: Double = 0
        
        override var objectID: NSManagedObjectID {
            return mockObjectID
        }
        
        override var date: Date {
            get { return mockDate }
            set { mockDate = newValue }
        }
        
        override var totalMeters: Int16 {
            get { return mockTotalMeters }
            set { mockTotalMeters = newValue }
        }
        
        override var swimmingStyle: Int16 {
            get { return mockSwimmingStyle }
            set { mockSwimmingStyle = newValue }
        }
        
        override var totalTime: Double {
            get { return mockTotalTime }
            set { mockTotalTime = newValue }
        }
    }
    
    class MockWorkoutSessionEntity: WorkoutSessionEntity {
        var mockId: UUID!
        var mockDate: Date!
        var mockTotalTime: Double = 0
        var mockPoolSize: Int16 = 0
        var mockWorkoutName: String?
        var mockExerciseSessions: NSSet?
        
        override var id: UUID? {
            get { return mockId }
            set { mockId = newValue }
        }
        
        override var date: Date? {
            get { return mockDate }
            set { mockDate = newValue }
        }
        
        override var totalTime: Double {
            get { return mockTotalTime }
            set { mockTotalTime = newValue }
        }
        
        override var poolSize: Int16 {
            get { return mockPoolSize }
            set { mockPoolSize = newValue }
        }
        
        override var workoutName: String? {
            get { return mockWorkoutName }
            set { mockWorkoutName = newValue }
        }
        
        override var exerciseSessions: NSSet? {
            get { return mockExerciseSessions }
            set { mockExerciseSessions = newValue }
        }
    }
    
    class MockExerciseSessionEntity: ExerciseSessionEntity {
        var mockOrderIndex: Int16 = 0
        var mockExerciseDescription: String?
        var mockStyle: Int16 = 0
        var mockType: Int16 = 0
        var mockMeters: Int16 = 0
        var mockRepetitions: Int16 = 0
        var mockHasInterval: Bool = false
        var mockIntervalMinutes: Int16 = 0
        var mockIntervalSeconds: Int16 = 0
        var mockWorkoutSession: WorkoutSessionEntity?
        
        override var orderIndex: Int16 {
            get { return mockOrderIndex }
            set { mockOrderIndex = newValue }
        }
        
        override var exerciseDescription: String? {
            get { return mockExerciseDescription }
            set { mockExerciseDescription = newValue }
        }
        
        override var style: Int16 {
            get { return mockStyle }
            set { mockStyle = newValue }
        }
        
        override var type: Int16 {
            get { return mockType }
            set { mockType = newValue }
        }
        
        override var meters: Int16 {
            get { return mockMeters }
            set { mockMeters = newValue }
        }
        
        override var repetitions: Int16 {
            get { return mockRepetitions }
            set { mockRepetitions = newValue }
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
        
        override var workoutSession: WorkoutSessionEntity? {
            get { return mockWorkoutSession }
            set { mockWorkoutSession = newValue }
        }
    }
    
    class MockManagedObjectID: NSManagedObjectID, @unchecked Sendable {
        override func isEqual(_ object: Any?) -> Bool {
            if let objectID = object as? MockManagedObjectID {
                return self === objectID
            }
            return false
        }
    }
    
    // MARK: - Test Properties
    var presentationLogicSpy: DiaryPresentationLogicSpy!
    var coreDataManagerMock: CoreDataManagerMock!
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        presentationLogicSpy = DiaryPresentationLogicSpy()
        coreDataManagerMock = CoreDataManagerMock()
        configureDiaryInteractor()
    }
    
    override func tearDown() {
        sut = nil
        presentationLogicSpy = nil
        coreDataManagerMock = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureDiaryInteractor() {
        sut = DiaryInteractor(coreDataManager: coreDataManagerMock)
        sut.presenter = presentationLogicSpy
    }
    
    // MARK: - Mock Data Setup
    func setupMockStartEntities() -> [StartEntity] {
        let start1 = MockStartEntity()
        start1.mockObjectID = MockManagedObjectID()
        start1.mockDate = Date()
        start1.mockTotalMeters = 1000
        start1.mockSwimmingStyle = SwimStyle.freestyle.rawValue
        start1.mockTotalTime = 720.5
        
        let start2 = MockStartEntity()
        start2.mockObjectID = MockManagedObjectID()
        start2.mockDate = Date().addingTimeInterval(-86400)
        start2.mockTotalMeters = 2000
        start2.mockSwimmingStyle = SwimStyle.backstroke.rawValue
        start2.mockTotalTime = 1500.0
        
        return [start1, start2]
    }
    
    func setupMockWorkoutSessionEntities() -> [WorkoutSessionEntity] {
        let session1 = MockWorkoutSessionEntity()
        session1.mockId = UUID()
        session1.mockDate = Date()
        session1.mockTotalTime = 3600
        session1.mockPoolSize = 25
        session1.mockWorkoutName = "Morning Workout"
        
        let session2 = MockWorkoutSessionEntity()
        session2.mockId = UUID()
        session2.mockDate = Date().addingTimeInterval(-86400)
        session2.mockTotalTime = 4500
        session2.mockPoolSize = 50
        session2.mockWorkoutName = "Evening Workout"
        
        return [session1, session2]
    }
    
    func setupMockExerciseSessionEntities(for session: WorkoutSessionEntity) -> [ExerciseSessionEntity] {
        let exercise1 = MockExerciseSessionEntity()
        exercise1.mockOrderIndex = 0
        exercise1.mockExerciseDescription = "Warmup"
        exercise1.mockStyle = SwimStyle.freestyle.rawValue
        exercise1.mockType = ExerciseType.warmup.rawValue
        exercise1.mockMeters = 100
        exercise1.mockRepetitions = 2
        exercise1.mockHasInterval = false
        exercise1.mockWorkoutSession = session
        
        let exercise2 = MockExerciseSessionEntity()
        exercise2.mockOrderIndex = 1
        exercise2.mockExerciseDescription = "Main set"
        exercise2.mockStyle = SwimStyle.backstroke.rawValue
        exercise2.mockType = ExerciseType.main.rawValue
        exercise2.mockMeters = 200
        exercise2.mockRepetitions = 4
        exercise2.mockHasInterval = true
        exercise2.mockIntervalMinutes = 1
        exercise2.mockIntervalSeconds = 30
        exercise2.mockWorkoutSession = session
        
        return [exercise1, exercise2]
    }
    
    // MARK: Fetch Starts
    func testFetchStarts() {
        // Arrange
        let mockStarts = setupMockStartEntities()
        coreDataManagerMock.mockStarts = mockStarts
        
        // Act
        sut.fetchStarts(request: DiaryModels.FetchStarts.Request())
        
        // Assert
        XCTAssertTrue(coreDataManagerMock.fetchAllStartsCalled)
        XCTAssertTrue(presentationLogicSpy.presentStartsCalled)
        XCTAssertEqual(presentationLogicSpy.startsResponse?.starts.count, 2)
        
        let firstStart = presentationLogicSpy.startsResponse?.starts.first
        XCTAssertEqual(firstStart?.totalMeters, 1000)
        XCTAssertEqual(firstStart?.swimmingStyle, SwimStyle.freestyle.rawValue)
        XCTAssertEqual(firstStart?.totalTime, 720.5)
        
        XCTAssertEqual(sut.starts?.count, 2)
    }
    
    // MARK: Delete Start
    func testDeleteStart() {
        // Arrange
        let mockStarts = setupMockStartEntities()
        coreDataManagerMock.mockStarts = mockStarts
        sut.starts = mockStarts
        
        let startToDelete = mockStarts[0]
        let startID = startToDelete.objectID
        
        // Act
        sut.deleteStart(request: DiaryModels.DeleteStart.Request(id: startID, index: 0))
        
        // Assert
        XCTAssertTrue(coreDataManagerMock.fetchStartByIDCalled)
        XCTAssertEqual(coreDataManagerMock.fetchStartByIDArgument, startID)
        XCTAssertTrue(coreDataManagerMock.deleteStartCalled)
        XCTAssertEqual(coreDataManagerMock.deleteStartArgument, startToDelete)
        XCTAssertTrue(presentationLogicSpy.presentDeleteStartCalled)
        XCTAssertEqual(presentationLogicSpy.deleteStartResponse?.index, 0)
        XCTAssertEqual(sut.starts?.count, 1)
    }
    
    // MARK: Show Start Detail
    func testShowStartDetail() {
        // Arrange
        let startID = MockManagedObjectID()
        
        // Act
        sut.showStartDetail(request: DiaryModels.ShowStartDetail.Request(startID: startID))
        
        // Assert
        XCTAssertTrue(presentationLogicSpy.presentStartDetailCalled)
        XCTAssertEqual(presentationLogicSpy.startDetailResponse?.startID, startID)
    }
    
    // MARK: Create Start
    func testCreateStart() {
        // Arrange
        
        // Act
        sut.createStart(request: DiaryModels.CreateStart.Request())
        
        // Assert
        XCTAssertTrue(presentationLogicSpy.presentCreateStartCalled)
    }
    
    // MARK: Fetch Workout Sessions
    func testFetchWorkoutSessions() {
        // Arrange
        let mockSessions = setupMockWorkoutSessionEntities()
        coreDataManagerMock.mockWorkoutSessions = mockSessions
        
        let exercises = setupMockExerciseSessionEntities(for: mockSessions[0])
        coreDataManagerMock.mockExerciseSessions = exercises
        
        let exerciseSet = NSSet(array: exercises)
        (mockSessions[0] as! MockWorkoutSessionEntity).mockExerciseSessions = exerciseSet
        
        // Act
        sut.fetchWorkoutSessions(request: DiaryModels.FetchWorkoutSessions.Request())
        
        // Assert
        XCTAssertTrue(coreDataManagerMock.fetchAllWorkoutSessionsCalled)
        XCTAssertTrue(coreDataManagerMock.fetchExerciseSessionsCalled)
        XCTAssertTrue(presentationLogicSpy.presentWorkoutSessionsCalled)
        XCTAssertEqual(presentationLogicSpy.workoutSessionsResponse?.workoutSessions.count, 2)
        
        let firstSession = presentationLogicSpy.workoutSessionsResponse?.workoutSessions.first
        XCTAssertEqual(firstSession?.poolSize, 25)
        XCTAssertEqual(firstSession?.totalTime, 3600)
        XCTAssertEqual(firstSession?.workoutName, "Morning Workout")
        XCTAssertEqual(firstSession?.exercises.count, 2)
        XCTAssertEqual(sut.workoutSessions?.count, 2)
    }
    
    // MARK: Delete Workout Session
    func testDeleteWorkoutSession() {
        // Arrange
        let mockSessions = setupMockWorkoutSessionEntities()
        coreDataManagerMock.mockWorkoutSessions = mockSessions
        sut.workoutSessions = mockSessions
        
        let sessionToDelete = mockSessions[0]
        let sessionID = sessionToDelete.id!
        
        // Act
        sut.deleteWorkoutSession(request: DiaryModels.DeleteWorkoutSession.Request(id: sessionID, index: 0))
        
        // Assert
        XCTAssertTrue(coreDataManagerMock.fetchWorkoutSessionByIDCalled)
        XCTAssertEqual(coreDataManagerMock.fetchWorkoutSessionByIDArgument, sessionID)
        XCTAssertTrue(coreDataManagerMock.deleteWorkoutSessionCalled)
        XCTAssertEqual(coreDataManagerMock.deleteWorkoutSessionArgument, sessionToDelete)
        XCTAssertTrue(presentationLogicSpy.presentDeleteWorkoutSessionCalled)
        XCTAssertEqual(presentationLogicSpy.deleteWorkoutSessionResponse?.index, 0)
        XCTAssertEqual(sut.workoutSessions?.count, 1)
    }
    
    // MARK: Show Workout Session Detail
    func testShowWorkoutSessionDetail() {
        // Arrange
        let sessionID = UUID()
        
        // Act
        sut.showWorkoutSessionDetail(request: DiaryModels.ShowWorkoutSessionDetail.Request(sessionID: sessionID))
        
        // Assert
        XCTAssertTrue(presentationLogicSpy.presentWorkoutSessionDetailCalled)
        XCTAssertEqual(presentationLogicSpy.workoutSessionDetailResponse?.sessionID, sessionID)
    }
    
    // MARK: Helper Method Tests
    func testCalculateTotalMeters() {
        // Arrange
        let session = MockWorkoutSessionEntity()
        
        let exercise1 = MockExerciseSessionEntity()
        exercise1.mockMeters = 100
        exercise1.mockRepetitions = 2
        
        let exercise2 = MockExerciseSessionEntity()
        exercise2.mockMeters = 200
        exercise2.mockRepetitions = 4
        
        session.mockExerciseSessions = NSSet(array: [exercise1, exercise2])
        
        // Act
        let result = sut.calculateTotalMeters(session)
        
        // Assert
        XCTAssertEqual(result, 1000)
    }
    
    func testGetSwimStyleDescription() {
        XCTAssertEqual(sut.getSwimStyleDescription(SwimStyle.freestyle.rawValue), "вольный стиль")
        XCTAssertEqual(sut.getSwimStyleDescription(SwimStyle.breaststroke.rawValue), "брасс")
        XCTAssertEqual(sut.getSwimStyleDescription(SwimStyle.backstroke.rawValue), "на спине")
        XCTAssertEqual(sut.getSwimStyleDescription(SwimStyle.butterfly.rawValue), "баттерфляй")
        XCTAssertEqual(sut.getSwimStyleDescription(SwimStyle.medley.rawValue), "комплекс")
        XCTAssertEqual(sut.getSwimStyleDescription(SwimStyle.any.rawValue), "любой стиль")
        
        XCTAssertEqual(sut.getSwimStyleDescription(99), "вольный стиль")
    }
}
