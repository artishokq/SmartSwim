//
//  WorkoutSessionService.swift
//  SSwim Watch App
//

import Foundation
import Combine
import HealthKit

final class WorkoutSessionService: ObservableObject {
    // MARK: - Published Properties
    @Published var sessionState: SwimWorkoutModels.WorkoutSessionState = .notStarted
    @Published var currentExercise: SwimWorkoutModels.ActiveExerciseData?
    @Published var nextExercisePreview: SwimWorkoutModels.ActiveExerciseData?
    @Published var completedExercises: [SwimWorkoutModels.CompletedExerciseData] = []
    
    // Exercise state properties
    @Published var isIntervalCompleted: Bool = false
    @Published var canCompleteExercise: Bool = false
    @Published var intervalTimeRemaining: TimeInterval = 0
    @Published var currentRepetitionNumber: Int = 1
    @Published var totalRepetitions: Int = 1
    @Published var isLastRepetition: Bool = true
    @Published var shouldShowNextRepButton: Bool = false
    
    // MARK: - Public Properties
    let workout: SwimWorkoutModels.SwimWorkout
    
    // MARK: - Private Properties
    private let healthManager: HealthKitManager
    private let communicationService: WatchCommunicationService
    
    private var exercises: [SwimWorkoutModels.SwimExercise] = []
    private var currentExerciseIndex: Int = 0
    private var sessionStartTime: Date?
    private var exerciseStartTime: Date?
    private var repetitionStartTime: Date?
    private var lapData: [SwimWorkoutModels.LapData] = []
    private var cancellables = Set<AnyCancellable>()
    
    // Timer-related properties
    private var sessionTimer: Timer?
    private var exerciseTimer: Timer?
    private var intervalTimer: Timer?
    private var manualRefreshTimer: Timer?
    
    private var sessionTime: TimeInterval = 0
    private var exerciseTime: TimeInterval = 0
    private var currentIntervalTime: TimeInterval = 0
    
    // Track HealthKit workout state
    private var healthKitWorkoutActive = false
    
    // Флаг получения подтверждения от iPhone
    private var gotWorkoutDataConfirmation = false
    private var subscriptionId: UUID?
    
    // MARK: - Initialization
    init(workout: SwimWorkoutModels.SwimWorkout,
         healthManager: HealthKitManager = HealthKitManager.shared,
         communicationService: WatchCommunicationService = ServiceLocator.shared.communicationService) {
        self.workout = workout
        self.healthManager = healthManager
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
        stopAllTimers()
        manualRefreshTimer?.invalidate()
        
        // Ensure HealthKit workout is stopped if still active
        if healthKitWorkoutActive {
            healthManager.stopWorkout()
        }
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Подписываемся на обновления пульса
        healthManager.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                guard let self = self else { return }
                self.updateHeartRate(heartRate)
            }
            .store(in: &cancellables)
        
