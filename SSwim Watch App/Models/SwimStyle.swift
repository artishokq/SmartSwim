//
//  SwimStyle.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import Foundation

enum SwimStyle: Int, CaseIterable, Identifiable {
    case freestyle = 0
    case breaststroke = 1
    case backstroke = 2
    case butterfly = 3
    
    var id: Int { self.rawValue }
    
    var name: String {
        switch self {
        case .freestyle: return "Вольный стиль"
        case .breaststroke: return "Брасс"
        case .backstroke: return "На спине"
        case .butterfly: return "Баттерфляй"
        }
    }
}
