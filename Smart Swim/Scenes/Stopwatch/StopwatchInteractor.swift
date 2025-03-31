//
//  StopwatchInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.02.2025.
//

import UIKit
import WatchConnectivity

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
    
    // Структура для хранения данных о пульсе за отрезок
    private struct PulseData {
        var readings: [Int] = []
        var timestamps: [Date] = []
        
        // Вычисляет среднее значение пульса
        var average: Int {
            guard !readings.isEmpty else { return 0 }
            let sum = readings.reduce(0, +)
            return sum / readings.count
        }
        
        // Вычисляет максимальное значение пульса
        var max: Int {
            return readings.max() ?? 0
        }
        
        // Добавляет новое измерение пульса
        mutating func addReading(_ value: Int) {
            readings.append(value)
            timestamps.append(Date())
        }
    }
    
    // Данные для пульса и гребков, накапливаем локально
    private var currentPulse: Int = 0
    private var currentStrokes: Int = 0
    private var lapPulseData: [Int: Int] = [:]
    private var lapStrokesData: [Int: Int] = [:]
    
    // Словарь для хранения данных о пульсе по отрезкам
    private var lapPulseReadings: [Int: PulseData] = [:]
    
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
    
    private var startEntity: StartEntity?
    
    // Флаг для предотвращения повторного запуска финализации
    private var isFinalizingWorkout: Bool = false
    
    // MARK: - Initialization
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
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
            
            // Обновляем финальные данные о пульсе для отрезка
            if let pulseData = lapPulseReadings[currentLapNumber] {
                // Сохраняем среднее значение пульса за отрезок
                lapPulseData[currentLapNumber] = pulseData.average
                print("DEBUG: Отрезок \(currentLapNumber) завершен. Средний пульс: \(pulseData.average), максимальный: \(pulseData.max), измерений: \(pulseData.readings.count)")
            } else if currentPulse > 0 {
                // Если нет накопленных данных, но есть текущее значение
                lapPulseData[currentLapNumber] = currentPulse
            }
            
            // Сохраняем данные гребков для текущего отрезка
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
        let newPulse = request.pulse
        currentPulse = newPulse
        
        if state == .running && newPulse > 0 {
            // Добавляем новое измерение пульса в текущий отрезок
            if lapPulseReadings[currentLapNumber] == nil {
                lapPulseReadings[currentLapNumber] = PulseData()
            }
            lapPulseReadings[currentLapNumber]?.addReading(newPulse)
            
            // Обновляем также текущее значение для обратной совместимости
            lapPulseData[currentLapNumber] = newPulse
        }
    }
    
    func updateStrokeCount(request: StopwatchModels.StrokeUpdate.Request) {
        currentStrokes = request.strokes
        print("DEBUG: updateStrokeCount received: \(request.strokes)")
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
    
    // MARK: - Timer Management
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
    
    // MARK: - Start Finish
    private func finishStopwatch() {
        // Защита от повторного вызова
        if isFinalizingWorkout {
            return
        }
        isFinalizingWorkout = true
        
        // Переходим в состояние завершения и останавливаем таймер
        state = .finished
        stopTimer()
        
        // Немедленно обновляем UI, делаем кнопку финиша серой и отключенной
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let immediateResponse = StopwatchModels.Finish.Response(
                finalButtonTitle: Constants.finishString,
                finalButtonColor: UIColor.systemGray,
                dataSaved: false
            )
            self.presenter?.presentFinish(response: immediateResponse)
        }
        
        WatchSessionManager.shared.sendCommandToWatch("stop")
        guard let globalStart = globalStartTime else { return }
        let finishTime = Date()
        let totalTime = finishTime.timeIntervalSince(globalStart)
        
        // Определяем числовой код стиля плавания
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
        
        // Проверяем, подключены ли часы
        let watchConnected = WCSession.default.isReachable
        print("DEBUG: WCSession.default.isReachable = \(watchConnected)")
        
        if watchConnected {
            print("DEBUG: Часы подключены, откладываем сохранение тренировки на 30 секунд для накопления данных")
            
            var receivedFinalStrokeCount = false
            
            // Запрашиваем финальное количество гребков перед сохранением
            func requestFinalStrokeCount() {
                print("DEBUG: Запрашиваем финальное количество гребков от часов")
                
                // Создаем сообщение с запросом финального количества гребков
                let message: [String: Any] = [
                    "requestFinalStrokeCount": true,
                    "startDate": globalStart,
                    "endDate": finishTime
                ]
                
                WCSession.default.sendMessage(message, replyHandler: { [weak self] response in
                    guard let self = self else { return }
                    
                    if let finalCount = response["finalStrokeCount"] as? Int {
                        print("DEBUG: Получено финальное количество гребков: \(finalCount)")
                        receivedFinalStrokeCount = true
                        
                        // Распределяем гребки по отрезкам пропорционально длине
                        self.distributeStrokesAcrossLaps(finalCount)
                    }
                }, errorHandler: { error in
                    print("DEBUG: Ошибка при запросе финального количества гребков: \(error.localizedDescription)")
                })
            }
            
            // Запрашиваем финальные данные как можно раньше
            requestFinalStrokeCount()
            
            // Основной таймер ожидания перед сохранением
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 30) { [weak self] in
                guard let self = self else { return }
                
                // Финальная проверка перед сохранением
                if !receivedFinalStrokeCount {
                    print("DEBUG: Не получены финальные данные о гребках, повторный запрос")
                    requestFinalStrokeCount()
                    
                    // Дополнительная задержка для получения финальных данных
                    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 5) {
                        self.saveStartEntityWithFinalData(
                            globalStart: globalStart,
                            totalTime: totalTime,
                            styleCode: styleCode
                        )
                    }
                } else {
                    self.saveStartEntityWithFinalData(
                        globalStart: globalStart,
                        totalTime: totalTime,
                        styleCode: styleCode
                    )
                }
            }
        } else {
            // Часы не подключены, сохраняем тренировку немедленно
            print("DEBUG: Часы не подключены, сохраняем тренировку немедленно")
            saveStartEntityWithFinalData(
                globalStart: globalStart,
                totalTime: totalTime,
                styleCode: styleCode
            )
        }
    }
    
    // Функция для распределения гребков по отрезкам
    private func distributeStrokesAcrossLaps(_ totalStrokes: Int) {
        // Если нет отрезков или общее количество гребков равно 0, выходим
        guard !self.laps.isEmpty, totalStrokes > 0 else { return }
        
        // Общее количество отрезков
        let totalLaps = self.totalLengths
        
        // Если у нас только один отрезок, присваиваем все гребки ему
        if totalLaps == 1 {
            self.lapStrokesData[1] = totalStrokes
            return
        }
        
        // Равномерное распределение по всем отрезкам
        let baseStrokesPerLap = totalStrokes / totalLaps
        let remainder = totalStrokes % totalLaps
        
        for lapNumber in 1...totalLaps {
            // Добавляем остаточные гребки к последним отрезкам
            let extraStrokes = (lapNumber > totalLaps - remainder) ? 1 : 0
            self.lapStrokesData[lapNumber] = baseStrokesPerLap + extraStrokes
        }
        print("DEBUG: Распределены гребки по отрезкам: \(self.lapStrokesData)")
    }
    
    // Выделяем сохранение данных в отдельный метод для повторного использования
    private func saveStartEntityWithFinalData(globalStart: Date, totalTime: TimeInterval, styleCode: Int16) {
        print("DEBUG: Сохранение тренировки. totalTime = \(totalTime) сек.")
        print("DEBUG: currentPulse = \(self.currentPulse), currentStrokes = \(self.currentStrokes)")
        
        // Финальная обработка данных о пульсе перед сохранением
        for lapNumber in 1...totalLengths {
            if let pulseData = lapPulseReadings[lapNumber], pulseData.readings.count > 0 {
                // Используем среднее значение пульса вместо последнего измерения
                lapPulseData[lapNumber] = pulseData.average
                print("DEBUG: Финальный пульс для отрезка \(lapNumber): \(pulseData.average) (из \(pulseData.readings.count) измерений)")
            }
        }
        
        print("DEBUG: lapPulseData = \(self.lapPulseData)")
        print("DEBUG: lapStrokesData = \(self.lapStrokesData)")
        
        // Собираем данные о каждом отрезке в массив LapData
        let lapDatas: [LapData] = self.laps.map { lap in
            let lapNumber = Int16(lap.lapNumber)
            let pulse = Int16(self.lapPulseData[lap.lapNumber] ?? 0)
            let strokes = Int16(self.lapStrokesData[lap.lapNumber] ?? 0)
            return LapData(lapTime: lap.lapTime, pulse: pulse, strokes: strokes, lapNumber: lapNumber)
        }
        
        // Создаём StartEntity с накопленными данными
        if let start = CoreDataManager.shared.createStart(
            poolSize: Int16(self.poolSize ?? 0),
            totalMeters: Int16(self.totalMeters ?? 0),
            swimmingStyle: styleCode,
            laps: lapDatas,
            date: globalStart
        ) {
            CoreDataManager.shared.updateStartTotalTime(start, totalTime: totalTime)
            self.startEntity = start
            print("DEBUG: StartEntity успешно создан.")
        } else {
            print("DEBUG: Ошибка при создании StartEntity")
        }
        
        // Сбрасываем флаг финализации
        self.isFinalizingWorkout = false
        
        // Обновляем UI, теперь данные сохранены
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let finalResponse = StopwatchModels.Finish.Response(
                finalButtonTitle: Constants.finishString,
                finalButtonColor: UIColor.systemGray,
                dataSaved: true
            )
            self.presenter?.presentFinish(response: finalResponse)
        }
    }
}
