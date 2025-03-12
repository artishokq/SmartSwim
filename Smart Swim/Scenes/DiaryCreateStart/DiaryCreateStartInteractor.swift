//
//  DiaryCreateStartInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.03.2025.
//

import UIKit
import CoreData

protocol DiaryCreateStartBusinessLogic {
    func createStart(request: DiaryCreateStartModels.Create.Request)
    func calculateLaps(request: DiaryCreateStartModels.CalculateLaps.Request)
    func collectAndValidateData(request: DiaryCreateStartModels.CollectData.Request)
}

protocol DiaryCreateStartDataStore {
    var createdStart: StartEntity? { get set }
}

final class DiaryCreateStartInteractor: DiaryCreateStartBusinessLogic, DiaryCreateStartDataStore {
    // MARK: - Constants
    private enum Constants {
        static let metersErrorMessage: String = "Введите корректное значение метров"
        static let timeErrorMessage: String = "Введите корректное время в формате мм:сс,мс"
        static let lapTimeErrorMessage: String = "Введите корректное время для всех отрезков"
        static let lapTimeMismatchMessage: String = "Сумма времени отрезков должна равняться общему времени"
        static let startSavingErrorMessage: String = "Не удалось сохранить старт"
    }
    
    // MARK: - Properties
    var presenter: DiaryCreateStartPresentationLogic?
    var createdStart: StartEntity?
    
    // MARK: - Create Start
    func createStart(request: DiaryCreateStartModels.Create.Request) {
        // Создаем сущность старта
        let startEntity = CoreDataManager.shared.createStart(
            poolSize: request.poolSize,
            totalMeters: request.totalMeters,
            swimmingStyle: request.swimmingStyle,
            date: request.date
        )
        
        if let startEntity = startEntity {
            // Обновляем общее время старта
            CoreDataManager.shared.updateStartTotalTime(startEntity, totalTime: request.totalTime)
            
            // Добавляем отрезки к старту
            for (index, lapData) in request.laps.enumerated() {
                _ = CoreDataManager.shared.createLap(
                    lapTime: lapData.lapTime,
                    pulse: lapData.pulse,
                    strokes: lapData.strokes,
                    lapNumber: Int16(index + 1),
                    startEntity: startEntity
                )
            }
            
            createdStart = startEntity
            
            // Отправляем уведомление о создании старта
            NotificationCenter.default.post(name: .didCreateStart, object: nil)
            
            let response = DiaryCreateStartModels.Create.Response(success: true, errorMessage: nil)
            presenter?.presentStartCreated(response: response)
        } else {
            let response = DiaryCreateStartModels.Create.Response(success: false, errorMessage: Constants.startSavingErrorMessage)
            presenter?.presentStartCreated(response: response)
        }
    }
    
    // MARK: - Calculate Laps
    func calculateLaps(request: DiaryCreateStartModels.CalculateLaps.Request) {
        // Рассчитываем количество отрезков
        let lapsCount = Int(request.totalMeters / request.poolSize)
        let response = DiaryCreateStartModels.CalculateLaps.Response(numberOfLaps: lapsCount)
        presenter?.presentLapCount(response: response)
    }
    
    // MARK: - Collect and Validate Data
    func collectAndValidateData(request: DiaryCreateStartModels.CollectData.Request) {
        // Проверяем метры
        if request.totalMetersText.isEmpty {
            let response = DiaryCreateStartModels.CollectData.Response(
                success: false,
                errorMessage: Constants.metersErrorMessage,
                createRequest: nil
            )
            presenter?.presentCollectedData(response: response)
            return
        }
        
        guard let totalMeters = Int16(request.totalMetersText) else {
            let response = DiaryCreateStartModels.CollectData.Response(
                success: false,
                errorMessage: Constants.metersErrorMessage,
                createRequest: nil
            )
            presenter?.presentCollectedData(response: response)
            return
        }
        
        if totalMeters <= 0 {
            let response = DiaryCreateStartModels.CollectData.Response(
                success: false,
                errorMessage: Constants.metersErrorMessage,
                createRequest: nil
            )
            presenter?.presentCollectedData(response: response)
            return
        }
        
        // Проверяем общее время
        if request.totalTimeText.isEmpty {
            let response = DiaryCreateStartModels.CollectData.Response(
                success: false,
                errorMessage: Constants.timeErrorMessage,
                createRequest: nil
            )
            presenter?.presentCollectedData(response: response)
            return
        }
        
        guard let totalTime = parseTime(request.totalTimeText) else {
            let response = DiaryCreateStartModels.CollectData.Response(
                success: false,
                errorMessage: Constants.timeErrorMessage,
                createRequest: nil
            )
            presenter?.presentCollectedData(response: response)
            return
        }
        
        // Парсим дату
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let date = dateFormatter.date(from: request.dateText) ?? Date()
        
        // Проверяем время отрезков
        var lapTimes: [Double] = []
        
        for lapTimeText in request.lapTimeTexts {
            if lapTimeText.isEmpty {
                let response = DiaryCreateStartModels.CollectData.Response(
                    success: false,
                    errorMessage: Constants.lapTimeErrorMessage,
                    createRequest: nil
                )
                presenter?.presentCollectedData(response: response)
                return
            }
            
            guard let lapTime = parseTime(lapTimeText) else {
                let response = DiaryCreateStartModels.CollectData.Response(
                    success: false,
                    errorMessage: Constants.lapTimeErrorMessage,
                    createRequest: nil
                )
                presenter?.presentCollectedData(response: response)
                return
            }
            
            lapTimes.append(lapTime)
        }
        
        // Проверяем, что сумма времени отрезков равна общему времени
        let sumOfLapTimes = lapTimes.reduce(0, +)
        if abs(sumOfLapTimes - totalTime) > 0.001 {
            let formattedTotal = durationToTimeString(totalTime)
            let formattedSum = durationToTimeString(sumOfLapTimes)
            let message = "\(Constants.lapTimeMismatchMessage)\nОбщее время: \(formattedTotal)\nСумма отрезков: \(formattedSum)"
            
            let response = DiaryCreateStartModels.CollectData.Response(
                success: false,
                errorMessage: message,
                createRequest: nil
            )
            presenter?.presentCollectedData(response: response)
            return
        }
        
        // Все проверки пройдены, создаем запрос
        let laps = lapTimes.map { LapDataDiary(lapTime: $0) }
        
        let createRequest = DiaryCreateStartModels.Create.Request(
            poolSize: request.poolSize,
            swimmingStyle: request.swimmingStyle,
            totalMeters: totalMeters,
            date: date,
            totalTime: totalTime,
            laps: laps
        )
        
        let response = DiaryCreateStartModels.CollectData.Response(
            success: true,
            errorMessage: nil,
            createRequest: createRequest
        )
        
        presenter?.presentCollectedData(response: response)
    }
    
    // MARK: - Helper Methods
    private func parseTime(_ timeString: String) -> Double? {
        let components = timeString.components(separatedBy: CharacterSet(charactersIn: ":,"))
        guard components.count == 3,
              let minutes = Double(components[0]),
              let seconds = Double(components[1]),
              let milliseconds = Double(components[2]) else {
            return nil
        }
        
        return minutes * 60 + seconds + milliseconds / 100
    }
    
    private func durationToTimeString(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int(round((duration.truncatingRemainder(dividingBy: 1)) * 100))
        return String(format: "%02d:%02d,%02d", minutes, seconds, milliseconds)
    }
}