        // Подписываемся на обновления гребков
        healthManager.strokeCountPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] strokeCount in
                guard let self = self else { return }
                self.updateStrokeCount(strokeCount)
            }
            .store(in: &cancellables)
            
        // Подписываемся на статус тренировки
        healthManager.workoutStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isActive in
                guard let self = self else { return }
                print("Workout active state changed: \(isActive)")
                
                self.healthKitWorkoutActive = isActive
                
                if isActive {
                    // Когда тренировка активирована, убедимся что таймеры работают
                    self.ensureTimersRunning()
                }
            }
            .store(in: &cancellables)
            
        // Подписываемся на ошибки
        healthManager.errorPublisher
            .receive(on: DispatchQueue.main)
            .sink { errorMessage in
                print("HealthKit error: \(errorMessage)")
            }
            .store(in: &cancellables)
            
        // Подписываемся на сообщения через метод subscribe
        subscriptionId = communicationService.subscribe(to: .command) { [weak self] message in
            if message["workoutDataReceived"] != nil {
                // Получили подтверждение от iPhone
                self?.gotWorkoutDataConfirmation = true
            }
        }
    }
    
    private func startManualRefreshTimer() {
        // Запускаем таймер для принудительного обновления UI
        manualRefreshTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self,
                  self.sessionState == .exerciseActive,
                  var exercise = self.currentExercise else { return }
            
            // Обновляем время вручную, если таймеры не сработали
            if self.sessionTimer == nil || self.exerciseTimer == nil {
                self.ensureTimersRunning()
            }
            
            // Принудительно обновляем время в UI
            exercise.totalSessionTime = self.sessionTime
            exercise.currentRepetitionTime = self.exerciseTime
            DispatchQueue.main.async {
                self.currentExercise = exercise
                // Также проверяем состояние интервала
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
        // Убедимся, что таймеры запущены
        if sessionTimer == nil || exerciseTimer == nil {
            startTimers()
        }
    }
    
    private func startTimers() {
        // Сначала остановим существующие таймеры, чтобы избежать дублирования
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
                
                // Обновляем состояние интервала
                self.updateIntervalStatus()
            }
            
            // Добавляем таймеры в RunLoop
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
            // Запоминаем время начала интервала
            repetitionStartTime = Date()
            currentIntervalTime = 0
            intervalTimeRemaining = TimeInterval(exercise.intervalInSeconds)
            isIntervalCompleted = false
            
            // Отображаем соответствующие кнопки в UI
            updateButtonState()
        } else {
            // Если нет интервала, отмечаем как завершенный сразу
            isIntervalCompleted = true
            updateButtonState()
        }
    }
    
    private func updateIntervalStatus() {
        guard let exercise = currentExercise?.exerciseRef else { return }
        
        // Проверяем только для упражнений с интервалом
        if exercise.hasInterval && exercise.intervalInSeconds > 0 {
            let intervalSeconds = TimeInterval(exercise.intervalInSeconds)
            
            // Обновляем оставшееся время интервала
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
                    // Если это было последнее повторение, позволяем завершить упражнение
                    canCompleteExercise = true
                }
                
                // Обновляем кнопки в UI
                updateButtonState()
            }
        }
    }
    
    // Public method for next repetition
    func advanceToNextRepetition() {
        guard let exercise = currentExercise?.exerciseRef,
              currentRepetitionNumber < exercise.repetitions else { return }
        
        // Call the private implementation instead of recursively calling itself
        performNextRepetitionStep()
    }
    
    // Private implementation with a different name to avoid conflict
    private func performNextRepetitionStep() {
        guard let exercise = currentExercise?.exerciseRef,
              currentRepetitionNumber < exercise.repetitions else { return }
        
        // Создаем запись о текущем отрезке перед переходом
        recordRepetitionCompletion()
        
        // Увеличиваем номер повторения
        currentRepetitionNumber += 1
        isLastRepetition = currentRepetitionNumber >= exercise.repetitions
        
        // Сбрасываем время текущего повторения
        exerciseTime = 0
        currentIntervalTime = 0
        isIntervalCompleted = false
        repetitionStartTime = Date()
        
        // Обновляем данные в UI
        DispatchQueue.main.async {
            if var exerciseData = self.currentExercise {
                exerciseData.currentRepetition = self.currentRepetitionNumber
                exerciseData.currentRepetitionTime = 0
                self.currentExercise = exerciseData
                
                // Сбрасываем флаг завершения упражнения, если это не последнее повторение
                if !self.isLastRepetition {
                    self.canCompleteExercise = false
                }
                
                // Обновляем состояние кнопок
                self.updateButtonState()
                self.objectWillChange.send()
            }
        }
    }
    
    private func recordRepetitionCompletion() {
        guard let exercise = currentExercise else { return }
        
        // Записываем данные о завершенном повторении
        let lapRecord = SwimWorkoutModels.LapData(
            timestamp: repetitionStartTime ?? Date(),
            lapNumber: currentRepetitionNumber,
            exerciseId: exercise.exerciseId,
            distance: exercise.exerciseRef.meters / exercise.exerciseRef.repetitions,
            lapTime: exerciseTime,
            heartRate: exercise.heartRate,
            strokes: exercise.strokeCount
        )
        
        // Добавляем в массив данных об отрезках
        lapData.append(lapRecord)
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
                    // Без интервала - кнопка для перехода к следующему повторению всегда активна
                    self.shouldShowNextRepButton = !self.isLastRepetition
                    self.canCompleteExercise = self.isLastRepetition
                }
            } else {
                // Для одиночных упражнений
                if exercise.hasInterval && exercise.intervalInSeconds > 0 {
                    // С интервалом - можно завершить только когда интервал истек
                    self.shouldShowNextRepButton = false
                    self.canCompleteExercise = self.isIntervalCompleted
                } else {
                    // Без интервала - можно завершить в любой момент
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
        // Обновляем UI с использованием ObservableObject
        DispatchQueue.main.async {
            if var exercise = self.currentExercise {
                exercise.totalSessionTime = self.sessionTime
                self.currentExercise = exercise
                self.objectWillChange.send() // Явно сообщаем об изменении
            }
        }
    }
    
    private func updateExerciseTime() {
        // Обновляем UI с использованием ObservableObject
        DispatchQueue.main.async {
            if var exercise = self.currentExercise {
                exercise.currentRepetitionTime = self.exerciseTime
                self.currentExercise = exercise
                self.objectWillChange.send() // Явно сообщаем об изменении
            }
        }
    }
    
    private func updateHeartRate(_ heartRate: Double) {
        // Обновляем пульс в текущем упражнении
        DispatchQueue.main.async {
            if var exercise = self.currentExercise {
                exercise.heartRate = heartRate
                self.currentExercise = exercise
                
                // Явно сообщаем об изменении
                self.objectWillChange.send()
                
                // Записываем данные о пульсе
                self.recordMetrics()
            }
        }
    }
    
    private func updateStrokeCount(_ strokeCount: Int) {
        // Обновляем количество гребков в текущем упражнении
        DispatchQueue.main.async {
            if var exercise = self.currentExercise {
                exercise.strokeCount = strokeCount
                self.currentExercise = exercise
                
                // Явно сообщаем об изменении
                self.objectWillChange.send()
                
                // Записываем данные о гребках
                self.recordMetrics()
            }
        }
    }
    
    private func recordMetrics() {
        guard let exercise = currentExercise else { return }
        
        // Создаем запись о текущем отрезке
        let lapRecord = SwimWorkoutModels.LapData(
            timestamp: Date(),
            lapNumber: currentRepetitionNumber,
            exerciseId: exercise.exerciseId,
            distance: exercise.exerciseRef.meters / exercise.exerciseRef.repetitions,
            lapTime: exerciseTime,
            heartRate: exercise.heartRate,
            strokes: exercise.strokeCount
        )
        
        // Добавляем в массив данных об отрезках
        lapData.append(lapRecord)
    }
    
    // MARK: - Отправка данных о выполненной тренировке
    private func prepareTransferWorkoutInfo() -> TransferWorkoutModels.TransferWorkoutInfo {
        // Преобразуем все упражнения в TransferExerciseInfo
        let transferExercises = completedExercises.enumerated().map { index, completedExercise -> TransferWorkoutModels.TransferExerciseInfo in
            // Находим оригинальное упражнение для получения полных данных
            let originalExercise = exercises.first { $0.id == completedExercise.exerciseId }!
            
            // Преобразуем отрезки в TransferLapInfo
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
            
            // Создаем TransferExerciseInfo с данными из оригинального упражнения
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
            endTime: Date(),
            totalCalories: healthManager.getWorkoutTotalCalories(),
            exercises: transferExercises
        )
    }
    
    private func sendWorkoutDataToPhone() {
        // Подготавливаем данные о тренировке в формате для передачи
        let transferWorkout = prepareTransferWorkoutInfo()
        
        // Преобразуем в словарь для передачи через WatchConnectivity
        let workoutDict = transferWorkout.toDictionary()
        
        // Отправляем данные на iPhone, используя существующий тип сообщения
        communicationService.sendMessage(
            type: .command, // Используем существующий тип сообщения
            data: ["completedWorkoutData": workoutDict]
        )
        
        // Сбрасываем флаг получения подтверждения
        gotWorkoutDataConfirmation = false
        
        // Пробуем отправить повторно через некоторое время, если не получим подтверждение
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.retryWorkoutDataSending(transferWorkout: transferWorkout)
        }
    }
    
    // Повторная отправка данных, если не получено подтверждение
    private func retryWorkoutDataSending(transferWorkout: TransferWorkoutModels.TransferWorkoutInfo, retryCount: Int = 0) {
        // Максимальное количество повторных попыток
        let maxRetries = 3
        
        // Проверяем, не превышено ли максимальное количество попыток
        if retryCount >= maxRetries {
            return // Превышено максимальное количество попыток
        }
        
        // Проверяем, получено ли подтверждение
        if gotWorkoutDataConfirmation {
            return // Подтверждение получено, больше не отправляем
        }
        
        // Преобразуем в словарь для передачи
        let workoutDict = transferWorkout.toDictionary()
        
        // Отправляем данные на iPhone повторно
        communicationService.sendMessage(
            type: .command, // Используем существующий тип
            data: [
                "completedWorkoutData": workoutDict,
                "retryCount": retryCount + 1
            ]
        )
        
        // Запланируем следующую повторную отправку
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.retryWorkoutDataSending(
                transferWorkout: transferWorkout,
                retryCount: retryCount + 1
            )
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
    
    // Начать выполнение текущего упражнения
    func startCurrentExercise() {
        guard sessionState == .previewingExercise,
              let preview = nextExercisePreview else { return }
        
        print("Starting current exercise")
        
        // Сбрасываем счетчики времени
        exerciseTime = 0  // Reset only exercise time, keep session time running
        
        // Сбрасываем состояние интервала
        isIntervalCompleted = false
        canCompleteExercise = false
        
        // Устанавливаем информацию о повторениях
        currentRepetitionNumber = 1
        
        // Получаем информацию о текущем упражнении
        let exerciseRef = exercises[currentExerciseIndex]
        totalRepetitions = exerciseRef.repetitions
        isLastRepetition = currentRepetitionNumber >= totalRepetitions
        
        // Обновляем состояние кнопок
        updateButtonState()
        
        // Устанавливаем текущее упражнение и сбрасываем превью
        DispatchQueue.main.async {
            self.currentExercise = preview
            self.nextExercisePreview = nil
            self.sessionState = .exerciseActive
            self.objectWillChange.send()
        }
        
        // Сохраняем время начала упражнения и повторения
        exerciseStartTime = Date()
        repetitionStartTime = Date()
        
        // Запускаем таймеры
        self.startTimers()
        
        // Start HealthKit workout if not already started
        if !healthKitWorkoutActive {
            // Запрашиваем разрешения HealthKit перед запуском
            healthManager.requestAuthorization { [weak self] success, error in
                guard let self = self, success else {
                    print("Failed to get HealthKit authorization: \(String(describing: error))")
                    return
                }
                
                DispatchQueue.main.async {
                    print("Starting HealthKit monitoring")
                    // Запускаем HealthKit мониторинг
                    self.healthManager.startWorkout(poolLength: Double(self.workout.poolSize))
                }
            }
        }
        
        // Устанавливаем начальное состояние интервала
        if let exercise = self.currentExercise?.exerciseRef {
            if exercise.hasInterval && exercise.intervalInSeconds > 0 {
                // Если есть интервал, кнопка блокируется до его истечения
                self.isIntervalCompleted = false
                self.canCompleteExercise = false
                self.intervalTimeRemaining = TimeInterval(exercise.intervalInSeconds)
            } else if exercise.repetitions > 1 {
                // Если есть повторения, но нет интервала - кнопка "Next Rep"
                self.shouldShowNextRepButton = true
                self.canCompleteExercise = false
            } else {
                // Если нет ни интервала, ни повторений - кнопка "Complete" активна
                self.canCompleteExercise = true
            }
            
            // Обновляем UI
            self.objectWillChange.send()
        }
    }
    
    // Завершить текущее упражнение и перейти к следующему
    func completeCurrentExercise() {
        guard sessionState == .exerciseActive,
              let currentExercise = currentExercise,
              let exerciseStartTime = exerciseStartTime else { return }
        
        // Проверяем, можем ли мы завершить упражнение
        if !canCompleteExercise {
            // Если не можем завершить, но можем перейти к следующему повторению
            if shouldShowNextRepButton {
                performNextRepetitionStep()
                return
            } else {
                // Если не можем ни завершить, ни перейти к следующему - игнорируем
                return
            }
        }
        
        print("Completing current exercise")
        
        // Записываем последнее повторение, если оно не было записано
        recordRepetitionCompletion()
        
        // Останавливаем таймеры упражнения
        stopExerciseTimer()
        
        // Собираем все записи об отрезках для этого упражнения
        let exerciseLaps = lapData.filter { $0.exerciseId == currentExercise.exerciseId }
        
        // Формируем данные о выполненном упражнении
        let completedExercise = SwimWorkoutModels.CompletedExerciseData(
            exerciseId: currentExercise.exerciseId,
            startTime: exerciseStartTime,
            endTime: Date(),
            laps: exerciseLaps
        )
        
        // Добавляем в список выполненных
        completedExercises.append(completedExercise)
        
        // Определяем, есть ли следующее упражнение
        let nextIndex = currentExerciseIndex + 1
        if nextIndex < exercises.count {
            // Переходим к следующему упражнению
            currentExerciseIndex = nextIndex
            prepareExercisePreview(exercises[nextIndex])
            
            DispatchQueue.main.async {
                self.sessionState = .previewingExercise
                self.objectWillChange.send()
            }
            
            // Сбрасываем состояние
            exerciseTime = 0
            isIntervalCompleted = false
            canCompleteExercise = false
            currentRepetitionNumber = 1
        } else {
            // Это было последнее упражнение, завершаем тренировку
            completeSession()
        }
    }
    
    // Завершить всю тренировку
    func completeSession() {
        print("Completing workout session")
        
        // Останавливаем HealthKit-мониторинг только если он активен
        if healthKitWorkoutActive {
            healthManager.stopWorkout()
            healthKitWorkoutActive = false
        }
        
        // Останавливаем все таймеры
        stopAllTimers()
        
        // Меняем состояние
        DispatchQueue.main.async {
            self.sessionState = .completed
            self.objectWillChange.send()
        }
        
        // Отправляем данные на телефон
        sendWorkoutDataToPhone()
    }
}
