//
//  StopwatchInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.02.2025.
//

import UIKit
import WatchConnectivity
import HealthKit

protocol StopwatchBusinessLogic {
    func handleMainButtonAction(request: StopwatchModels.MainButtonAction.Request)
    func timerTick(request: StopwatchModels.TimerTick.Request)
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
    
    private var startEntity: StartEntity?
    
    private let healthStore = HKHealthStore()
    private var isFinalizingWorkout: Bool = false
    private var strokeDataQueryCompleted = false
    private var heartRateQueryCompleted = false
    private var isWaitingForWatchConfirmation = false
    private var workoutStopTime: Date?
    
    // MARK: - Initialization
    init() {
        WatchSessionManager.shared.delegate = self
        requestHealthKitPermissions()
    }
    
    private func requestHealthKitPermissions() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if !success {
                print("Ошибка при запросе разрешений HealthKit: \(String(describing: error))")
            }
        }
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
    
    func updateWatchStatus(request: StopwatchModels.WatchStatusUpdate.Request) {
        print("Получен статус от часов: \(request.status)")
        if request.status == "stopped" || request.status == "workoutStopped" {
            if isWaitingForWatchConfirmation {
                isWaitingForWatchConfirmation = false
                // Запрашиваем данные из HealthKit
                fetchHealthKitDataAndSave()
            }
        }
    }
    
    // MARK: - WatchDataDelegate
    func didReceiveHeartRate(_ pulse: Int) {
    }
    
    func didReceiveStrokeCount(_ strokes: Int) {
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
    
    // MARK: - HealthKit Data Fetching
    private func fetchHealthKitDataAndSave() {
        print("DEBUG: Установка задержки 20 секунд перед запросом данных из HealthKit")
        DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) { [weak self] in
            guard let self = self else { return }
            print("DEBUG: Начинаем запрос данных из HealthKit после задержки")
            self.queryHeartRateDataFromHealth()
            self.queryStrokeDataFromHealth()
        }
    }
    
    private func queryHeartRateDataFromHealth() {
        print("DEBUG: Запрос данных о пульсе из HealthKit")
        guard let startTime = globalStartTime, let stopTime = workoutStopTime else {
            print("ERROR: Не удалось определить время начала или окончания тренировки")
            heartRateQueryCompleted = true
            return
        }
        
        // Запас к временному диапазону
        let extendedStartTime = startTime.addingTimeInterval(-5.0)
        let extendedStopTime = stopTime.addingTimeInterval(5.0)
        
        heartRateQueryCompleted = false
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            print("ERROR: Не удалось получить тип данных для пульса")
            heartRateQueryCompleted = true
            return
        }
        
        // Создаем предикат для временного диапазона с расширенными границами
        let predicate = HKQuery.predicateForSamples(withStart: extendedStartTime, end: extendedStopTime, options: [])
        print("DEBUG: Запрос пульса в диапазоне \(extendedStartTime) - \(extendedStopTime)")
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        let query = HKSampleQuery(sampleType: heartRateType,
                                  predicate: predicate,
                                  limit: 200,
                                  sortDescriptors: [sortDescriptor]) { [weak self] (_, samples, error) in
            
            guard let self = self else { return }
            if let error = error {
                print("ERROR: Ошибка при получении данных о пульсе: \(error.localizedDescription)")
                self.heartRateQueryCompleted = true
                return
            }
            
            guard let heartRateSamples = samples as? [HKQuantitySample], !heartRateSamples.isEmpty else {
                print("DEBUG: Нет данных о пульсе в HealthKit")
                for lapNumber in 1...self.totalLengths {
                    self.lapPulseData[lapNumber] = 0
                }
                self.heartRateQueryCompleted = true
                self.checkAllQueriesCompleted()
                return
            }
            print("DEBUG: Получено \(heartRateSamples.count) значений пульса из HealthKit")
            self.distributeHeartRates(heartRateSamples)
            self.heartRateQueryCompleted = true
            self.checkAllQueriesCompleted()
        }
        healthStore.execute(query)
    }
    
    private func distributeHeartRates(_ heartRateSamples: [HKQuantitySample]) {
        guard let startTime = globalStartTime, let stopTime = workoutStopTime, totalLengths > 0 else {
            print("DEBUG: Не удалось распределить пульс по отрезкам")
            return
        }
        
        if totalLengths == 1 {
            let sum = heartRateSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
            let avgPulse = Int(sum / Double(heartRateSamples.count))
            lapPulseData[1] = avgPulse
            print("DEBUG: Средний пульс для единственного отрезка: \(avgPulse)")
            return
        }
        
        let totalDuration = stopTime.timeIntervalSince(startTime)
        let lapDuration = totalDuration / Double(totalLengths)
        
        // Группируем значения пульса по отрезкам
        for lapNumber in 1...totalLengths {
            let lapStartOffset = lapDuration * Double(lapNumber - 1)
            let lapEndOffset = lapDuration * Double(lapNumber)
            _ = startTime.addingTimeInterval(lapStartOffset)
            _ = startTime.addingTimeInterval(lapEndOffset)
            
            let lapHeartRates = heartRateSamples.filter { sample in
                let sampleTime = sample.startDate.timeIntervalSince(startTime)
                return sampleTime >= lapStartOffset && sampleTime < lapEndOffset
            }
            
            if !lapHeartRates.isEmpty {
                // Вычисляем средний пульс для отрезка
                let sum = lapHeartRates.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
                let avgPulse = Int(sum / Double(lapHeartRates.count))
                lapPulseData[lapNumber] = avgPulse
                print("DEBUG: Отрезок \(lapNumber): средний пульс \(avgPulse) из \(lapHeartRates.count) показаний")
            } else if !heartRateSamples.isEmpty {
                let sum = heartRateSamples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
                let avgPulse = Int(sum / Double(heartRateSamples.count))
                lapPulseData[lapNumber] = avgPulse
                print("DEBUG: Отрезок \(lapNumber): нет показаний, используем общий средний \(avgPulse)")
            } else {
                lapPulseData[lapNumber] = 0
                print("DEBUG: Отрезок \(lapNumber): нет данных о пульсе, устанавливаем 0")
            }
        }
    }
    
    private func queryStrokeDataFromHealth() {
        print("DEBUG: Запрос данных о гребках из HealthKit")
        guard let startTime = globalStartTime, let stopTime = workoutStopTime else {
            print("ERROR: Не удалось определить время начала или окончания тренировки")
            strokeDataQueryCompleted = true
            return
        }
        
        let extendedStartTime = startTime.addingTimeInterval(-5.0)
        let extendedStopTime = stopTime.addingTimeInterval(5.0)
        print("DEBUG: Запрос гребков в диапазоне \(extendedStartTime) - \(extendedStopTime)")
        strokeDataQueryCompleted = false
        
        guard let strokeType = HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount) else {
            print("ERROR: Не удалось получить тип данных для гребков")
            strokeDataQueryCompleted = true
            return
        }
        let predicate = HKQuery.predicateForSamples(withStart: extendedStartTime, end: extendedStopTime, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Создаем запрос для получения последних записей о гребках
        let query = HKSampleQuery(sampleType: strokeType,
                                  predicate: predicate,
                                  limit: max(50, totalLengths * 2),
                                  sortDescriptors: [sortDescriptor]) { [weak self] (_, samples, error) in
            
            guard let self = self else { return }
            if let error = error {
                print("ERROR: Ошибка при получении данных о гребках: \(error.localizedDescription)")
                self.strokeDataQueryCompleted = true
                return
            }
            
            guard let strokeSamples = samples as? [HKQuantitySample], !strokeSamples.isEmpty else {
                print("DEBUG: Нет данных о гребках в HealthKit")
                for lapNumber in 1...self.totalLengths {
                    self.lapStrokesData[lapNumber] = 0
                }
                self.strokeDataQueryCompleted = true
                self.checkAllQueriesCompleted()
                return
            }
            print("DEBUG: Получено \(strokeSamples.count) записей о гребках из HealthKit")
            
            strokeSamples.forEach { sample in
                print("DEBUG: Гребки - время: \(sample.startDate), количество: \(sample.quantity.doubleValue(for: HKUnit.count()))")
            }
            let relevantSamples = strokeSamples.filter { sample in
                return sample.startDate >= extendedStartTime && sample.endDate <= extendedStopTime
            }
            print("DEBUG: Отфильтровано \(relevantSamples.count) записей о гребках для текущей тренировки")
            
            if relevantSamples.isEmpty {
                for lapNumber in 1...self.totalLengths {
                    self.lapStrokesData[lapNumber] = 0
                }
            } else if relevantSamples.count >= self.totalLengths {
                for (index, sample) in relevantSamples.prefix(self.totalLengths).enumerated().reversed() {
                    let lapNumber = self.totalLengths - index
                    if lapNumber > 0 && lapNumber <= self.totalLengths {
                        let strokes = Int(sample.quantity.doubleValue(for: HKUnit.count()))
                        self.lapStrokesData[lapNumber] = strokes
                        print("DEBUG: Отрезок \(lapNumber): \(strokes) гребков из HealthKit")
                    }
                }
            } else {
                let totalStrokes = relevantSamples.reduce(0) { $0 + Int($1.quantity.doubleValue(for: HKUnit.count())) }
                let strokesPerLap = totalStrokes / self.totalLengths
                let extraStrokes = totalStrokes % self.totalLengths
                
                for lapNumber in 1...self.totalLengths {
                    let lapStrokes = strokesPerLap + (lapNumber <= extraStrokes ? 1 : 0)
                    self.lapStrokesData[lapNumber] = lapStrokes
                    print("DEBUG: Отрезок \(lapNumber): \(lapStrokes) гребков (равномерное распределение)")
                }
            }
            
            for lapNumber in 1...self.totalLengths {
                if self.lapStrokesData[lapNumber] == nil {
                    self.lapStrokesData[lapNumber] = 0
                    print("DEBUG: Отрезок \(lapNumber): нет данных о гребках, устанавливаем 0")
                }
            }
            self.strokeDataQueryCompleted = true
            self.checkAllQueriesCompleted()
        }
        healthStore.execute(query)
    }
    
    private func checkAllQueriesCompleted() {
        if heartRateQueryCompleted && strokeDataQueryCompleted {
            print("DEBUG: Все запросы данных из HealthKit завершены")
            guard let globalStart = globalStartTime, let stopTime = workoutStopTime else {
                print("ERROR: Не удалось определить время начала или окончания тренировки")
                return
            }
            
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
            
            let totalTime = stopTime.timeIntervalSince(globalStart)
            saveStartEntityWithFinalData(
                globalStart: globalStart,
                totalTime: totalTime,
                styleCode: styleCode
            )
        }
    }
    
    // MARK: - Start and Finish
    private func finishStopwatch() {
        if isFinalizingWorkout {
            return
        }
        isFinalizingWorkout = true
        
        state = .finished
        stopTimer()
        workoutStopTime = Date()
        
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
        
        // Проверяем соединение с часами
        let watchConnected = WCSession.default.isReachable
        print("DEBUG: WCSession.default.isReachable = \(watchConnected)")
        if watchConnected {
            print("DEBUG: Часы подключены, отправляем команду завершения и ждем подтверждения")
            WatchSessionManager.shared.sendCommandToWatch("stop")
            isWaitingForWatchConfirmation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) { [weak self] in
                guard let self = self, self.isWaitingForWatchConfirmation else { return }
                print("DEBUG: Таймаут ожидания подтверждения от часов, запрашиваем данные напрямую")
                self.isWaitingForWatchConfirmation = false
                self.fetchHealthKitDataAndSave()
            }
        } else {
            print("DEBUG: Часы не подключены, запрашиваем данные напрямую")
            fetchHealthKitDataAndSave()
        }
    }
    
    private func saveStartEntityWithFinalData(globalStart: Date, totalTime: TimeInterval, styleCode: Int16) {
        print("DEBUG: Сохранение тренировки. totalTime = \(totalTime) сек.")
        print("DEBUG: Финальные данные о пульсе по отрезкам: \(lapPulseData)")
        print("DEBUG: Финальные данные о гребках по отрезкам: \(lapStrokesData)")
        
        // Собираем данные о каждом отрезке в массив LapData
        var lapDatas: [LapData] = []
        for lapNumber in 1...totalLengths {
            let pulse = Int16(lapPulseData[lapNumber] ?? 0)
            let strokes = Int16(lapStrokesData[lapNumber] ?? 0)
            
            var lapTime: Double = 0
            if let lap = laps.first(where: { $0.lapNumber == lapNumber }) {
                lapTime = lap.lapTime
            }
            lapDatas.append(LapData(lapTime: lapTime, pulse: pulse, strokes: strokes, lapNumber: Int16(lapNumber)))
        }
        
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
        
        self.isFinalizingWorkout = false
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
