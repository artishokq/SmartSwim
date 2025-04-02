//
//  WorkoutSessionService.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import Foundation
import Combine

final class WorkoutSessionService: ObservableObject {
    // MARK: - Published Properties
    @Published var sessionState: SwimWorkoutModels.WorkoutSessionState = .notStarted
    @Published var currentExercise: SwimWorkoutModels.ActiveExerciseData?
    @Published var nextExercisePreview: SwimWorkoutModels.ActiveExerciseData?
    @Published var completedExercises: [SwimWorkoutModels.CompletedExerciseData] = []
    
    @Published var isIntervalCompleted: Bool = false
    @Published var canCompleteExercise: Bool = false
    @Published var intervalTimeRemaining: TimeInterval = 0
    @Published var currentRepetitionNumber: Int = 1
    @Published var totalRepetitions: Int = 1
    @Published var currentCalories: Double = 0
    @Published var isLastRepetition: Bool = true
    @Published var shouldShowNextRepButton: Bool = false
    
    // MARK: - Public Properties
    let workout: SwimWorkoutModels.SwimWorkout
    
    // MARK: - Private Properties
    private let workoutKitManager: WorkoutKitManager
    private let communicationService: WatchCommunicationService
    
    private var exercises: [SwimWorkoutModels.SwimExercise] = []
    private var currentExerciseIndex: Int = 0
    private var sessionStartTime: Date?
    private var exerciseStartTime: Date?
    private var repetitionStartTime: Date?
    private var lapData: [SwimWorkoutModels.LapData] = []
    private var cancellables = Set<AnyCancellable>()
    
    private var sessionTimer: Timer?
    private var exerciseTimer: Timer?
    private var intervalTimer: Timer?
    private var manualRefreshTimer: Timer?
    
    private var sessionTime: TimeInterval = 0
    private var exerciseTime: TimeInterval = 0
    
    private var workoutActive = false
    
    // Флаг получения подтверждения от iPhone
    private var gotWorkoutDataConfirmation = false
    private var subscriptionId: UUID?
    
    // Флаг для предотвращения повторного вызова завершения сессии
    private var isCompletingSession = false
    
    private var strokeCountAtLapStart: Int = 0
    private var strokesInCurrentLap: Int = 0
    private var lastRecordedStrokeCount: Int = 0
    private var lastStrokeMetricTime: Date?
    
    private var allHeartRateReadings: [HeartRateData] = []
    private var heartRateReadings: [HeartRateData] = []
    private var lapHeartRateData: [Int: [HeartRateData]] = [:]
    
    private var exerciseDurations: [String: TimeInterval] = [:]
    
    private var totalCaloriesBurned: Double = 0
    private var lastKnownCalories: Double = 0
    
    private var queryCompleted = false
    
    private struct PendingDataCollection {
        let exerciseId: String
        let startTime: Date
        let endTime: Date
        let timer: Timer
    }
    
    private struct HeartRateData {
        let timestamp: Date
        let value: Double
    }
    
    private var pendingDataCollections: [PendingDataCollection] = []
    
    // MARK: - Initialization
    init(workout: SwimWorkoutModels.SwimWorkout,
         workoutKitManager: WorkoutKitManager = WorkoutKitManager.shared,
         communicationService: WatchCommunicationService = ServiceLocator.shared.communicationService) {
        self.workout = workout
        self.workoutKitManager = workoutKitManager
        self.communicationService = communicationService
        
        // Сортируем упражнения по порядку
        self.exercises = workout.exercises.sorted { $0.orderIndex < $1.orderIndex }
        
        setupSubscriptions()
        startManualRefreshTimer()
    }
    
    deinit {
        if let id = subscriptionId {
            communicationService.unsubscribe(id: id)
        }
        
        for pendingCollection in pendingDataCollections {
            pendingCollection.timer.invalidate()
        }
        pendingDataCollections.removeAll()
        
        stopAllTimers()
        manualRefreshTimer?.invalidate()
        
        if workoutActive {
            workoutKitManager.stopWorkout()
        }
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Подписываемся на обновления пульса
        workoutKitManager.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                guard let self = self else { return }
                self.updateHeartRate(heartRate)
            }
            .store(in: &cancellables)
        
