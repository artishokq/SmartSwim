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
        
        let exerciseEntities = CoreDataManager.shared.fetchExerciseSessions(for: sessionEntity)
        let headerData = WorkoutSessionDetailModels.FetchSessionDetails.Response.HeaderData(
            date: sessionEntity.date ?? Date(),
            totalTime: sessionEntity.totalTime,
            totalMeters: calculateTotalMeters(from: exerciseEntities),
            totalCalories: sessionEntity.totalCalories,
            averageHeartRate: calculateAverageHeartRate(from: exerciseEntities),
            poolSize: sessionEntity.poolSize,
            workoutName: sessionEntity.workoutName ?? "Тренировка"
        )
        
        var exercisesData: [WorkoutSessionDetailModels.FetchSessionDetails.Response.ExerciseData] = []
        for exerciseEntity in exerciseEntities.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let lapEntities = CoreDataManager.shared.fetchLapSessions(for: exerciseEntity)
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
            
            let heartRateReadings = CoreDataManager.shared.fetchHeartRateReadings(for: exerciseEntity).map {
                WorkoutSessionDetailModels.FetchSessionDetails.Response.HeartRateData(
                    value: $0.value,
                    timestamp: $0.timestamp ?? Date()
                )
            }
            
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
                heartRateReadings: heartRateReadings,
                totalTime: exerciseEntity.endTime?.timeIntervalSince(exerciseEntity.startTime ?? Date()) ?? 0,
                averageHeartRate: exerciseEntity.averageHeartRate,
                totalStrokes: calculateTotalStrokes(from: lapEntities)
            )
            
            exercisesData.append(exerciseData)
        }
        
        let response = WorkoutSessionDetailModels.FetchSessionDetails.Response(
            headerData: headerData,
            exercises: exercisesData
        )
        
        presenter?.presentSessionDetails(response: response)
        fetchRecommendation(request: WorkoutSessionDetailModels.FetchRecommendation.Request(sessionID: request.sessionID))
    }
    
    // MARK: - Fetch Recommendation
    func fetchRecommendation(request: WorkoutSessionDetailModels.FetchRecommendation.Request) {
        let loadingResponse = WorkoutSessionDetailModels.FetchRecommendation.Response(
            recommendationText: nil,
            isLoading: true
        )
        presenter?.presentRecommendation(response: loadingResponse)
        guard let sessionEntity = CoreDataManager.shared.fetchWorkoutSession(byID: request.sessionID) else {
            let errorResponse = WorkoutSessionDetailModels.FetchRecommendation.Response(
                recommendationText: "Не удалось загрузить данные тренировки",
                isLoading: false
            )
            presenter?.presentRecommendation(response: errorResponse)
            return
        }
        
        // Проверяем, есть ли уже рекомендация
        if let recommendation = sessionEntity.recommendation, !recommendation.isEmpty {
            let response = WorkoutSessionDetailModels.FetchRecommendation.Response(
                recommendationText: recommendation,
                isLoading: false
            )
            presenter?.presentRecommendation(response: response)
            return
        }
        
        // Запрашиваем рекомендацию из DeepSeek API
        AIWorkoutService.shared.generateRecommendation(for: sessionEntity) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recommendation):
                    CoreDataManager.shared.updateWorkoutSessionRecommendation(sessionEntity, recommendation: recommendation)
                    
                    let recommendationResponse = WorkoutSessionDetailModels.FetchRecommendation.Response(
                        recommendationText: recommendation,
                        isLoading: false
                    )
                    self?.presenter?.presentRecommendation(response: recommendationResponse)
                    
                case .failure(let error):
                    let errorMessage = "Не удалось получить рекомендацию: \(error.localizedDescription)"
                    print("DeepSeek API Error: \(errorMessage)")
                    
                    let fallbackMessage = "Не удалось получить рекомендацию. Пожалуйста, повторите позже."
                    let recommendationResponse = WorkoutSessionDetailModels.FetchRecommendation.Response(
                        recommendationText: fallbackMessage,
                        isLoading: false
                    )
                    self?.presenter?.presentRecommendation(response: recommendationResponse)
                }
            }
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
