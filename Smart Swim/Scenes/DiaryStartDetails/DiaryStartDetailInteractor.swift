//
//  DiaryStartDetailInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.03.2025.
//

import Foundation
import CoreData

protocol CoreDataManagerType {
    func fetchStart(byID: NSManagedObjectID) -> StartEntity?
    func fetchStartsWithCriteria(totalMeters: Int16, swimmingStyle: Int16, poolSize: Int16) -> [StartEntity]
    func startHasRecommendation(_ start: StartEntity) -> Bool
    func updateStartRecommendation(_ start: StartEntity, recommendation: String)
}

protocol AIStartServiceType {
    func generateRecommendation(for start: StartEntity, completion: @escaping (Result<String, DeepSeekError>) -> Void)
}

protocol DiaryStartDetailBusinessLogic {
    func fetchStartDetails(request: DiaryStartDetailModels.FetchStartDetails.Request)
}

protocol DiaryStartDetailDataStore {
    var startID: NSManagedObjectID? { get set }
}

final class DiaryStartDetailInteractor: DiaryStartDetailBusinessLogic, DiaryStartDetailDataStore {
    var presenter: DiaryStartDetailPresentationLogic?
    var startID: NSManagedObjectID?
    private let coreDataManager: CoreDataManagerType
    private let aiStartService: AIStartServiceType
    
    // MARK: - Initialization
    init(coreDataManager: CoreDataManagerType = CoreDataManager.shared,
         aiStartService: AIStartServiceType = AIStartService.shared) {
        self.coreDataManager = coreDataManager
        self.aiStartService = aiStartService
    }
    
    // MARK: - Fetch Start Details
    func fetchStartDetails(request: DiaryStartDetailModels.FetchStartDetails.Request) {
        guard let start = coreDataManager.fetchStart(byID: request.startID) else {
            return
        }
        
        guard let lapEntities = start.laps?.allObjects as? [LapEntity], !lapEntities.isEmpty else {
            return
        }
        
        let sortedLaps = lapEntities.sorted { $0.lapNumber < $1.lapNumber }
        
        let lapsData = sortedLaps.map { lap -> DiaryStartDetailModels.FetchStartDetails.Response.LapData in
            return DiaryStartDetailModels.FetchStartDetails.Response.LapData(
                lapNumber: lap.lapNumber,
                lapTime: lap.lapTime,
                pulse: lap.pulse,
                strokes: lap.strokes
            )
        }
        
        let bestTimeInfo = findBestTime(
            forMeters: start.totalMeters,
            style: start.swimmingStyle,
            poolSize: start.poolSize,
            currentStartID: request.startID
        )
        
        let hasRecommendation = coreDataManager.startHasRecommendation(start)
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
        
        if !hasRecommendation {
            loadRecommendation(for: start, startID: request.startID)
        }
    }
    
    // MARK: - Load Recommendation
    func loadRecommendation(for start: StartEntity, startID: NSManagedObjectID) {
        let loadingResponse = DiaryStartDetailModels.RecommendationLoading.Response(isLoading: true)
        presenter?.presentRecommendationLoading(response: loadingResponse)
        
        aiStartService.generateRecommendation(for: start) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let recommendation):
                    self?.coreDataManager.updateStartRecommendation(start, recommendation: recommendation)
                    
                    let recommendationResponse = DiaryStartDetailModels.RecommendationReceived.Response(
                        recommendationText: recommendation,
                        startID: startID
                    )
                    self?.presenter?.presentRecommendationReceived(response: recommendationResponse)
                    
                case .failure(let error):
                    let errorMessage = "Не удалось получить рекомендацию: \(error.localizedDescription)"
                    print("AI Service Error: \(errorMessage)")
                    
                    let fallbackMessage = "Не удалось получить рекомендацию. Пожалуйста, повторите позже."
                    let recommendationResponse = DiaryStartDetailModels.RecommendationReceived.Response(
                        recommendationText: fallbackMessage,
                        startID: startID
                    )
                    self?.presenter?.presentRecommendationReceived(response: recommendationResponse)
                }
                
                let loadingResponse = DiaryStartDetailModels.RecommendationLoading.Response(isLoading: false)
                self?.presenter?.presentRecommendationLoading(response: loadingResponse)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func findBestTime(forMeters meters: Int16, style: Int16, poolSize: Int16, currentStartID: NSManagedObjectID) -> (bestTime: Double, date: Date?, isBest: Bool) {
        let starts = coreDataManager.fetchStartsWithCriteria(
            totalMeters: meters,
            swimmingStyle: style,
            poolSize: poolSize
        )
        
        var bestTime: Double?
        var bestTimeDate: Date?
        var isCurrentBest = false
        
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

extension CoreDataManager: CoreDataManagerType {}
extension AIStartService: AIStartServiceType {}
