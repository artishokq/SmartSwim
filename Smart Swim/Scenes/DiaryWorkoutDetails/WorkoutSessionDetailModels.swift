//
//  WorkoutSessionDetailModels.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 25.03.2025.
//

import UIKit
import CoreData

enum WorkoutSessionDetailModels {
    enum FetchSessionDetails {
        struct Request {
            let sessionID: UUID
        }
        
        struct Response {
            struct HeaderData {
                let date: Date
                let totalTime: Double
                let totalMeters: Int16
                let totalCalories: Double
                let averageHeartRate: Double
                let poolSize: Int16
                let workoutName: String
            }
            
            struct ExerciseData {
                let id: UUID
                let orderIndex: Int16
                let description: String?
                let style: Int16
                let type: Int16
                let startTime: Date
                let endTime: Date
                let hasInterval: Bool
                let intervalMinutes: Int16
                let intervalSeconds: Int16
                let meters: Int16
                let repetitions: Int16
                let laps: [LapData]
                let totalTime: Double
                let averageHeartRate: Double
                let totalStrokes: Int
            }
            
            struct LapData {
                let id: UUID
                let lapNumber: Int16
                let distance: Int16
                let lapTime: Double
                let heartRate: Double
                let strokes: Int16
                let timestamp: Date
            }
            
            let headerData: HeaderData
            let exercises: [ExerciseData]
        }
        
        struct ViewModel {
            struct SummaryData {
                let dateString: String
                let totalTimeString: String
                let totalMetersString: String
                let totalCaloriesString: String
                let averageHeartRateString: String
                let poolSizeString: String
            }
            
            struct ExerciseDetail {
                let id: UUID
                let orderIndex: Int16
                let description: String
                let styleString: String
                let typeString: String
                let timeString: String
                let hasInterval: Bool
                let intervalString: String
                let metersString: String
                let repetitionsString: String
                
                struct PulseAnalysis {
                    let averagePulse: String
                    let maxPulse: String
                    let minPulse: String
                    let pulseZone: String
                }
                
                struct StrokeAnalysis {
                    let averageStrokes: String
                    let maxStrokes: String
                    let minStrokes: String
                    let totalStrokes: String
                }
                
                let pulseAnalysis: PulseAnalysis
                let strokeAnalysis: StrokeAnalysis
            }
            
            let summaryData: SummaryData
            let exercises: [ExerciseDetail]
        }
    }
    
    enum FetchRecommendation {
        struct Request {
            let sessionID: UUID
        }
        
        struct Response {
            let recommendationText: String?
            let isLoading: Bool
        }
        
        struct ViewModel {
            let recommendationText: String
            let isLoading: Bool
        }
    }
}
