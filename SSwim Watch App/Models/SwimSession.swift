//
//  SwimSession.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import Foundation

struct SwimSession {
    var poolLength: Double = 25.0
    var swimmingStyle: Int = 0
    var totalMeters: Int = 0
    var heartRate: Double = 0
    var strokeCount: Int = 0
    var isActive: Bool = false
    var startTime: Date? = nil
    
    var totalLaps: Int {
        return Int(Double(totalMeters) / poolLength)
    }
    
    init(poolLength: Double = 25.0, swimmingStyle: Int = 0, totalMeters: Int = 0,
         heartRate: Double = 0, strokeCount: Int = 0, isActive: Bool = false) {
        self.poolLength = poolLength
        self.swimmingStyle = swimmingStyle
        self.totalMeters = totalMeters
        self.heartRate = heartRate
        self.strokeCount = strokeCount
        self.isActive = isActive
        self.startTime = nil
    }
}
