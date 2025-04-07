//
//  DiaryInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import Foundation
import CoreData

protocol DiaryBusinessLogic {
    func fetchStarts(request: DiaryModels.FetchStarts.Request)
    func deleteStart(request: DiaryModels.DeleteStart.Request)
    func showStartDetail(request: DiaryModels.ShowStartDetail.Request)
    func createStart(request: DiaryModels.CreateStart.Request)
    func fetchWorkoutSessions(request: DiaryModels.FetchWorkoutSessions.Request)
    func deleteWorkoutSession(request: DiaryModels.DeleteWorkoutSession.Request)
    func showWorkoutSessionDetail(request: DiaryModels.ShowWorkoutSessionDetail.Request)
}

protocol DiaryDataStore {
    var starts: [StartEntity]? { get set }
    var workoutSessions: [WorkoutSessionEntity]? { get set }
}

protocol DiaryCoreDataManagerProtocol {
    func fetchAllStarts() -> [StartEntity]
    func fetchStart(byID: NSManagedObjectID) -> StartEntity?
    func deleteStart(_ start: StartEntity)
    func fetchAllWorkoutSessions() -> [WorkoutSessionEntity]
    func fetchWorkoutSession(byID: UUID) -> WorkoutSessionEntity?
    func deleteWorkoutSession(_ session: WorkoutSessionEntity)
    func fetchExerciseSessions(for session: WorkoutSessionEntity) -> [ExerciseSessionEntity]
}

final class DiaryInteractor: DiaryBusinessLogic, DiaryDataStore {
    var workoutSessions: [WorkoutSessionEntity]?
    var presenter: DiaryPresentationLogic?
    var starts: [StartEntity]?
    var coreDataManager: DiaryCoreDataManagerProtocol
    
    init(coreDataManager: DiaryCoreDataManagerProtocol = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - Fetch Starts
    func fetchStarts(request: DiaryModels.FetchStarts.Request) {
        let startEntities = coreDataManager.fetchAllStarts()
        self.starts = startEntities
        
        let startData = startEntities.map { entity -> DiaryModels.FetchStarts.Response.StartData in
            return DiaryModels.FetchStarts.Response.StartData(
                id: entity.objectID,
                date: entity.date,
                totalMeters: entity.totalMeters,
                swimmingStyle: entity.swimmingStyle,
                totalTime: entity.totalTime
            )
        }
        
        let response = DiaryModels.FetchStarts.Response(starts: startData)
        presenter?.presentStarts(response: response)
    }
    
    // MARK: - Delete Start
    func deleteStart(request: DiaryModels.DeleteStart.Request) {
        if let start = coreDataManager.fetchStart(byID: request.id) {
            coreDataManager.deleteStart(start)
            
            // Удаляем из локального массива
            if let index = starts?.firstIndex(where: { $0.objectID == request.id }) {
                starts?.remove(at: index)
            }
            
            let response = DiaryModels.DeleteStart.Response(index: request.index)
            presenter?.presentDeleteStart(response: response)
        }
    }
    
    // MARK: - Show Start Detail
    func showStartDetail(request: DiaryModels.ShowStartDetail.Request) {
        let response = DiaryModels.ShowStartDetail.Response(startID: request.startID)
        presenter?.presentStartDetail(response: response)
    }
    
    // MARK: - Create Start
    func createStart(request: DiaryModels.CreateStart.Request) {
        let response = DiaryModels.CreateStart.Response()
        presenter?.presentCreateStart(response: response)
    }
    
    // MARK: - Fetch Workout Sessions
    func fetchWorkoutSessions(request: DiaryModels.FetchWorkoutSessions.Request) {
        let workoutSessionEntities = coreDataManager.fetchAllWorkoutSessions()
        self.workoutSessions = workoutSessionEntities
        
        let sessionData = workoutSessionEntities.map { entity -> DiaryModels.FetchWorkoutSessions.Response.WorkoutSessionData in
            
            let exerciseEntities = coreDataManager.fetchExerciseSessions(for: entity)
            
            let exercises = exerciseEntities.sorted(by: { $0.orderIndex < $1.orderIndex }).map { exercise -> DiaryModels.FetchWorkoutSessions.Response.WorkoutSessionData.ExerciseData in
                return DiaryModels.FetchWorkoutSessions.Response.WorkoutSessionData.ExerciseData(
                    orderIndex: Int(exercise.orderIndex),
                    description: exercise.exerciseDescription,
                    style: exercise.style,
                    type: exercise.type,
                    meters: exercise.meters,
                    repetitions: exercise.repetitions,
                    hasInterval: exercise.hasInterval,
                    intervalMinutes: exercise.intervalMinutes,
                    intervalSeconds: exercise.intervalSeconds
                )
            }
            
            return DiaryModels.FetchWorkoutSessions.Response.WorkoutSessionData(
                id: entity.id ?? UUID(),
                date: entity.date ?? Date(),
                totalMeters: calculateTotalMeters(entity),
                totalTime: entity.totalTime,
                poolSize: entity.poolSize,
                workoutName: entity.workoutName ?? "Тренировка",
                exercises: exercises
            )
        }
        
        let response = DiaryModels.FetchWorkoutSessions.Response(workoutSessions: sessionData)
        presenter?.presentWorkoutSessions(response: response)
    }
    
    // MARK: - Delete Workout Session
    func deleteWorkoutSession(request: DiaryModels.DeleteWorkoutSession.Request) {
        if let session = coreDataManager.fetchWorkoutSession(byID: request.id) {
            coreDataManager.deleteWorkoutSession(session)
            
            // Удаляем из локального массива
            if let index = workoutSessions?.firstIndex(where: { $0.id == request.id }) {
                workoutSessions?.remove(at: index)
            }
            
            let response = DiaryModels.DeleteWorkoutSession.Response(index: request.index)
            presenter?.presentDeleteWorkoutSession(response: response)
        }
    }
    
    // MARK: - Show Workout Session Detail
    func showWorkoutSessionDetail(request: DiaryModels.ShowWorkoutSessionDetail.Request) {
        let response = DiaryModels.ShowWorkoutSessionDetail.Response(sessionID: request.sessionID)
        presenter?.presentWorkoutSessionDetail(response: response)
    }
    
    // MARK: - Helper Methods
    func getSwimStyleDescription(_ styleRawValue: Int16) -> String {
        let style = SwimStyle(rawValue: styleRawValue) ?? .freestyle
        switch style {
        case .freestyle: return "вольный стиль"
        case .breaststroke: return "брасс"
        case .backstroke: return "на спине"
        case .butterfly: return "баттерфляй"
        case .medley: return "комплекс"
        case .any: return "любой стиль"
        }
    }
    
    func calculateTotalMeters(_ session: WorkoutSessionEntity) -> Int {
        guard let exercises = session.exerciseSessions?.allObjects as? [ExerciseSessionEntity] else {
            return 0
        }
        
        return exercises.reduce(0) { sum, exercise in
            return sum + Int(exercise.meters * exercise.repetitions)
        }
    }
}

extension CoreDataManager: DiaryCoreDataManagerProtocol {}
