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
        
        // Получаем сессию тренировки
        guard let sessionEntity = CoreDataManager.shared.fetchWorkoutSession(byID: request.sessionID) else {
            // Если не удалось получить сессию, показываем сообщение об ошибке
            let errorResponse = WorkoutSessionDetailModels.FetchRecommendation.Response(
                recommendationText: "Не удалось загрузить данные тренировки",
                isLoading: false
            )
            presenter?.presentRecommendation(response: errorResponse)
            return
        }
        
        // Проверяем, есть ли уже рекомендация
        if let recommendation = sessionEntity.recommendation, !recommendation.isEmpty {
            // Если рекомендация уже есть, показываем ее
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
                    // Сохраняем рекомендацию в CoreData
                    CoreDataManager.shared.updateWorkoutSessionRecommendation(sessionEntity, recommendation: recommendation)
                    
                    // Информируем презентер, что рекомендация загружена
                    let recommendationResponse = WorkoutSessionDetailModels.FetchRecommendation.Response(
                        recommendationText: recommendation,
                        isLoading: false
                    )
                    self?.presenter?.presentRecommendation(response: recommendationResponse)
                    
                case .failure(let error):
                    // В случае ошибки показываем соответствующее сообщение
                    let errorMessage = "Не удалось получить рекомендацию: \(error.localizedDescription)"
                    print("DeepSeek API Error: \(errorMessage)") // Для отладки
                    
                    // Формируем ответ с информацией об ошибке
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
