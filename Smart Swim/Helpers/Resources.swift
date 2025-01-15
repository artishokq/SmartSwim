//
//  Resources.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 12.01.2025.
//

import UIKit

enum Resources {
    enum Colors {
        static let active = UIColor(hexString: "#93DBFA")
        static let inactive = UIColor(hexString: "#B7C4E6")
        
        static let tabAndNavBar = UIColor(hexString: "#3A3C5D")
        static let titleWhite = UIColor(hexString: "#FFFFFF") ?? .white
        
        static let background = UIColor(hexString: "#242531")
        
        static let createButtonColor = UIColor(hexString: "#B7C4E6")
        static let infoButtonColor = UIColor(hexString: "#B7C4E6")
        
        static let createBackgroundColor = UIColor(hexString: "#242531")
        static let infoBackgroundColor = UIColor(hexString: "#242531")
        static let createCellBackgroundColor = UIColor(hexString: "#505773")
        static let fieldsBackgroundColor = UIColor(hexString: "#323645")
        
        static let blueColor = UIColor(hexString: "#0A84FF")
    }
    
    enum Strings {
        enum TabBar {
            static let start = "Старт"
            static let workout = "Тренировка"
            static let diary = "Дневник"
        }
        
        enum Workout {
            static let createButtonTitle = "Создать"
            static let infoButtonTitle = "Инфо"
            static let createTitle = "Создать"
            static let workoutTitle = "Тренировки"
            
            static let addButtonTitle = "Добавить"
            static let constructorTitle = "Конструктор"
            static let infoTitle = "Информация"
            
            static let workoutNamePlaceholder = "Название тренировки"
        }
        
        enum Diary {
            
        }
        
        enum Start {
            
        }
    }
    
    enum Images {
        enum TabBar {
            static let start = UIImage(named: "startTab")
            static let workout = UIImage(named: "workoutTab")
            static let diary = UIImage(named: "diaryTab")
        }
        
        enum Workout {
            static let createButtonImage = UIImage(named: "createButton")
            static let infoButtonImage = UIImage(named: "infoButton")
            static let deleteButtonImage = UIImage(named: "deleteButton")
            static let editButtonImage = UIImage(named: "editButton")
        }
        
        enum Diary {
            
        }
    }
    
    enum Fonts {
        static let NavBarTitle = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let constructorTitle = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let infoTitle = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let workoutNamePlaceholder = UIFont.systemFont(ofSize: 18, weight: .light)
    }
}
