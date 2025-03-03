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
}

protocol DiaryDataStore {
    var starts: [StartEntity]? { get set }
}

final class DiaryInteractor: DiaryBusinessLogic, DiaryDataStore {
    var presenter: DiaryPresentationLogic?
    var starts: [StartEntity]?
    
    // MARK: - Fetch Starts
    func fetchStarts(request: DiaryModels.FetchStarts.Request) {
        let startEntities = CoreDataManager.shared.fetchAllStarts()
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
        if let start = CoreDataManager.shared.fetchStart(byID: request.id) {
            CoreDataManager.shared.deleteStart(start)
            
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
    
    // MARK: - Helper Methods
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
