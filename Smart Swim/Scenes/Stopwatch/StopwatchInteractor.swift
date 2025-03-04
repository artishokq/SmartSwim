//
//  StopwatchInteractor.swift
//  Smart Swim
//
//  Обновлённая версия для сохранения Start аналогично Workout
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
    
    // Данные для пульса и гребков, накапливаем локально
    private var currentPulse: Int = 0
    private var currentStrokes: Int = 0
    private var lapPulseData: [Int: Int] = [:]
    private var lapStrokesData: [Int: Int] = [:]
    
    // Количество отрезков, рассчитываемое по дистанции и размеру бассейна
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
    
    // Core Data объект StartEntity (будет создан при завершении тренировки)
    private var startEntity: StartEntity?
    
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
            
            // Преобразуем стиль плавания в числовой код (Int16)
            var styleCode: Int16 = 0
            switch swimmingStyle {
            case "Кроль": styleCode = 0
            case "Брасс": styleCode = 1
            case "Спина": styleCode = 2
            case "Батт": styleCode = 3
            case "К/П": styleCode = 4
            default: styleCode = 0
            }
            
            print("Отправка параметров на часы: бассейн \(poolSize)м, стиль \(swimmingStyle) (\(styleCode)), дистанция \(totalMeters)м")
            
            // Отправляем параметры тренировки на часы
            WatchSessionManager.shared.sendTrainingParametersToWatch(
                poolSize: Double(poolSize),
                style: Int(styleCode),
                meters: totalMeters
            )
            
            // Немного ждём перед запуском секундомера
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self else { return }
                
                self.state = .running
                self.currentLapNumber = 1
                self.globalStartTime = Date()
                self.lapStartTime = self.globalStartTime
                self.startTimer()
                
                let nextTitle = (self.totalLengths == 1) ? Constants.finishString : Constants.turnString
                let nextColor = (self.totalLengths == 1) ? Constants.finishColor : Constants.turnColor
                let response = StopwatchModels.MainButtonAction.Response(nextButtonTitle: nextTitle,
                                                                         nextButtonColor: nextColor)
                self.presenter?.presentMainButtonAction(response: response)
                
                // Создаём первый активный отрезок (модельное представление)
                let lapResponse = StopwatchModels.LapRecording.Response(lapNumber: self.currentLapNumber, lapTime: 0)
                self.laps.append(lapResponse)
                self.presenter?.presentLapRecording(response: lapResponse)
                
                // Команда для часов о старте тренировки
                WatchSessionManager.shared.sendCommandToWatch("start")
            }
            
        case .running:
            // Завершаем текущий отрезок
            guard let lapStart = lapStartTime else { return }
            let now = Date()
            let lapTime = now.timeIntervalSince(lapStart)
            
            // Обновляем модель текущего отрезка
            let updatedLapResponse = StopwatchModels.LapRecording.Response(lapNumber: currentLapNumber,
                                                                           lapTime: lapTime)
            if let index = laps.firstIndex(where: { $0.lapNumber == currentLapNumber }) {
                laps[index] = updatedLapResponse
            }
            presenter?.presentLapRecording(response: updatedLapResponse)
            
            // Сохраняем данные пульса и гребков для текущего отрезка
            if lapPulseData[currentLapNumber] == nil {
                lapPulseData[currentLapNumber] = currentPulse
            }
            if lapStrokesData[currentLapNumber] == nil {
                lapStrokesData[currentLapNumber] = currentStrokes
                currentStrokes = 0
            }
            
            // Переходим к следующему отрезку
            currentLapNumber += 1
            lapStartTime = now
            
            if currentLapNumber > totalLengths {
                self.finishStopwatch()
            } else {
                let nextTitle = (currentLapNumber == totalLengths) ? Constants.finishString : Constants.turnString
                let nextColor = (currentLapNumber == totalLengths) ? Constants.finishColor : Constants.turnColor
                let response = StopwatchModels.MainButtonAction.Response(nextButtonTitle: nextTitle,
                                                                         nextButtonColor: nextColor)
                presenter?.presentMainButtonAction(response: response)
                
                // Создаём новый активный отрезок (модельное представление)
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
        guard state == .running,
              let globalStart = globalStartTime,
              let lapStart = lapStartTime else { return }
        let now = Date()
        let globalTime = now.timeIntervalSince(globalStart)
        let lapTime = now.timeIntervalSince(lapStart)
        let response = StopwatchModels.TimerTick.Response(globalTime: globalTime, lapTime: lapTime)
        presenter?.presentTimerTick(response: response)
    }
    
    // MARK: - Обработка данных с часов
    func updatePulseData(request: StopwatchModels.PulseUpdate.Request) {
        currentPulse = request.pulse
        if state == .running {
            lapPulseData[currentLapNumber] = currentPulse
        }
    }
    
    func updateStrokeCount(request: StopwatchModels.StrokeUpdate.Request) {
        currentStrokes = request.strokes
        if state == .running {
            lapStrokesData[currentLapNumber] = currentStrokes
        }
    }
    
    func updateWatchStatus(request: StopwatchModels.WatchStatusUpdate.Request) {
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
    
    // MARK: - Таймер
    private func startTimer() {
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
    
    // MARK: - Завершение тренировки
    private func finishStopwatch() {
        state = .finished
        stopTimer()
        WatchSessionManager.shared.sendCommandToWatch("stop")
        
        guard let globalStart = globalStartTime else { return }
        let totalTime = Date().timeIntervalSince(globalStart)
        
        // Собираем данные всех отрезков в массив LapData
        let lapDatas: [LapData] = laps.map { lap in
            let lapNumber = Int16(lap.lapNumber)
            let pulse = Int16(lapPulseData[lap.lapNumber] ?? 0)
            let strokes = Int16(lapStrokesData[lap.lapNumber] ?? 0)
            return LapData(lapTime: lap.lapTime, pulse: pulse, strokes: strokes, lapNumber: lapNumber)
        }
        
        // Определяем код стиля плавания
        var styleCode: Int16 = 0
        if let swimmingStyle = swimmingStyle {
            switch swimmingStyle {
            case "Кроль": styleCode = 0
            case "Брасс": styleCode = 1
            case "Спина": styleCode = 2
            case "Батт": styleCode = 3
            case "К/П": styleCode = 4
            default: styleCode = 0
            }
        }
        
        // Создаём StartEntity вместе с массивом отрезков, аналогично созданию Workout
        if let start = CoreDataManager.shared.createStart(
            poolSize: Int16(poolSize ?? 0),
            totalMeters: Int16(totalMeters ?? 0),
            swimmingStyle: styleCode,
            laps: lapDatas,
            date: globalStart
        ) {
            CoreDataManager.shared.updateStartTotalTime(start, totalTime: totalTime)
            self.startEntity = start
        } else {
            print("Ошибка при создании StartEntity")
            // При необходимости уведомляем презентер об ошибке сохранения
        }
        
        let response = StopwatchModels.Finish.Response(
            finalButtonTitle: Constants.finishString,
            finalButtonColor: UIColor.systemGray,
            dataSaved: true
        )
        presenter?.presentFinish(response: response)
    }
}
