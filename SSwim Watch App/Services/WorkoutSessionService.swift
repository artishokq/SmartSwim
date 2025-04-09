//
//  WorkoutSessionService.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 23.03.2025.
//

import Foundation
import Combine

class WorkoutSessionService: ObservableObject {
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
    let workoutKitManager: WorkoutKitManager
    private let communicationService: WatchCommunicationService
    
    private var exercises: [SwimWorkoutModels.SwimExercise] = []
    private var currentExerciseIndex: Int = 0
    private var sessionStartTime: Date?
    private var exerciseStartTime: Date?
    private var repetitionStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    private var sessionTimer: Timer?
    private var exerciseTimer: Timer?
    private var intervalTimer: Timer?
    private var manualRefreshTimer: Timer?
    
    private var sessionTime: TimeInterval = 0
    private var exerciseTime: TimeInterval = 0
    
    private var workoutActive = false
    
    private struct ExerciseTimeData {
        let exerciseId: String
        let orderIndex: Int
        let startTime: Date
        let endTime: Date?
    }
    
    private var exerciseTimestamps: [ExerciseTimeData] = []
    
    private var gotWorkoutDataConfirmation = false
    private var subscriptionId: UUID?
    private var isCompletingSession = false
    
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
        
        stopAllTimers()
        manualRefreshTimer?.invalidate()
        
