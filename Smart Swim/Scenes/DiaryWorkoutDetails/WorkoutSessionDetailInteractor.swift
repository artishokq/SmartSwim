//
//  WorkoutSessionDetailInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 25.03.2025.
//

import Foundation

protocol WorkoutSessionDetailBusinessLogic {
    func fetchSessionDetails(request: WorkoutSessionDetailModels.FetchSessionDetails.Request)
    func fetchRecommendation(request: WorkoutSessionDetailModels.FetchRecommendation.Request)
}

protocol WorkoutSessionDetailDataStore {
    var sessionID: UUID? { get set }
}

final class WorkoutSessionDetailInteractor: WorkoutSessionDetailBusinessLogic, WorkoutSessionDetailDataStore {
    var presenter: WorkoutSessionDetailPresentationLogic?
    var sessionID: UUID?
    
    // MARK: - Fetch Session Details
    func fetchSessionDetails(request: WorkoutSessionDetailModels.FetchSessionDetails.Request) {
        guard let sessionEntity = CoreDataManager.shared.fetchWorkoutSession(byID: request.sessionID) else {
            return
        }
        
        // Получаем все упражнения для сессии
        let exerciseEntities = CoreDataManager.shared.fetchExerciseSessions(for: sessionEntity)
        
        // Подготавливаем данные для заголовка
        let headerData = WorkoutSessionDetailModels.FetchSessionDetails.Response.HeaderData(
            date: sessionEntity.date ?? Date(),
            totalTime: sessionEntity.totalTime,
            totalMeters: calculateTotalMeters(from: exerciseEntities),
            totalCalories: sessionEntity.totalCalories,
            averageHeartRate: calculateAverageHeartRate(from: exerciseEntities),
            poolSize: sessionEntity.poolSize,
            workoutName: sessionEntity.workoutName ?? "Тренировка"
        )
        
        // Подготавливаем данные для упражнений
        var exercisesData: [WorkoutSessionDetailModels.FetchSessionDetails.Response.ExerciseData] = []
        
        for exerciseEntity in exerciseEntities.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            // Получаем отрезки для упражнения
            let lapEntities = CoreDataManager.shared.fetchLapSessions(for: exerciseEntity)
            
            // Подготавливаем данные об отрезках
            let lapsData = lapEntities.sorted(by: { $0.lapNumber < $1.lapNumber }).map { lap -> WorkoutSessionDetailModels.FetchSessionDetails.Response.LapData in
                return WorkoutSessionDetailModels.FetchSessionDetails.Response.LapData(
                    id: lap.id ?? UUID(),
                    lapNumber: lap.lapNumber,
                    distance: lap.distance,
                    lapTime: lap.lapTime,
                    heartRate: lap.heartRate,
                    strokes: lap.strokes,
                    timestamp: lap.timestamp ?? Date()
                )
            }
            
            // Добавляем данные об упражнении
            let exerciseData = WorkoutSessionDetailModels.FetchSessionDetails.Response.ExerciseData(
                id: exerciseEntity.id ?? UUID(),
                orderIndex: exerciseEntity.orderIndex,
                description: exerciseEntity.exerciseDescription ?? "Упражнение",
                style: exerciseEntity.style,
                type: exerciseEntity.type,
                startTime: exerciseEntity.startTime ?? Date(),
                endTime: exerciseEntity.endTime ?? Date(),
                hasInterval: exerciseEntity.hasInterval,
                intervalMinutes: exerciseEntity.intervalMinutes,
                intervalSeconds: exerciseEntity.intervalSeconds,
                meters: exerciseEntity.meters,
                repetitions: exerciseEntity.repetitions,
                laps: lapsData,
                totalTime: exerciseEntity.endTime?.timeIntervalSince(exerciseEntity.startTime ?? Date()) ?? 0,
                averageHeartRate: calculateAverageHeartRate(from: lapEntities),
                totalStrokes: calculateTotalStrokes(from: lapEntities)
            )
            
            exercisesData.append(exerciseData)
        }
        
        // Создаем и отправляем ответ
        let response = WorkoutSessionDetailModels.FetchSessionDetails.Response(
            headerData: headerData,
            exercises: exercisesData
        )
        
        presenter?.presentSessionDetails(response: response)
        
        // После загрузки деталей запрашиваем рекомендацию
        fetchRecommendation(request: WorkoutSessionDetailModels.FetchRecommendation.Request(sessionID: request.sessionID))
    }
    
    // MARK: - Fetch Recommendation
    func fetchRecommendation(request: WorkoutSessionDetailModels.FetchRecommendation.Request) {
        // Сообщаем о начале загрузки
        let loadingResponse = WorkoutSessionDetailModels.FetchRecommendation.Response(
            recommendationText: nil,
            isLoading: true
        )
        presenter?.presentRecommendation(response: loadingResponse)
        
        // TBA
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            let recommendation = "TBA"
            
            let response = WorkoutSessionDetailModels.FetchRecommendation.Response(
                recommendationText: recommendation,
                isLoading: false
            )
            self?.presenter?.presentRecommendation(response: response)
        }
    }
    
    // MARK: - Helper Methods
    private func calculateTotalMeters(from exercises: [ExerciseSessionEntity]) -> Int16 {
        return exercises.reduce(0) { sum, exercise in
            return sum + exercise.meters * exercise.repetitions
        }
    }
    
    private func calculateAverageHeartRate(from exercises: [ExerciseSessionEntity]) -> Double {
        var totalHeartRate: Double = 0
        var lapCount = 0
        
        for exercise in exercises {
            if let laps = exercise.laps?.allObjects as? [LapSessionEntity], !laps.isEmpty {
                totalHeartRate += laps.reduce(0) { $0 + $1.heartRate }
                lapCount += laps.count
            }
        }
        
        return lapCount > 0 ? totalHeartRate / Double(lapCount) : 0
    }
    
    private func calculateAverageHeartRate(from laps: [LapSessionEntity]) -> Double {
        guard !laps.isEmpty else { return 0 }
        return laps.reduce(0) { $0 + $1.heartRate } / Double(laps.count)
    }
    
    private func calculateTotalStrokes(from laps: [LapSessionEntity]) -> Int {
        return laps.reduce(0) { $0 + Int($1.strokes) }
    }
    
    private func getSwimStyleDescription(_ styleRawValue: Int16) -> String {
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
}
