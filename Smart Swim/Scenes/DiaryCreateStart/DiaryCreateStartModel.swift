//
//  DiaryCreateStartModel.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.03.2025.
//

import Foundation

enum DiaryCreateStartModels {
    enum Create {
        struct Request {
            let poolSize: Int16
            let swimmingStyle: Int16
            let totalMeters: Int16
            let date: Date
            let totalTime: Double
            let laps: [LapDataDiary]
        }
        
        struct Response {
            let success: Bool
            let errorMessage: String?
        }
        
        struct ViewModel {
            let success: Bool
            let message: String
        }
    }
    
    enum CalculateLaps {
        struct Request {
            let poolSize: Int16
            let totalMeters: Int16
        }
        
        struct Response {
            let numberOfLaps: Int
        }
        
        struct ViewModel {
            let numberOfLaps: Int
        }
    }
    
    enum CollectData {
        struct Request {
            let poolSize: Int16
            let swimmingStyle: Int16
            let totalMetersText: String
            let dateText: String
            let totalTimeText: String
            let lapTimeTexts: [String]
        }
        
        struct Response {
            let success: Bool
            let errorMessage: String?
            let createRequest: Create.Request?
        }
        
        struct ViewModel {
            let success: Bool
            let errorMessage: String?
            let createRequest: Create.Request?
        }
    }
}

struct LapDataDiary {
    let lapTime: Double
    let pulse: Int16 = 0
    let strokes: Int16 = 0
}
