//
//  SwimSession.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import Foundation

struct SwimSession {
    var poolLength: Double
    var swimmingStyle: Int
    var totalMeters: Int
    var strokeCount: Int = 0
    var heartRate: Double = 0
    var isActive: Bool = false
}
