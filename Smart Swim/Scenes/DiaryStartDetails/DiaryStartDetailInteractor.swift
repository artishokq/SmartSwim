//
//  DiaryStartDetailInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.03.2025.
//

import Foundation
import CoreData

protocol DiaryStartDetailBusinessLogic {
    func fetchStartDetails(request: DiaryStartDetailModels.FetchStartDetails.Request)
}

protocol DiaryStartDetailDataStore {
    var startID: NSManagedObjectID? { get set }
}

final class DiaryStartDetailInteractor: DiaryStartDetailBusinessLogic, DiaryStartDetailDataStore {
    var presenter: DiaryStartDetailPresentationLogic?
    var startID: NSManagedObjectID?
    
    // MARK: - Fetch Start Details
    func fetchStartDetails(request: DiaryStartDetailModels.FetchStartDetails.Request) {
        guard let start = CoreDataManager.shared.fetchStart(byID: request.startID) else {
            // Старт не найден
            return
        }
        
        // Достаём отрезки для старта
        guard let lapEntities = start.laps?.allObjects as? [LapEntity], !lapEntities.isEmpty else {
            // Отрезки не найдены
            return
        }
        
        // Сортиуем отрезки
        let sortedLaps = lapEntities.sorted { $0.lapNumber < $1.lapNumber }
        
        let lapsData = sortedLaps.map { lap -> DiaryStartDetailModels.FetchStartDetails.Response.LapData in
            return DiaryStartDetailModels.FetchStartDetails.Response.LapData(
                lapNumber: lap.lapNumber,
                lapTime: lap.lapTime,
                pulse: lap.pulse,
                strokes: lap.strokes
            )
        }
        
        // Находим лучшее время для сравнения
        let bestTimeInfo = findBestTime(
            forMeters: start.totalMeters,
            style: start.swimmingStyle,
            poolSize: start.poolSize,
            currentStartID: request.startID
        )
        
        // Получаем рекомендацию
        let hasRecommendation = CoreDataManager.shared.startHasRecommendation(start)
        let recommendationText = start.recommendation
        let isLoadingRecommendation = false
        
        let response = DiaryStartDetailModels.FetchStartDetails.Response(
            date: start.date,
            poolSize: start.poolSize,
            totalMeters: start.totalMeters,
            swimmingStyle: start.swimmingStyle,
            totalTime: start.totalTime,
            laps: lapsData,
            bestTime: bestTimeInfo.bestTime,
            bestTimeDate: bestTimeInfo.date,
            isCurrentBest: bestTimeInfo.isBest,
            hasRecommendation: hasRecommendation,
            recommendationText: recommendationText,
            isLoadingRecommendation: isLoadingRecommendation
        )
        
        presenter?.presentStartDetails(response: response)
        
        // Если рекомендация отсутствует, запрашиваем ее из Deepseek
        if !hasRecommendation {
            loadRecommendation(for: start, startID: request.startID)
        }
    }
    
    // MARK: - Load Recommendation
    func loadRecommendation(for start: StartEntity, startID: NSManagedObjectID) {
        // Информируем презентер, что загрузка рекомендации началась
        let loadingResponse = DiaryStartDetailModels.RecommendationLoading.Response(isLoading: true)
        presenter?.presentRecommendationLoading(response: loadingResponse)
        
        // Запрашиваем рекомендацию из DeepSeek API
        AIStartService.shared.generateRecommendation(for: start) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recommendation):
                    // Сохраняем рекомендацию в CoreData
                    CoreDataManager.shared.updateStartRecommendation(start, recommendation: recommendation)
                    
                    // Информируем презентер, что рекомендация загружена
                    let recommendationResponse = DiaryStartDetailModels.RecommendationReceived.Response(
                        recommendationText: recommendation,
                        startID: startID
                    )
                    self?.presenter?.presentRecommendationReceived(response: recommendationResponse)
                    
                case .failure(let error):
                    // В случае ошибки показываем соответствующее сообщение с детальной информацией
                    let errorMessage = "Не удалось получить рекомендацию: \(error.localizedDescription)"
                    print("DeepSeek API Error: \(errorMessage)") // Для отладки
                    
                    // Формируем ответ с информацией об ошибке
                    let fallbackMessage = "Не удалось получить рекомендацию. Пожалуйста, повторите позже."
                    let recommendationResponse = DiaryStartDetailModels.RecommendationReceived.Response(
                        recommendationText: fallbackMessage,
                        startID: startID
                    )
                    self?.presenter?.presentRecommendationReceived(response: recommendationResponse)
                }
                
                // Информируем презентер, что загрузка рекомендации завершена
                let loadingResponse = DiaryStartDetailModels.RecommendationLoading.Response(isLoading: false)
                self?.presenter?.presentRecommendationLoading(response: loadingResponse)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func findBestTime(forMeters meters: Int16, style: Int16, poolSize: Int16, currentStartID: NSManagedObjectID) -> (bestTime: Double, date: Date?, isBest: Bool) {
        // Находим все старты с такими критериями
        let starts = CoreDataManager.shared.fetchStartsWithCriteria(
            totalMeters: meters,
            swimmingStyle: style,
            poolSize: poolSize
        )
        
        var bestTime: Double?
        var bestTimeDate: Date?
        var isCurrentBest = false
        
        // Находим лучшее время
        for fetchedStart in starts {
            if bestTime == nil || fetchedStart.totalTime < bestTime! {
                bestTime = fetchedStart.totalTime
                bestTimeDate = fetchedStart.date
                
                if fetchedStart.objectID == currentStartID {
                    isCurrentBest = true
                }
            }
        }
        
        return (bestTime ?? 0, bestTimeDate, isCurrentBest)
    }
}
