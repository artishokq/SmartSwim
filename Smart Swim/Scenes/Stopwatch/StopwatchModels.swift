//
//  StopwatchModels.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.02.2025.
//

import UIKit

enum StopwatchModels {
    // Модель для обновления таймера
    enum TimerTick {
        struct Request { }
        
        struct Response {
            let globalTime: TimeInterval   // Общее время (с момента старта)
            let lapTime: TimeInterval      // Время активного отрезка
        }
        
        struct ViewModel {
            let formattedGlobalTime: String
            let formattedActiveLapTime: String
        }
    }
    
    // Модель для обработки нажатия на основную кнопку (Старт/Поворот/Финиш)
    enum MainButtonAction {
        struct Request {
            
        }
        
        struct Response {
            let nextButtonTitle: String
            let nextButtonColor: UIColor
        }
        
        struct ViewModel {
            let buttonTitle: String
            let buttonColor: UIColor
        }
    }
    
    // Модель для записи отрезка
    enum LapRecording {
        struct Request {
            
        }
        
        struct Response {
            let lapNumber: Int
            let lapTime: TimeInterval
        }
        
        struct ViewModel {
            let lapNumber: Int
            var lapTimeString: String
        }
    }
    
    // Модель для завершения работы секундомера
    enum Finish {
        struct Request {
            
        }
        
        struct Response {
            let finalButtonTitle: String
            let finalButtonColor: UIColor
            let dataSaved: Bool
        }
        
        struct ViewModel {
            let buttonTitle: String
            let buttonColor: UIColor
            let showSaveSuccessAlert: Bool
        }
    }
    
    // Модель для обновления данных о пульсе
    enum PulseUpdate {
        struct Request {
            let pulse: Int
        }
        
        struct Response {
            let pulse: Int
        }
        
        struct ViewModel {
            let pulse: Int
        }
    }
    
    // Модель для обновления данных о гребках
    enum StrokeUpdate {
        struct Request {
            let strokes: Int
        }
        
        struct Response {
            let strokes: Int
        }
        
        struct ViewModel {
            let strokes: Int
        }
    }
    
    // Модель для обновления статуса часов
    enum WatchStatusUpdate {
        struct Request {
            let status: String
        }
        
        struct Response {
            let status: String
        }
        
        struct ViewModel {
            let status: String
        }
    }
}
