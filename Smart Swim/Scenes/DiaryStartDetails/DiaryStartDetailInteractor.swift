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
            // Handle error case - start not found
            return
        }
        
        // Fetch laps for this start
        guard let lapEntities = start.laps?.allObjects as? [LapEntity], !lapEntities.isEmpty else {
            // Handle error case - no laps found
            return
        }
        
        // Sort laps by lap number
        let sortedLaps = lapEntities.sorted { $0.lapNumber < $1.lapNumber }
        
        // Convert laps to model data
        let lapsData = sortedLaps.map { lap -> DiaryStartDetailModels.FetchStartDetails.Response.LapData in
            return DiaryStartDetailModels.FetchStartDetails.Response.LapData(
                lapNumber: lap.lapNumber,
                lapTime: lap.lapTime,
                pulse: lap.pulse,
                strokes: lap.strokes
            )
        }
        
        // Find best time for comparison
        let bestTimeInfo = findBestTime(
            forMeters: start.totalMeters,
            style: start.swimmingStyle,
            poolSize: start.poolSize,
            currentStartID: request.startID
        )
        
        // Create response with all the needed data
        let response = DiaryStartDetailModels.FetchStartDetails.Response(
            date: start.date,
            poolSize: start.poolSize,
            totalMeters: start.totalMeters,
            swimmingStyle: start.swimmingStyle,
            totalTime: start.totalTime,
            laps: lapsData,
            bestTime: bestTimeInfo.bestTime,
            bestTimeDate: bestTimeInfo.date,
            isCurrentBest: bestTimeInfo.isBest
        )
        
        presenter?.presentStartDetails(response: response)
    }
    
    // MARK: - Find Best Time
    private func findBestTime(forMeters meters: Int16, style: Int16, poolSize: Int16, currentStartID: NSManagedObjectID) -> (bestTime: Double, date: Date?, isBest: Bool) {
        // Get all starts with the same criteria
        let starts = CoreDataManager.shared.fetchStartsWithCriteria(
            totalMeters: meters,
            swimmingStyle: style,
            poolSize: poolSize
        )
        
        var bestTime: Double?
        var bestTimeDate: Date?
        var isCurrentBest = false
        
        // Find the best time
        for fetchedStart in starts {
            if bestTime == nil || fetchedStart.totalTime < bestTime! {
                bestTime = fetchedStart.totalTime
                bestTimeDate = fetchedStart.date
                
                // Check if the current start has the best time
                if fetchedStart.objectID == currentStartID {
                    isCurrentBest = true
                }
            }
        }
        
        return (bestTime ?? 0, bestTimeDate, isCurrentBest)
    }
}
