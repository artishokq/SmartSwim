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
}

protocol StopwatchDataStore {
    var totalMeters: Int? { get set }
    var poolSize: Int? { get set }
    var swimmingStyle: String? { get set }
}

final class StopwatchInteractor: StopwatchBusinessLogic, StopwatchDataStore {
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
    
    // MARK: - Handle MainButton Action
    func handleMainButtonAction(request: StopwatchModels.MainButtonAction.Request) {
        switch state {
        case .notStarted:
            // Запуск секундомера
            state = .running
            currentLapNumber = 1
            globalStartTime = Date()
            lapStartTime = globalStartTime
            startTimer()
            
            // Определяем заголовок кнопки: если всего один отрезок — сразу "Финиш", иначе "Поворот"
            let nextTitle = (totalLengths == 1) ? Constants.finishString : Constants.turnString
            let nextColor = (totalLengths == 1) ? Constants.finishColor : Constants.turnColor
            let response = StopwatchModels.MainButtonAction.Response(nextButtonTitle: nextTitle,
                                                                     nextButtonColor: nextColor)
            presenter?.presentMainButtonAction(response: response)
            
            // Создаём первый активный отрезок с нулевым временем
            let lapResponse = StopwatchModels.LapRecording.Response(lapNumber: currentLapNumber, lapTime: 0)
            laps.append(lapResponse)
            presenter?.presentLapRecording(response: lapResponse)
            
        case .running:
            // Фиксируем текущий отрезок
            guard let lapStart = lapStartTime else { return }
            let now = Date()
            let lapTime = now.timeIntervalSince(lapStart)
            let lapResponse = StopwatchModels.LapRecording.Response(lapNumber: currentLapNumber, lapTime: lapTime)
            // Обновляем активный отрезок (последний в списке)
            laps[laps.count - 1] = lapResponse
            presenter?.presentLapRecording(response: lapResponse)
            
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
        let response = StopwatchModels.Finish.Response(finalButtonTitle: Constants.finishString, finalButtonColor: UIColor.systemGray)
        presenter?.presentFinish(response: response)
    }
}