        if workoutActive {
            workoutKitManager.stopWorkout()
        }
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        workoutKitManager.heartRatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] heartRate in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if var exercise = self.currentExercise {
                        exercise.heartRate = heartRate
                        self.currentExercise = exercise
                        self.objectWillChange.send()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Подписываемся на обновления гребков для отображения в UI
        workoutKitManager.strokeCountPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] strokeCount in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if var exercise = self.currentExercise {
                        exercise.strokeCount = strokeCount
                        self.currentExercise = exercise
                        self.objectWillChange.send()
                    }
                }
            }
            .store(in: &cancellables)
        
        // Подписываемся на обновления калорий для отображения в UI
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
        
        subscriptionId = communicationService.subscribe(to: .command) { [weak self] message in
            if let confirmation = message["workoutDataReceived"] as? Bool, confirmation {
                self?.gotWorkoutDataConfirmation = true
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
    
    func stopAllTimers() {
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
    
    private func startManualRefreshTimer() {
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
    
    // MARK: - Отправка данных о тренировке на iPhone
    private func sendWorkoutCompletionToIPhone(sessionEndTime: Date) {
        print("Подготовка данных о тренировке для отправки на iPhone")
        print("Вызов sendWorkoutCompletionToIPhone, isReachable: \(communicationService.isReachable)")
        
        let startTimeInterval = (sessionStartTime ?? Date()).timeIntervalSince1970
        let endTimeInterval = sessionEndTime.timeIntervalSince1970
        
        let workoutMetadata: [String: Any] = [
            "workoutId": workout.id,
            "workoutName": workout.name,
            "poolSize": workout.poolSize,
            "startTime": startTimeInterval,
            "endTime": endTimeInterval,
            "exercises": exercises.map { exercise -> [String: Any] in
                let exerciseTimestamp = self.exerciseTimestamps.first { $0.exerciseId == exercise.id }
                let precisStartTime = exerciseTimestamp?.startTime.timeIntervalSince1970 ?? startTimeInterval
                let precisEndTime = exerciseTimestamp?.endTime?.timeIntervalSince1970 ?? endTimeInterval
                
                return [
                    "exerciseId": exercise.id,
                    "description": exercise.description ?? "",
                    "style": exercise.style,
                    "type": exercise.type,
                    "hasInterval": exercise.hasInterval,
                    "intervalMinutes": exercise.intervalMinutes,
                    "intervalSeconds": exercise.intervalSeconds,
                    "meters": exercise.meters,
                    "repetitions": exercise.repetitions,
                    "orderIndex": exercise.orderIndex,
                    "preciseStartTime": precisStartTime,
                    "preciseEndTime": precisEndTime
                ]
            }
        ]
        
        let sendId = UUID().uuidString
        
        saveWorkoutDataLocally(metadata: [
            "workoutMetadata": workoutMetadata,
            "sendId": sendId
        ])
        
        let isReachable = communicationService.isReachable
        print("Отправляем данные тренировки, isReachable: \(isReachable)")
        
        if isReachable {
            communicationService.sendMessageWithReply(
                type: .command,
                data: [
                    "workoutCompleted": true,
                    "workoutMetadata": workoutMetadata,
                    "sendId": sendId
                ],
                timeout: 5.0
            ) { [weak self] response in
                guard let self = self else { return }
                if let confirmed = response?["workoutDataReceived"] as? Bool, confirmed {
                    print("Получено подтверждение от iPhone о получении данных тренировки")
                    self.gotWorkoutDataConfirmation = true
                    self.removeLocalWorkoutData(sendId: sendId)
                } else {
                    print("Подтверждение не получено, повторная попытка отправки данных")
                    self.retrySendOnce(metadata: workoutMetadata, sendId: sendId)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
                guard let self = self else { return }
                if !self.gotWorkoutDataConfirmation {
                    print("Подтверждение не получено после 6 секунд, повторная отправка данных")
                    self.retrySendOnce(metadata: workoutMetadata, sendId: sendId)
                }
            }
        } else {
            print("iPhone недоступен, данные сохранены локально. Запускаем фоновую синхронизацию.")
            scheduleBackgroundDataSync()
        }
    }
    
    private func saveWorkoutDataLocally(metadata: [String: Any]) {
        do {
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            let fileURL = documentsDirectory.appendingPathComponent("pending_workouts.json")
            
            var pendingWorkouts: [[String: Any]] = []
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    let savedData = try Data(contentsOf: fileURL)
                    if let savedWorkouts = try JSONSerialization.jsonObject(with: savedData) as? [[String: Any]] {
                        pendingWorkouts = savedWorkouts
                    }
                } catch {
                    print("Ошибка при чтении сохраненных данных: \(error)")
                }
            }
            
            pendingWorkouts.append(metadata)
            let updatedData = try JSONSerialization.data(withJSONObject: pendingWorkouts)
            try updatedData.write(to: fileURL)
            print("Данные о тренировке сохранены локально")
        } catch {
            print("Ошибка при сохранении данных тренировки: \(error)")
        }
    }
    
    private func removeLocalWorkoutData(sendId: String) {
        do {
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            let fileURL = documentsDirectory.appendingPathComponent("pending_workouts.json")
            
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return
            }
            
            let savedData = try Data(contentsOf: fileURL)
            guard var savedWorkouts = try JSONSerialization.jsonObject(with: savedData) as? [[String: Any]] else {
                return
            }
            
            savedWorkouts.removeAll { workout in
                return (workout["sendId"] as? String) == sendId
            }
            
            let updatedData = try JSONSerialization.data(withJSONObject: savedWorkouts)
            try updatedData.write(to: fileURL)
            print("Локально сохраненные данные удалены после успешной отправки")
        } catch {
            print("Ошибка при удалении данных тренировки: \(error)")
        }
    }
    
    private func scheduleBackgroundDataSync() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            if self.communicationService.isReachable {
                self.checkAndSendPendingWorkouts()
            } else {
                print("Фоновая синхронизация: iPhone все еще недоступен")
            }
        }
    }
    
    private func checkAndSendPendingWorkouts() {
        guard communicationService.isReachable else {
            print("iPhone все еще недоступен, отложенная синхронизация ожидает")
            return
        }
        
        do {
            let fileManager = FileManager.default
            guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                return
            }
            
            let fileURL = documentsDirectory.appendingPathComponent("pending_workouts.json")
            
            guard fileManager.fileExists(atPath: fileURL.path) else {
                return
            }
            
            let savedData = try Data(contentsOf: fileURL)
            guard let savedWorkouts = try JSONSerialization.jsonObject(with: savedData) as? [[String: Any]], !savedWorkouts.isEmpty else {
                return
            }
            
            print("Найдено \(savedWorkouts.count) ожидающих отправки тренировок")
            
            for workoutData in savedWorkouts {
                if let metadata = workoutData["workoutMetadata"] as? [String: Any],
                   let sendId = workoutData["sendId"] as? String {
                    
                    communicationService.sendMessageWithReply(
                        type: .command,
                        data: [
                            "workoutCompleted": true,
                            "workoutMetadata": metadata,
                            "sendId": sendId
                        ],
                        timeout: 5.0
                    ) { [weak self] response in
                        if let confirmed = response?["workoutDataReceived"] as? Bool, confirmed {
                            print("Получено подтверждение от iPhone о получении отложенных данных тренировки")
                            self?.removeLocalWorkoutData(sendId: sendId)
                        }
                    }
                }
            }
        } catch {
            print("Ошибка при проверке и отправке ожидающих данных: \(error)")
        }
    }
    
    private func retrySendOnce(metadata: [String: Any], sendId: String) {
        guard !gotWorkoutDataConfirmation else { return }
        
        print("Повторная отправка данных тренировки с sendId: \(sendId)")
        communicationService.sendMessageWithReply(
            type: .command,
            data: [
                "workoutCompleted": true,
                "workoutMetadata": metadata,
                "sendId": sendId
            ],
            timeout: 5.0
        ) { [weak self] response in
            guard let self = self else { return }
            if let confirmed = response?["workoutDataReceived"] as? Bool, confirmed {
                print("Подтверждение получено при повторной отправке данных тренировки")
                self.gotWorkoutDataConfirmation = true
                self.removeLocalWorkoutData(sendId: sendId)
            } else {
                print("Повторная отправка не удалась, ожидаем следующую попытку фоновой синхронизации")
            }
        }
    }
    
    // MARK: - Public Methods
    func startSession() {
        guard sessionState == .notStarted else { return }
        
        print("Starting workout session")
        sessionStartTime = Date()
        
        currentCalories = 0
        exerciseTimestamps = []
        
        if !exercises.isEmpty {
            currentExerciseIndex = 0
            prepareExercisePreview(exercises[currentExerciseIndex])
            
            DispatchQueue.main.async {
                self.sessionState = .previewingExercise
                self.objectWillChange.send()
            }
        } else {
            completeSession(completion: {})
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
        
        updateButtonState()
        
        DispatchQueue.main.async {
            self.currentExercise = preview
            self.nextExercisePreview = nil
            self.sessionState = .exerciseActive
            self.objectWillChange.send()
        }
        
        let now = Date()
        exerciseStartTime = now
        repetitionStartTime = now
        exerciseTimestamps.append(ExerciseTimeData(
            exerciseId: exerciseRef.id,
            orderIndex: Int(exerciseRef.orderIndex),
            startTime: now,
            endTime: nil
        ))
        
        print("Зафиксировано начало упражнения \(exerciseRef.id) в \(now)")
        
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
        guard sessionState == .exerciseActive, let currentExercise = currentExercise else { return }
        
        if !canCompleteExercise {
            if shouldShowNextRepButton {
                performNextRepetitionStep()
                return
            } else {
                return
            }
        }
        
        print("Completing current exercise")
        
        let exerciseEndTime = Date()
        if let index = exerciseTimestamps.firstIndex(where: { $0.exerciseId == currentExercise.exerciseId }) {
            let updatedData = ExerciseTimeData(
                exerciseId: exerciseTimestamps[index].exerciseId,
                orderIndex: exerciseTimestamps[index].orderIndex,
                startTime: exerciseTimestamps[index].startTime,
                endTime: exerciseEndTime
            )
            
            exerciseTimestamps[index] = updatedData
            print("Зафиксировано окончание упражнения \(currentExercise.exerciseId) в \(exerciseEndTime)")
            print("Продолжительность упражнения: \(exerciseEndTime.timeIntervalSince(updatedData.startTime)) сек")
        }
        
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
            completeSession(completion: {})
        }
    }
    
    func completeSession(completion: @escaping () -> Void) {
        print("completeSession вызван")
        if isCompletingSession {
            print("completeSession: Сессия уже завершается, выход")
            DispatchQueue.main.async {
                completion()
            }
            return
        }
        
        isCompletingSession = true
        let sessionEndTime = Date()
        
        for (index, timeData) in exerciseTimestamps.enumerated() {
            if timeData.endTime == nil {
                let updatedData = ExerciseTimeData(
                    exerciseId: timeData.exerciseId,
                    orderIndex: timeData.orderIndex,
                    startTime: timeData.startTime,
                    endTime: sessionEndTime
                )
                exerciseTimestamps[index] = updatedData
                print("Автоматически завершено упражнение \(timeData.exerciseId) при завершении сессии")
            }
        }
        
        DispatchQueue.main.async {
            self.sessionState = .completed
            self.objectWillChange.send()
        }
        
        stopAllTimers()
        let wasWorkoutActive = workoutActive
        print("wasWorkoutActive в момент завершения сессии: \(wasWorkoutActive)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            print("Начинаем завершение тренировки. Текущее workoutActive: \(self.workoutActive)")
            
            if wasWorkoutActive {
                print("Останавливаем тренировку в HealthKit")
                self.workoutKitManager.stopWorkout()
                self.workoutActive = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
                    guard let self = self else {
                        DispatchQueue.main.async {
                            completion()
                        }
                        return
                    }
                    self.sendWorkoutCompletionToIPhone(sessionEndTime: sessionEndTime)
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            } else {
                print("Тренировка уже остановлена, немедленно отправляем данные на iPhone")
                self.sendWorkoutCompletionToIPhone(sessionEndTime: sessionEndTime)
                DispatchQueue.main.async {
                    completion()
                }
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