        // Подписываемся на обновления гребков
        workoutKitManager.strokeCountPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] strokeCount in
                guard let self = self else { return }
                self.updateStrokeCount(strokeCount)
            }
            .store(in: &cancellables)
        
        // Подписываемся на обновления калорий
        workoutKitManager.caloriesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] calories in
                guard let self = self else { return }
                
                self.currentCalories = calories
                
                if calories > self.lastKnownCalories {
                    self.lastKnownCalories = calories
                    
                    // Обновляем общее количество сожженных калорий
                    self.totalCaloriesBurned = calories
                }
            }
            .store(in: &cancellables)
        
        // Подписываемся на статус тренировки
        workoutKitManager.workoutStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                guard let self = self else { return }
                print("Workout active state changed: \(isActive)")
                
                self.workoutActive = isActive
                
                if isActive {
                    self.ensureTimersRunning()
                }
            }
            .store(in: &cancellables)
        
        workoutKitManager.lapCompletedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] lapNumber in
                guard let self = self else { return }
                print("Lap completed: \(lapNumber)")
                self.handleLapTransition()
            }
            .store(in: &cancellables)
        
        workoutKitManager.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { errorMessage in
                print("WorkoutKit error: \(errorMessage)")
            }
            .store(in: &cancellables)
        
        subscriptionId = communicationService.subscribe(to: .command) { [weak self] message in
            if message["workoutDataReceived"] != nil {
                self?.gotWorkoutDataConfirmation = true
            }
        }
    }
    
    private func handleLapTransition() {
        let currentLapHeartRate = calculateAverageHeartRate(for: currentRepetitionNumber)
        
        // Создаем запись о текущем отрезке с усредненным пульсом и актуальным количеством гребков
        let lapRecord = SwimWorkoutModels.LapData(
            timestamp: Date(),
            lapNumber: currentRepetitionNumber,
            exerciseId: currentExercise?.exerciseId ?? "",
            distance: (currentExercise?.exerciseRef.meters ?? 0) / (currentExercise?.exerciseRef.repetitions ?? 1),
            lapTime: exerciseTime,
            heartRate: currentLapHeartRate,
            strokes: strokesInCurrentLap
        )
        
        // Сохраняем запись о текущем отрезке
        if let existingIndex = lapData.firstIndex(where: {
            $0.exerciseId == lapRecord.exerciseId && $0.lapNumber == currentRepetitionNumber
        }) {
            lapData[existingIndex] = lapRecord
        } else {
            lapData.append(lapRecord)
        }
        
        strokeCountAtLapStart = lastRecordedStrokeCount
        strokesInCurrentLap = 0
        
        if heartRateReadings.count > 0 {
            lapHeartRateData[currentRepetitionNumber] = heartRateReadings
        }
    }
    
    private func startManualRefreshTimer() {
        // Запускаем таймер для принудительного обновления UI
        manualRefreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self,
                  self.sessionState == .exerciseActive,
                  var exercise = self.currentExercise else { return }
            
            if self.sessionTimer == nil || self.exerciseTimer == nil {
                self.ensureTimersRunning()
            }
            
            exercise.totalSessionTime = self.sessionTime
            exercise.currentRepetitionTime = self.exerciseTime
            DispatchQueue.main.async {
                self.currentExercise = exercise
                self.updateIntervalStatus()
                self.objectWillChange.send()
            }
        }
    }
    
    private func prepareExercisePreview(_ exercise: SwimWorkoutModels.SwimExercise) {
        // Создаем превью упражнения
        let previewData = SwimWorkoutModels.ActiveExerciseData(
            from: exercise,
            index: currentExerciseIndex + 1,
            totalExercises: exercises.count
        )
        
        DispatchQueue.main.async {
            self.nextExercisePreview = previewData
            self.objectWillChange.send()
        }
    }
    
    private func ensureTimersRunning() {
        if sessionTimer == nil || exerciseTimer == nil {
            startTimers()
        }
    }
    
    private func startTimers() {
        stopAllTimers()
        
        // Запускаем таймер сессии в основном потоке
        DispatchQueue.main.async {
            print("Starting timers")
            self.sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.sessionTime += 1.0
                self.updateSessionTime()
            }
            
            // Запускаем таймер упражнения
            self.exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.exerciseTime += 1.0
                self.updateExerciseTime()
                
                self.updateIntervalStatus()
            }
            
            RunLoop.main.add(self.sessionTimer!, forMode: .common)
            RunLoop.main.add(self.exerciseTimer!, forMode: .common)
            
            self.startIntervalTimerIfNeeded()
        }
    }
    
    private func startIntervalTimerIfNeeded() {
        guard let exercise = currentExercise?.exerciseRef else { return }
        
        if exercise.hasInterval && exercise.intervalInSeconds > 0 {
            repetitionStartTime = Date()
            intervalTimeRemaining = TimeInterval(exercise.intervalInSeconds)
            isIntervalCompleted = false
            
            updateButtonState()
        } else {
            isIntervalCompleted = true
            updateButtonState()
        }
    }
    
    private func updateIntervalStatus() {
        guard let exercise = currentExercise?.exerciseRef else { return }
        
        if exercise.hasInterval && exercise.intervalInSeconds > 0 {
            let intervalSeconds = TimeInterval(exercise.intervalInSeconds)
            
            intervalTimeRemaining = max(0, intervalSeconds - exerciseTime)
            
            // Если интервал истек, отмечаем как завершенный
            if exerciseTime >= intervalSeconds && !isIntervalCompleted {
                isIntervalCompleted = true
                
                // Если это было промежуточное повторение, автоматически переходим к следующему
                if currentRepetitionNumber < exercise.repetitions {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                        self?.performNextRepetitionStep()
                    }
                } else {
                    canCompleteExercise = true
                }
                updateButtonState()
            }
        }
    }
    
    func advanceToNextRepetition() {
        guard let exercise = currentExercise?.exerciseRef,
              currentRepetitionNumber < exercise.repetitions else { return }
        
        performNextRepetitionStep()
    }
    
    private func performNextRepetitionStep() {
        guard let exercise = currentExercise?.exerciseRef,
              currentRepetitionNumber < exercise.repetitions else { return }
        
        // Создаем запись о текущем отрезке перед переходом
        recordRepetitionCompletion()
        
        currentRepetitionNumber += 1
        isLastRepetition = currentRepetitionNumber >= exercise.repetitions
        
        exerciseTime = 0
        isIntervalCompleted = false
        repetitionStartTime = Date()
        
        DispatchQueue.main.async {
            if var exerciseData = self.currentExercise {
                exerciseData.currentRepetition = self.currentRepetitionNumber
                exerciseData.currentRepetitionTime = 0
                self.currentExercise = exerciseData
                
                if !self.isLastRepetition {
                    self.canCompleteExercise = false
                }
                
                self.updateButtonState()
                self.objectWillChange.send()
            }
        }
        
        strokeCountAtLapStart = lastRecordedStrokeCount
        strokesInCurrentLap = 0
    }
    
    private func recordRepetitionCompletion() {
        guard let exercise = currentExercise else { return }
        
        // Записываем финальные данные о завершенном отрезке
        let lapRecord = SwimWorkoutModels.LapData(
            timestamp: repetitionStartTime ?? Date(),
            lapNumber: currentRepetitionNumber,
            exerciseId: exercise.exerciseId,
            distance: exercise.exerciseRef.meters / exercise.exerciseRef.repetitions,
            lapTime: exerciseTime,
            heartRate: exercise.heartRate,
            strokes: strokesInCurrentLap
        )
        
        // Заменяем существующие промежуточные данные по этому отрезку
        if let existingIndex = lapData.firstIndex(where: {
            $0.exerciseId == exercise.exerciseId && $0.lapNumber == currentRepetitionNumber
        }) {
            lapData[existingIndex] = lapRecord
        } else {
            lapData.append(lapRecord)
        }
    }
    
    private func updateButtonState() {
        guard let exercise = currentExercise?.exerciseRef else { return }
        
        DispatchQueue.main.async {
            if exercise.repetitions > 1 {
                // Для упражнений с несколькими повторениями
                if exercise.hasInterval && exercise.intervalInSeconds > 0 {
                    self.shouldShowNextRepButton = self.isIntervalCompleted && !self.isLastRepetition
                    self.canCompleteExercise = self.isIntervalCompleted && self.isLastRepetition
                } else {
                    self.shouldShowNextRepButton = !self.isLastRepetition
                    self.canCompleteExercise = self.isLastRepetition
                }
            } else {
                if exercise.hasInterval && exercise.intervalInSeconds > 0 {
                    self.shouldShowNextRepButton = false
                    self.canCompleteExercise = self.isIntervalCompleted
                } else {
                    self.shouldShowNextRepButton = false
                    self.canCompleteExercise = true
                }
            }
            
            self.objectWillChange.send()
        }
    }
    
    private func stopExerciseTimer() {
        exerciseTimer?.invalidate()
        exerciseTimer = nil
        intervalTimer?.invalidate()
        intervalTimer = nil
    }
    
    private func stopAllTimers() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        stopExerciseTimer()
    }
    
    private func updateSessionTime() {
        DispatchQueue.main.async {
            if var exercise = self.currentExercise {
                exercise.totalSessionTime = self.sessionTime
                self.currentExercise = exercise
                self.objectWillChange.send()
            }
        }
    }
    
    private func updateExerciseTime() {
        DispatchQueue.main.async {
            if var exercise = self.currentExercise {
                exercise.currentRepetitionTime = self.exerciseTime
                self.currentExercise = exercise
                self.objectWillChange.send()
            }
        }
    }
    
    private func updateHeartRate(_ heartRate: Double) {
        let newReading = HeartRateData(timestamp: Date(), value: heartRate)
        allHeartRateReadings.append(newReading)
        heartRateReadings.append(newReading)
        
        DispatchQueue.main.async {
            if var exercise = self.currentExercise {
                exercise.heartRate = heartRate
                self.currentExercise = exercise
                self.objectWillChange.send()
            }
        }
    }
    
    private func calculateAverageHeartRate(for lapNumber: Int) -> Double {
        // Есть ли сохраненные данные для этого отрезка
        if let savedReadings = lapHeartRateData[lapNumber], !savedReadings.isEmpty {
            let sum = savedReadings.reduce(0.0) { $0 + $1.value }
            return sum / Double(savedReadings.count)
        }
        
        // Если нет сохраненных данных используем текущие показания
        if !heartRateReadings.isEmpty {
            let sum = heartRateReadings.reduce(0.0) { $0 + $1.value }
            return sum / Double(heartRateReadings.count)
        }
        
        return currentExercise?.heartRate ?? 0
    }
    
    private func updateStrokeCount(_ strokeCount: Int) {
        if strokeCount == lastRecordedStrokeCount {
            return
        }
        
        DispatchQueue.main.async {
            if var exercise = self.currentExercise {
                self.strokesInCurrentLap = strokeCount - self.strokeCountAtLapStart
                
                exercise.strokeCount = self.strokesInCurrentLap
                self.currentExercise = exercise
                
                self.objectWillChange.send()
                
                let now = Date()
                if self.lastStrokeMetricTime == nil || now.timeIntervalSince(self.lastStrokeMetricTime!) > 5.0 {
                    self.recordLapMetrics()
                    self.lastStrokeMetricTime = now
                }
                
                self.lastRecordedStrokeCount = strokeCount
            }
        }
    }
    
    private func distributeHeartRateReadings() {
        if completedExercises.isEmpty || allHeartRateReadings.isEmpty {
            return
        }
        
        print("Распределение \(allHeartRateReadings.count) показаний пульса между \(completedExercises.count) упражнениями")
        
        var totalDuration: TimeInterval = 0
        var exerciseTimings: [(exerciseId: String, duration: TimeInterval)] = []
        
        for exercise in completedExercises {
            let duration = exercise.endTime.timeIntervalSince(exercise.startTime)
            totalDuration += duration
            exerciseTimings.append((exerciseId: exercise.exerciseId, duration: duration))
        }
        
        let sortedHeartRates = allHeartRateReadings.sorted { $0.timestamp < $1.timestamp }
        let totalReadings = sortedHeartRates.count
        
        if totalDuration <= 0 || totalReadings <= 0 {
            return
        }
        
        var startIndex = 0
        for i in 0..<exerciseTimings.count {
            let timing = exerciseTimings[i]
            
            // Рассчитываем количество показаний для этого упражнения пропорционально его длительности
            let proportion = timing.duration / totalDuration
            let readingsForExercise = Int(Double(totalReadings) * proportion)
            let endIndex = min(startIndex + readingsForExercise, totalReadings)
            
            if startIndex < endIndex {
                let exerciseReadings = Array(sortedHeartRates[startIndex..<endIndex])
                
                updateLapHeartRates(for: timing.exerciseId, with: exerciseReadings)
                startIndex = endIndex
            }
        }
        
        if startIndex < totalReadings && !completedExercises.isEmpty {
            let lastExerciseId = completedExercises.last!.exerciseId
            let remainingReadings = Array(sortedHeartRates[startIndex..<totalReadings])
            updateLapHeartRates(for: lastExerciseId, with: remainingReadings)
        }
    }
    
    private func updateLapHeartRates(for exerciseId: String, with heartRates: [HeartRateData]) {
        guard !heartRates.isEmpty else { return }
        
        guard let exerciseIndex = completedExercises.firstIndex(where: { $0.exerciseId == exerciseId }) else {
            return
        }
        
        let existingLaps = completedExercises[exerciseIndex].laps
        if existingLaps.isEmpty {
            return
        }
        
        var newLaps: [SwimWorkoutModels.LapData] = []
        if existingLaps.count == 1 {
            let avgHeartRate = heartRates.reduce(0.0) { $0 + $1.value } / Double(heartRates.count)
            
            let lap = existingLaps[0]
            let newLap = SwimWorkoutModels.LapData(
                timestamp: lap.timestamp,
                lapNumber: lap.lapNumber,
                exerciseId: lap.exerciseId,
                distance: lap.distance,
                lapTime: lap.lapTime,
                heartRate: avgHeartRate,
                strokes: lap.strokes
            )
            newLaps.append(newLap)
            
            if let lapIndex = lapData.firstIndex(where: {
                $0.exerciseId == exerciseId && $0.lapNumber == lap.lapNumber
            }) {
                let oldLap = lapData[lapIndex]
                let updatedLapData = SwimWorkoutModels.LapData(
                    timestamp: oldLap.timestamp,
                    lapNumber: oldLap.lapNumber,
                    exerciseId: oldLap.exerciseId,
                    distance: oldLap.distance,
                    lapTime: oldLap.lapTime,
                    heartRate: avgHeartRate,
                    strokes: oldLap.strokes
                )
                lapData[lapIndex] = updatedLapData
            }
        } else {
            let totalLapTime = existingLaps.reduce(0.0) { $0 + $1.lapTime }
            if totalLapTime <= 0 {
                return
            }
            
            var startIndex = 0
            let totalReadings = heartRates.count
            
            for lap in existingLaps {
                let proportion = lap.lapTime / totalLapTime
                let readingsForLap = max(1, Int(Double(totalReadings) * proportion))
                let endIndex = min(startIndex + readingsForLap, totalReadings)
                
                var lapHeartRate = lap.heartRate
                
                if startIndex < endIndex {
                    let lapReadings = Array(heartRates[startIndex..<endIndex])
                    lapHeartRate = lapReadings.reduce(0.0) { $0 + $1.value } / Double(lapReadings.count)
                    
                    if let lapIndex = lapData.firstIndex(where: {
                        $0.exerciseId == exerciseId && $0.lapNumber == lap.lapNumber
                    }) {
                        let oldLap = lapData[lapIndex]
                        let updatedLapData = SwimWorkoutModels.LapData(
                            timestamp: oldLap.timestamp,
                            lapNumber: oldLap.lapNumber,
                            exerciseId: oldLap.exerciseId,
                            distance: oldLap.distance,
                            lapTime: oldLap.lapTime,
                            heartRate: lapHeartRate,
                            strokes: oldLap.strokes
                        )
                        lapData[lapIndex] = updatedLapData
                    }
                    
                    startIndex = endIndex
                }
                
                let newLap = SwimWorkoutModels.LapData(
                    timestamp: lap.timestamp,
                    lapNumber: lap.lapNumber,
                    exerciseId: lap.exerciseId,
                    distance: lap.distance,
                    lapTime: lap.lapTime,
                    heartRate: lapHeartRate,
                    strokes: lap.strokes
                )
                newLaps.append(newLap)
            }
        }
        
        let currentExercise = completedExercises[exerciseIndex]
        let updatedExercise = SwimWorkoutModels.CompletedExerciseData(
            exerciseId: currentExercise.exerciseId,
            startTime: currentExercise.startTime,
            endTime: currentExercise.endTime,
            laps: newLaps
        )
        
        completedExercises[exerciseIndex] = updatedExercise
    }
    
    private func requestFinalStrokeData() {
        guard let sessionStartTime = sessionStartTime else { return }
        let endTime = Date()
        
        workoutKitManager.queryFinalStrokeCount(from: sessionStartTime, to: endTime) { [weak self] totalStrokeCount in
            guard let self = self else { return }
            
            print("Получены финальные данные о гребках: \(totalStrokeCount)")
            self.queryCompleted = true
            
            DispatchQueue.main.async {
                self.distributeStrokesAcrossLaps(totalStrokes: totalStrokeCount)
            }
        }
    }
    
    private func distributeStrokesAcrossLaps(totalStrokes: Int) {
        var totalLaps = 0
        var exerciseLaps: [String: Int] = [:]
        
        for exercise in completedExercises {
            let lapsInExercise = exercise.laps.count
            totalLaps += lapsInExercise
            exerciseLaps[exercise.exerciseId] = lapsInExercise
        }
        
        if totalLaps == 0 {
            return
        }
        
        // Если у нас только один отрезок все гребки идут на него
        if totalLaps == 1, let firstExercise = completedExercises.first, !firstExercise.laps.isEmpty {
            let lapIndex = lapData.firstIndex {
                $0.exerciseId == firstExercise.exerciseId && $0.lapNumber == firstExercise.laps[0].lapNumber
            }
            
            if let index = lapIndex {
                // Создаем новый экземпляр структуры с обновленным значением гребков
                let oldLap = lapData[index]
                let newLap = SwimWorkoutModels.LapData(
                    timestamp: oldLap.timestamp,
                    lapNumber: oldLap.lapNumber,
                    exerciseId: oldLap.exerciseId,
                    distance: oldLap.distance,
                    lapTime: oldLap.lapTime,
                    heartRate: oldLap.heartRate,
                    strokes: totalStrokes
                )
                lapData[index] = newLap
            }
            return
        }
        
        var remainingStrokes = totalStrokes
        var processedLapIndices: [Int] = []
        
        // Рраспределяем известные гребки
        for (_, exercise) in completedExercises.enumerated() {
            for (_, lap) in exercise.laps.enumerated() {
                if let dataIndex = lapData.firstIndex(where: {
                    $0.exerciseId == exercise.exerciseId && $0.lapNumber == lap.lapNumber
                }) {
                    // Если у нас уже есть ненулевое количество гребков, оставляем его
                    if lapData[dataIndex].strokes > 0 {
                        remainingStrokes -= lapData[dataIndex].strokes
                    }
                    processedLapIndices.append(dataIndex)
                }
            }
        }
        
        // Распределяем оставшиеся гребки равномерно по оставшимся отрезкам
        let remainingLaps = totalLaps - processedLapIndices.count
        if remainingLaps > 0 && remainingStrokes > 0 {
            let strokesPerLap = remainingStrokes / remainingLaps
            let extraStrokes = remainingStrokes % remainingLaps
            
            var extraDistributed = 0
            
            // Распределяем равномерно между отрезками
            for (_, exercise) in completedExercises.enumerated() {
                for (_, lap) in exercise.laps.enumerated() {
                    if let dataIndex = lapData.firstIndex(where: {
                        $0.exerciseId == exercise.exerciseId && $0.lapNumber == lap.lapNumber
                    }), !processedLapIndices.contains(dataIndex) {
                        let oldLap = lapData[dataIndex]
                        var newStrokeCount = strokesPerLap
                        if extraDistributed < extraStrokes {
                            newStrokeCount += 1
                            extraDistributed += 1
                        }
                        
                        let newLap = SwimWorkoutModels.LapData(
                            timestamp: oldLap.timestamp,
                            lapNumber: oldLap.lapNumber,
                            exerciseId: oldLap.exerciseId,
                            distance: oldLap.distance,
                            lapTime: oldLap.lapTime,
                            heartRate: oldLap.heartRate,
                            strokes: newStrokeCount
                        )
                        lapData[dataIndex] = newLap
                    }
                }
            }
        }
        print("DEBUG: Распределены гребки по отрезкам из финального запроса")
    }
    
    private func recordLapMetrics() {
        guard let exercise = currentExercise else { return }
        let lapRecord = SwimWorkoutModels.LapData(
            timestamp: Date(),
            lapNumber: currentRepetitionNumber,
            exerciseId: exercise.exerciseId,
            distance: exercise.exerciseRef.meters / exercise.exerciseRef.repetitions,
            lapTime: exerciseTime,
            heartRate: exercise.heartRate,
            strokes: strokesInCurrentLap
        )
        
        if let existingIndex = lapData.firstIndex(where: {
            $0.exerciseId == exercise.exerciseId && $0.lapNumber == currentRepetitionNumber
        }) {
            lapData[existingIndex] = lapRecord
        } else {
            lapData.append(lapRecord)
        }
    }
    
    private func resetStrokeCounters() {
        strokeCountAtLapStart = 0
        strokesInCurrentLap = 0
        lastRecordedStrokeCount = 0
        lastStrokeMetricTime = nil
    }
    
    private func finalizeExerciseDataCollection(exerciseId: String, startTime: Date, endTime: Date) {
        print("Finalizing background data collection for exercise: \(exerciseId)")
        let duration = endTime.timeIntervalSince(startTime)
        exerciseDurations[exerciseId] = duration
        
        let exerciseLaps = lapData.filter { $0.exerciseId == exerciseId }
        let completedExercise = SwimWorkoutModels.CompletedExerciseData(
            exerciseId: exerciseId,
            startTime: startTime,
            endTime: endTime,
            laps: exerciseLaps
        )
        
        if let existingIndex = completedExercises.firstIndex(where: { $0.exerciseId == exerciseId }) {
            completedExercises[existingIndex] = completedExercise
        } else {
            completedExercises.append(completedExercise)
        }
    }
    
    // MARK: - Отправка данных о выполненной тренировке
    private func prepareTransferWorkoutInfo(finalEndTime: Date? = nil) -> TransferWorkoutModels.TransferWorkoutInfo {
        let endTime = finalEndTime ?? Date()
        distributeHeartRateReadings()
        
        let transferExercises = completedExercises.enumerated().map { index, completedExercise -> TransferWorkoutModels.TransferExerciseInfo in
            let originalExercise = exercises.first { $0.id == completedExercise.exerciseId }!
            
            let transferLaps = completedExercise.laps.map { lap -> TransferWorkoutModels.TransferLapInfo in
                return TransferWorkoutModels.TransferLapInfo.create(
                    timestamp: lap.timestamp,
                    lapNumber: lap.lapNumber,
                    exerciseId: lap.exerciseId,
                    distance: lap.distance,
                    lapTime: lap.lapTime,
                    heartRate: lap.heartRate,
                    strokes: lap.strokes
                )
            }
            
            return TransferWorkoutModels.TransferExerciseInfo.create(
                exerciseId: completedExercise.exerciseId,
                orderIndex: index,
                description: originalExercise.description,
                style: originalExercise.style,
                type: originalExercise.type,
                hasInterval: originalExercise.hasInterval,
                intervalMinutes: originalExercise.intervalMinutes,
                intervalSeconds: originalExercise.intervalSeconds,
                meters: originalExercise.meters,
                repetitions: originalExercise.repetitions,
                startTime: completedExercise.startTime,
                endTime: completedExercise.endTime,
                laps: transferLaps
            )
        }
        
        let healthKitCalories = workoutKitManager.getWorkoutTotalCalories()
        let finalCalories = max(totalCaloriesBurned, max(healthKitCalories, lastKnownCalories))
        return TransferWorkoutModels.TransferWorkoutInfo.create(
            workoutId: workout.id,
            workoutName: workout.name,
            poolSize: workout.poolSize,
            startTime: sessionStartTime ?? Date(),
            endTime: endTime,
            totalCalories: finalCalories,
            exercises: transferExercises
        )
    }
    
    private func sendWorkoutDataWithConfirmation(finalEndTime: Date? = nil) {
        let endTime = finalEndTime ?? Date()
        let transferWorkout = prepareTransferWorkoutInfo(finalEndTime: endTime)
        let workoutDict = transferWorkout.toDictionary()
        let sendId = UUID().uuidString
        
        communicationService.sendMessageWithReply(
            type: .command,
            data: [
                "completedWorkoutData": workoutDict,
                "sendId": sendId
            ],
            timeout: 5.0
        ) { [weak self] response in
            if let confirmed = response?["workoutDataReceived"] as? Bool, confirmed {
                print("Received confirmation from iPhone for workout data")
                self?.gotWorkoutDataConfirmation = true
            } else {
                self?.retrySendOnce(transferWorkout: transferWorkout, sendId: sendId)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            guard let self = self, !self.gotWorkoutDataConfirmation else { return }
            self.retrySendOnce(transferWorkout: transferWorkout, sendId: sendId)
        }
    }
    
    private func retrySendOnce(transferWorkout: TransferWorkoutModels.TransferWorkoutInfo, sendId: String) {
        guard !gotWorkoutDataConfirmation else { return }
        
        print("Retrying workout data send once")
        let workoutDict = transferWorkout.toDictionary()
        
        communicationService.sendMessageWithReply(
            type: .command,
            data: [
                "completedWorkoutData": workoutDict,
                "sendId": sendId,
                "isRetry": true
            ],
            timeout: 5.0
        ) { [weak self] response in
            if let confirmed = response?["workoutDataReceived"] as? Bool, confirmed {
                print("Received confirmation from iPhone for retry workout data")
                self?.gotWorkoutDataConfirmation = true
            }
        }
    }
    
    private func finalizeWorkout(sessionEndTime: Date) {
        if workoutActive {
            let currentHealthKitCalories = workoutKitManager.getWorkoutTotalCalories()
            if currentHealthKitCalories > 0 {
                totalCaloriesBurned = max(totalCaloriesBurned, currentHealthKitCalories)
                lastKnownCalories = max(lastKnownCalories, currentHealthKitCalories)
            }
            
            workoutKitManager.stopWorkout()
            workoutActive = false
        }
        
        print("Завершение тренировки. Всего сожжено калорий: \(totalCaloriesBurned)")
        self.sendWorkoutDataWithConfirmation(finalEndTime: sessionEndTime)
    }
    
    // MARK: - Public Methods
    func startSession() {
        guard sessionState == .notStarted else { return }
        
        print("Starting workout session")
        sessionStartTime = Date()
        
        allHeartRateReadings = []
        heartRateReadings = []
        lapHeartRateData = [:]
        exerciseDurations = [:]
        
        lastKnownCalories = 0
        totalCaloriesBurned = 0
        currentCalories = 0
        
        if !exercises.isEmpty {
            currentExerciseIndex = 0
            prepareExercisePreview(exercises[currentExerciseIndex])
            
            DispatchQueue.main.async {
                self.sessionState = .previewingExercise
                self.objectWillChange.send()
            }
        } else {
            completeSession()
        }
    }
    
    func startCurrentExercise() {
        guard (sessionState == .previewingExercise || sessionState == .countdown),
              let preview = nextExercisePreview else { return }
        
        print("Starting current exercise")
        
        exerciseTime = 0
        isIntervalCompleted = false
        canCompleteExercise = false
        currentRepetitionNumber = 1
        
        let exerciseRef = exercises[currentExerciseIndex]
        totalRepetitions = exerciseRef.repetitions
        isLastRepetition = currentRepetitionNumber >= totalRepetitions
        
        resetStrokeCounters()
        heartRateReadings = []
        updateButtonState()
        
        DispatchQueue.main.async {
            self.currentExercise = preview
            self.nextExercisePreview = nil
            self.sessionState = .exerciseActive
            self.objectWillChange.send()
        }
        
        exerciseStartTime = Date()
        repetitionStartTime = Date()
        self.startTimers()
        
        if !workoutActive {
            workoutKitManager.requestAuthorization { [weak self] success, error in
                guard let self = self, success else {
                    print("Failed to get authorization: \(String(describing: error))")
                    return
                }
                
                DispatchQueue.main.async {
                    print("Starting WorkoutKit monitoring")
                    self.workoutKitManager.startWorkout(workout: self.workout)
                }
            }
        }
        
        if let exercise = self.currentExercise?.exerciseRef {
            if exercise.hasInterval && exercise.intervalInSeconds > 0 {
                self.isIntervalCompleted = false
                self.canCompleteExercise = false
                self.intervalTimeRemaining = TimeInterval(exercise.intervalInSeconds)
            } else if exercise.repetitions > 1 {
                self.shouldShowNextRepButton = true
                self.canCompleteExercise = false
            } else {
                self.canCompleteExercise = true
            }
            
            self.objectWillChange.send()
        }
    }
    
    func completeCurrentExercise() {
        guard sessionState == .exerciseActive,
              let currentExercise = currentExercise,
              let exerciseStartTime = exerciseStartTime else { return }
        
        if !canCompleteExercise {
            if shouldShowNextRepButton {
                performNextRepetitionStep()
                return
            } else {
                return
            }
        }
        
        print("Completing current exercise with background data collection")
        let exerciseEndTime = Date()
        recordRepetitionCompletion()
        
        if !heartRateReadings.isEmpty {
            lapHeartRateData[currentRepetitionNumber] = heartRateReadings
        }
        
        let currentHealthKitCalories = workoutKitManager.getWorkoutTotalCalories()
        if currentHealthKitCalories > 0 {
            totalCaloriesBurned = max(totalCaloriesBurned, currentHealthKitCalories)
            lastKnownCalories = max(lastKnownCalories, currentHealthKitCalories)
        }
        
        let exerciseId = currentExercise.exerciseId
        let backgroundTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] timer in
            guard let self = self else { return }
            
            self.finalizeExerciseDataCollection(exerciseId: exerciseId, startTime: exerciseStartTime, endTime: exerciseEndTime)
            
            self.pendingDataCollections.removeAll { $0.timer === timer }
        }
        
        RunLoop.main.add(backgroundTimer, forMode: .common)
        
        pendingDataCollections.append(PendingDataCollection(
            exerciseId: exerciseId,
            startTime: exerciseStartTime,
            endTime: exerciseEndTime,
            timer: backgroundTimer
        ))
        
        stopExerciseTimer()
        
        let nextIndex = currentExerciseIndex + 1
        if nextIndex < exercises.count {
            currentExerciseIndex = nextIndex
            prepareExercisePreview(exercises[nextIndex])
            
            DispatchQueue.main.async {
                self.sessionState = .previewingExercise
                self.objectWillChange.send()
            }
            
            exerciseTime = 0
            isIntervalCompleted = false
            canCompleteExercise = false
            currentRepetitionNumber = 1
            
            heartRateReadings = []
            resetStrokeCounters()
        } else {
            completeSession()
        }
    }
    
    func completeSession() {
        if isCompletingSession {
            return
        }
        
        isCompletingSession = true
        let sessionEndTime = Date()
        
        DispatchQueue.main.async {
            self.sessionState = .completed
            self.objectWillChange.send()
        }
        
        sessionTimer?.invalidate()
        sessionTimer = nil
        stopExerciseTimer()
        requestFinalStrokeData()
        
        // Ожидаем данных перед завершением
        DispatchQueue.main.asyncAfter(deadline: .now() + 35.0) {
            // Проверяем, получили ли мы данные о гребках
            if !self.queryCompleted {
                self.requestFinalStrokeData()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.finalizeWorkout(sessionEndTime: sessionEndTime)
                }
            } else {
                self.finalizeWorkout(sessionEndTime: sessionEndTime)
            }
        }
    }
    
    func showCountdown() {
        guard sessionState == .previewingExercise,
              let _ = nextExercisePreview else { return }
        
        DispatchQueue.main.async {
            self.sessionState = .countdown
            self.objectWillChange.send()
        }
    }
}
