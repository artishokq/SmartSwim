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
    
    private struct PendingDataCollection {
        let exerciseId: String
        let startTime: Date
        let endTime: Date
        let timer: Timer
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
        // Записываем метрики завершенного отрезка
        recordLapMetrics()
        
        strokeCountAtLapStart = lastRecordedStrokeCount
        strokesInCurrentLap = 0
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
            
            // Если у текущего упражнения есть интервал, запускаем интервальный таймер
            self.startIntervalTimerIfNeeded()
        }
    }
    
    private func startIntervalTimerIfNeeded() {
        guard let exercise = currentExercise?.exerciseRef else { return }
        
        // Если у упражнения есть интервал, запускаем таймер интервала
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
                    // С интервалом - кнопка активна только когда интервал истек
                    self.shouldShowNextRepButton = self.isIntervalCompleted && !self.isLastRepetition
                    self.canCompleteExercise = self.isIntervalCompleted && self.isLastRepetition
                } else {
                    // Без интервала кнопка для перехода к следующему повторению всегда активна
                    self.shouldShowNextRepButton = !self.isLastRepetition
                    self.canCompleteExercise = self.isLastRepetition
                }
            } else {
                // Для одиночных упражнений
                if exercise.hasInterval && exercise.intervalInSeconds > 0 {
                    // С интервалом можно завершить только когда интервал истек
                    self.shouldShowNextRepButton = false
                    self.canCompleteExercise = self.isIntervalCompleted
                } else {
                    // Без интервала можно завершить в любой момент
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
        DispatchQueue.main.async {
            if var exercise = self.currentExercise {
                exercise.heartRate = heartRate
                self.currentExercise = exercise
                
                self.objectWillChange.send()
                
                let now = Date()
                if self.lastStrokeMetricTime == nil || now.timeIntervalSince(self.lastStrokeMetricTime!) > 4.0 {
                    self.recordLapMetrics()
                    self.lastStrokeMetricTime = now
                }
            }
        }
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
    
    private func recordLapMetrics() {
        guard let exercise = currentExercise else { return }
        
        // Создаем запись о текущем отрезке
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
    
    // Метод для сброса счетчиков гребков при начале нового упражнения
    private func resetStrokeCounters() {
        strokeCountAtLapStart = 0
        strokesInCurrentLap = 0
        lastRecordedStrokeCount = 0
        lastStrokeMetricTime = nil
    }
    
    private func finalizeExerciseDataCollection(exerciseId: String, startTime: Date, endTime: Date) {
        print("Finalizing background data collection for exercise: \(exerciseId)")
        
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
        
        // Преобразуем все упражнения в TransferExerciseInfo
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
        
        // Создаем объект с данными о тренировке
        return TransferWorkoutModels.TransferWorkoutInfo.create(
            workoutId: workout.id,
            workoutName: workout.name,
            poolSize: workout.poolSize,
            startTime: sessionStartTime ?? Date(),
            endTime: endTime,
            totalCalories: workoutKitManager.getWorkoutTotalCalories(),
            exercises: transferExercises
        )
    }
    
    private func sendWorkoutDataWithConfirmation(finalEndTime: Date? = nil) {
        let endTime = finalEndTime ?? Date()
        
        // Подготавливаем данные о тренировке в формате для передачи
        let transferWorkout = prepareTransferWorkoutInfo(finalEndTime: endTime)
        
        // Преобразуем в словарь для передачи через WatchConnectivity
        let workoutDict = transferWorkout.toDictionary()
        
        // Генерируем уникальный идентификатор для этой отправки
        let sendId = UUID().uuidString
        
        // Отправляем данные на iPhone с ожиданием ответа
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
    
    // MARK: - Public Methods
    func startSession() {
        guard sessionState == .notStarted else { return }
        
        print("Starting workout session")
        sessionStartTime = Date()
        
        // Показываем превью первого упражнения
        if !exercises.isEmpty {
            currentExerciseIndex = 0
            prepareExercisePreview(exercises[currentExerciseIndex])
            
            DispatchQueue.main.async {
                self.sessionState = .previewingExercise
                self.objectWillChange.send()
            }
        } else {
            // Если нет упражнений, завершаем тренировку
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
        
        updateButtonState()
        
        // Устанавливаем текущее упражнение и сбрасываем превью
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
                    // Запускаем тренировку WorkoutKit
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if self.workoutActive {
                self.workoutKitManager.stopWorkout()
                self.workoutActive = false
            }
            
            self.sendWorkoutDataWithConfirmation(finalEndTime: sessionEndTime)
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
