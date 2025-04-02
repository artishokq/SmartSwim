//
//  DiaryStartDetailModel.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.03.2025.
//

import Foundation
import UIKit
import CoreData

enum DiaryStartDetailModels {
    enum FetchStartDetails {
        struct Request {
            let startID: NSManagedObjectID
        }
        
        struct Response {
            let date: Date
            let poolSize: Int16
            let totalMeters: Int16
            let swimmingStyle: Int16
            let totalTime: Double
            let laps: [LapData]
            let bestTime: Double
            let bestTimeDate: Date?
            let isCurrentBest: Bool
            let hasRecommendation: Bool
            let recommendationText: String?
            let isLoadingRecommendation: Bool
            
            struct LapData {
                let lapNumber: Int16
                let lapTime: Double
                let pulse: Int16
                let strokes: Int16
            }
        }
        
        struct ViewModel {
            let headerInfo: HeaderInfo
            let lapDetails: [LapDetail]
            let recommendationText: String
            let isLoadingRecommendation: Bool
            
            struct HeaderInfo {
                let distanceWithStyle: String
                let totalTime: String
                let timeComparisonString: String
                let dateString: String
                let poolSizeString: String
                let comparisonColor: UIColor
            }
            
            struct LapDetail {
                let title: String
                let pulse: String
                let strokes: String
                let time: String
            }
        }
    }
    
    enum RecommendationLoading {
        struct Response {
            let isLoading: Bool
        }
        
        struct ViewModel {
            let isLoading: Bool
        }
    }
    
    enum RecommendationReceived {
        struct Response {
            let recommendationText: String
            let startID: NSManagedObjectID
        }
        
        struct ViewModel {
            let recommendationText: String
        }
    }
}
