//
//  StopwatchInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.02.2025.
//

import UIKit

protocol StopwatchBusinessLogic {
    func handleMainButtonAction(request: StopwatchModels.MainButtonAction.Request)
    func timerTick(request: StopwatchModels.TimerTick.Request)
    func updatePulseData(request: StopwatchModels.PulseUpdate.Request)
    func updateStrokeCount(request: StopwatchModels.StrokeUpdate.Request)
    func updateWatchStatus(request: StopwatchModels.WatchStatusUpdate.Request)
}

protocol StopwatchDataStore {
    var totalMeters: Int? { get set }
    var poolSize: Int? { get set }
    var swimmingStyle: String? { get set }
}

final class StopwatchInteractor: StopwatchBusinessLogic, StopwatchDataStore, WatchDataDelegate {
    // MARK: - Constants
    private enum Constants {
        static let finishString: String = "Финиш"
        static let turnString: String = "Поворот"
        
        static let finishColor: UIColor = .systemRed
        static let turnColor: UIColor = .systemBlue
    }
    
    // MARK: - Fields
    var presenter: StopwatchPresentationLogic?
    
    var totalMeters: Int?
    var poolSize: Int?
    var swimmingStyle: String?
    
    private var timer: Timer?
    private var globalStartTime: Date?
    private var lapStartTime: Date?
    private var currentLapNumber: Int = 0
    private var laps: [StopwatchModels.LapRecording.Response] = []
    
    // Данные для CoreData
    private var startEntity: StartEntity?
    private var currentPulse: Int = 0
    private var currentStrokes: Int = 0
    private var lapPulseData: [Int: Int] = [:]
    private var lapStrokesData: [Int: Int] = [:]
    
    var totalLengths: Int {
        if let totalMeters = totalMeters, let poolSize = poolSize, poolSize > 0 {
            return totalMeters / poolSize
        }
        return 0
    }
    
    private enum StopwatchState {
        case notStarted, running, finished
    }
    private var state: StopwatchState = .notStarted
    
    // MARK: - Инициализация
    init() {
        // Настраиваем связь с Apple Watch
        WatchSessionManager.shared.delegate = self
    }
    
