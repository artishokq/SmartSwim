//
//  Resources.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 12.01.2025.
//

import UIKit

enum Resources {
    enum Colors {
        static var active = UIColor(hexString: "#93DBFA")
        static var inactive = UIColor(hexString: "#B7C4E6")
        
        static var TabAndNavBar = UIColor(hexString: "#3A3C5D")
        static var TitleWhite = UIColor(hexString: "#FFFFFF") ?? .white
        static var background = UIColor(hexString: "#242531")
    }
    
    enum Strings {
        enum TabBar {
            static var start = "Старт"
            static var workout = "Тренировка"
            static var diary = "Дневник"
        }
    }
    
    enum Images {
        enum TabBar {
            static var start = UIImage(named: "startTab")
            static var workout = UIImage(named: "workoutTab")
            static var diary = UIImage(named: "diaryTab")
        } 
    }
    
    enum Fonts {
        static var NavBarTitle = UIFont.systemFont(ofSize: 20, weight: .light)
    }
}