    // MARK: - Handle MainButton Action
    func handleMainButtonAction(request: StopwatchModels.MainButtonAction.Request) {
        switch state {
        case .notStarted:
            // Проверяем, что все необходимые параметры установлены
            guard let poolSize = poolSize,
                  let totalMeters = totalMeters,
                  let swimmingStyle = swimmingStyle else {
                print("ОШИБКА: Не все параметры тренировки установлены")
                return
            }
            
            // Преобразуем стиль плавания в код
            var styleCode: Int
            switch swimmingStyle {
            case "Кроль": styleCode = 0
            case "Брасс": styleCode = 1
            case "Спина": styleCode = 2
            case "Батт": styleCode = 3
            case "К/П" : styleCode = 4
            default: styleCode = 0
            }
            
            print("Отправка параметров на часы: бассейн \(poolSize)м, стиль \(swimmingStyle) (\(styleCode)), дистанция \(totalMeters)м")
            
            // Сначала отправляем параметры тренировки на часы
            WatchSessionManager.shared.sendTrainingParametersToWatch(
                poolSize: Double(poolSize),
                style: styleCode,
                meters: totalMeters
            )
            
            // Даем немного времени на доставку параметров
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                
                // Запуск секундомера
                self.state = .running
                self.currentLapNumber = 1
                self.globalStartTime = Date()
                self.lapStartTime = self.globalStartTime
                self.startTimer()
                
                // Определяем заголовок кнопки: если всего один отрезок — сразу "Финиш", иначе "Поворот"
                let nextTitle = (self.totalLengths == 1) ? Constants.finishString : Constants.turnString
                let nextColor = (self.totalLengths == 1) ? Constants.finishColor : Constants.turnColor
                let response = StopwatchModels.MainButtonAction.Response(nextButtonTitle: nextTitle,
                                                                         nextButtonColor: nextColor)
                self.presenter?.presentMainButtonAction(response: response)
                
                // Создаём первый активный отрезок с нулевым временем
                let lapResponse = StopwatchModels.LapRecording.Response(lapNumber: self.currentLapNumber, lapTime: 0)
                self.laps.append(lapResponse)
                self.presenter?.presentLapRecording(response: lapResponse)
                
                // Отправляем команду на часы о начале тренировки после отправки параметров
                WatchSessionManager.shared.sendCommandToWatch("start")
                
                // Создаем запись в CoreData
                self.createStartEntity()
            }
            
        case .running:
            // Фиксируем текущий отрезок
            guard let lapStart = lapStartTime else { return }
            let now = Date()
            let lapTime = now.timeIntervalSince(lapStart)
            let lapResponse = StopwatchModels.LapRecording.Response(lapNumber: currentLapNumber, lapTime: lapTime)
            // Обновляем активный отрезок (последний в списке)
            laps[laps.count - 1] = lapResponse
            presenter?.presentLapRecording(response: lapResponse)
            
            // Сохраняем пульс и гребки для текущего отрезка
            if lapPulseData[currentLapNumber] == nil {
                lapPulseData[currentLapNumber] = currentPulse
            }
            
            if lapStrokesData[currentLapNumber] == nil {
                lapStrokesData[currentLapNumber] = currentStrokes
                // Сбрасываем счетчик гребков для следующего отрезка
                currentStrokes = 0
            }
            
            // Сохраняем завершенный отрезок в CoreData
            saveLapToCoreData(lapNumber: currentLapNumber)
            
            // Переходим к следующему отрезку
            currentLapNumber += 1
            lapStartTime = now
            
            // Если количество отрезков превышает разрешённое, завершаем секундомер
            if currentLapNumber > totalLengths {
                finishStopwatch()
            } else {
                let nextTitle = (currentLapNumber == totalLengths) ? Constants.finishString : Constants.turnString
                let nextColor = (currentLapNumber == totalLengths) ? Constants.finishColor : Constants.turnColor
                let response = StopwatchModels.MainButtonAction.Response(nextButtonTitle: nextTitle,
                                                                         nextButtonColor: nextColor)
                presenter?.presentMainButtonAction(response: response)
                
                // Создаём новый активный отрезок
                let newLapResponse = StopwatchModels.LapRecording.Response(lapNumber: currentLapNumber, lapTime: 0)
                laps.append(newLapResponse)
                presenter?.presentLapRecording(response: newLapResponse)
            }
            
        case .finished:
            // Если секундомер завершён, нажатия игнорируем
            break
        }
    }
    
    // MARK: - TimerTick
    func timerTick(request: StopwatchModels.TimerTick.Request) {
        guard state == .running, let globalStart = globalStartTime, let lapStart = lapStartTime else { return }
        let now = Date()
        let globalTime = now.timeIntervalSince(globalStart)
        let lapTime = now.timeIntervalSince(lapStart)
        let response = StopwatchModels.TimerTick.Response(globalTime: globalTime, lapTime: lapTime)
        presenter?.presentTimerTick(response: response)
    }
    
    // MARK: - Обработка данных с Watch
    func updatePulseData(request: StopwatchModels.PulseUpdate.Request) {
        currentPulse = request.pulse
        
        // Если есть активный отрезок, обновляем его пульс
        if state == .running {
            lapPulseData[currentLapNumber] = currentPulse
        }
    }
    
    func updateStrokeCount(request: StopwatchModels.StrokeUpdate.Request) {
        currentStrokes = request.strokes
        
        // Если есть активный отрезок, обновляем количество его гребков
        if state == .running {
            lapStrokesData[currentLapNumber] = currentStrokes
        }
    }
    
    func updateWatchStatus(request: StopwatchModels.WatchStatusUpdate.Request) {
        // Обрабатываем статус часов при необходимости
        print("Получен статус от часов: \(request.status)")
    }
    
    // MARK: - WatchDataDelegate
    func didReceiveHeartRate(_ pulse: Int) {
        let request = StopwatchModels.PulseUpdate.Request(pulse: pulse)
        updatePulseData(request: request)
    }
    
    func didReceiveStrokeCount(_ strokes: Int) {
        let request = StopwatchModels.StrokeUpdate.Request(strokes: strokes)
        updateStrokeCount(request: request)
    }
    
    func didReceiveWatchStatus(_ status: String) {
        let request = StopwatchModels.WatchStatusUpdate.Request(status: status)
        updateWatchStatus(request: request)
    }
    
    // MARK: - CoreData Operations
    private func createStartEntity() {
        guard let poolSize = poolSize,
              let totalMeters = totalMeters,
              let swimmingStyle = swimmingStyle else { return }
        
        // Преобразуем строковый стиль плавания в Int16
        var styleValue: Int16 = 0
        
        // Соответствие между названием стиля и его числовым кодом
        switch swimmingStyle {
        case "Кроль": styleValue = 0
        case "Брасс": styleValue = 1
        case "Спина": styleValue = 2
        case "Батт": styleValue = 3
        case "К/П" : styleValue = 4
        default: styleValue = 0
        }
        
        // Создаем запись о старте в CoreData
        startEntity = CoreDataManager.shared.createStart(
            poolSize: Int16(poolSize),
            totalMeters: Int16(totalMeters),
            swimmingStyle: styleValue
        )
    }
    
    private func saveLapToCoreData(lapNumber: Int) {
        guard let startEntity = startEntity else { return }
        
        // Получаем данные отрезка
        guard let lapResponse = laps.first(where: { $0.lapNumber == lapNumber }) else { return }
        
        // Получаем пульс и гребки для отрезка
        let pulse = lapPulseData[lapNumber] ?? 0
        let strokes = lapStrokesData[lapNumber] ?? 0
        
        // Сохраняем отрезок в CoreData
        let _ = CoreDataManager.shared.createLap(
            lapTime: lapResponse.lapTime,
            pulse: Int16(pulse),
            strokes: Int16(strokes),
            lapNumber: Int16(lapNumber),
            startEntity: startEntity
        )
    }
    
    // MARK: - Private Methods
    private func startTimer() {
        // Таймер обновляется каждые 0.01 секунды; добавляем его в RunLoop в режиме .common,
        // чтобы он не замирал при прокрутке TableView
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.timerTick(request: StopwatchModels.TimerTick.Request())
        }
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func finishStopwatch() {
        state = .finished
        stopTimer()
        
        // Отправляем команду остановки на часы
        WatchSessionManager.shared.sendCommandToWatch("stop")
        
        // Сохраняем последний отрезок в CoreData если он существует
        if let lastLap = laps.last {
            lapPulseData[lastLap.lapNumber] = currentPulse
            lapStrokesData[lastLap.lapNumber] = currentStrokes
            saveLapToCoreData(lapNumber: lastLap.lapNumber)
        }
        
        // Сохраняем общее время тренировки в CoreData
        if let startEntity = startEntity, let globalStart = globalStartTime {
            let totalTime = Date().timeIntervalSince(globalStart)
            CoreDataManager.shared.updateStartTotalTime(startEntity, totalTime: totalTime)
        }
        
        let response = StopwatchModels.Finish.Response(
            finalButtonTitle: Constants.finishString,
            finalButtonColor: UIColor.systemGray,
            dataSaved: true
        )
        presenter?.presentFinish(response: response)
    }
}
