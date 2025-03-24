//
//  WorkoutSessionService.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 24.03.2025.
//

import Foundation
import Combine

final class WorkoutSessionService: ObservableObject {
    // MARK: - Published Properties
    @Published var sessionState: SwimWorkoutModels.WorkoutSessionState = .notStarted
    @Published var currentExercise: SwimWorkoutModels.ActiveExerciseData?
    @Published var nextExercisePreview: SwimWorkoutModels.ActiveExerciseData?
    @Published var completedExercises: [SwimWorkoutModels.CompletedExerciseData] = []
    
    // MARK: - Public Properties
    let workout: SwimWorkoutModels.SwimWorkout
    
    // MARK: - Private Properties
    private let healthManager: HealthKitManager
    private let communicationService: WatchCommunicationService
    
    private var exercises: [SwimWorkoutModels.SwimExercise] = []
    private var currentExerciseIndex: Int = 0
    private var sessionStartTime: Date?
    private var exerciseStartTime: Date?
    private var lapData: [SwimWorkoutModels.LapData] = []
    private var cancellables = Set<AnyCancellable>()
    
    private var sessionTimer: Timer?
    private var exerciseTimer: Timer?
    
    private var sessionTime: TimeInterval = 0
    private var exerciseTime: TimeInterval = 0
    
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
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Подписываемся на обновления пульса
        healthManager.heartRatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] heartRate in
                self?.updateHeartRate(heartRate)
            }
            .store(in: &cancellables)
        
        // Подписываемся на обновления гребков
        healthManager.strokeCountPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] strokeCount in
                self?.updateStrokeCount(strokeCount)
            }
            .store(in: &cancellables)
    }
    
    private func prepareExercisePreview(_ exercise: SwimWorkoutModels.SwimExercise) {
        // Создаем превью упражнения
        nextExercisePreview = SwimWorkoutModels.ActiveExerciseData(
            from: exercise,
            index: currentExerciseIndex + 1,
            totalExercises: exercises.count
        )
    }
    
    private func startTimers() {
        // Запускаем таймер сессии, если еще не запущен
        if sessionTimer == nil {
            sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateSessionTime()
            }
        }
        
        // Запускаем таймер упражнения
        exerciseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateExerciseTime()
        }
    }
    
    private func stopExerciseTimer() {
        exerciseTimer?.invalidate()
        exerciseTimer = nil
    }
    
    private func stopAllTimers() {
        sessionTimer?.invalidate()
        sessionTimer = nil
        stopExerciseTimer()
    }
    
    private func updateSessionTime() {
        guard let startTime = sessionStartTime else { return }
        sessionTime = Date().timeIntervalSince(startTime)
        
        // Обновляем время в модели текущего упражнения
        if var exercise = currentExercise {
            exercise.totalSessionTime = sessionTime
            currentExercise = exercise
        }
    }
    
    private func updateExerciseTime() {
        exerciseTime += 1.0
        
        // Обновляем время в модели текущего упражнения
        if var exercise = currentExercise {
            exercise.currentRepetitionTime = exerciseTime
            currentExercise = exercise
        }
    }
    
    private func updateHeartRate(_ heartRate: Double) {
        // Обновляем пульс в текущем упражнении
        if var exercise = currentExercise {
            exercise.heartRate = heartRate
            currentExercise = exercise
            
            // Записываем данные о пульсе
            recordMetrics()
        }
    }
    
    private func updateStrokeCount(_ strokeCount: Int) {
        // Обновляем количество гребков в текущем упражнении
        if var exercise = currentExercise {
            exercise.strokeCount = strokeCount
            currentExercise = exercise
            
            // Записываем данные о гребках
            recordMetrics()
        }
    }
    
    private func recordMetrics() {
        guard let exercise = currentExercise else { return }
        
        // Создаем запись о текущем отрезке
        let lapRecord = SwimWorkoutModels.LapData(
            timestamp: Date(),
            lapNumber: exercise.currentRepetition,
            exerciseId: exercise.exerciseId,
            distance: exercise.exerciseRef.meters / exercise.exerciseRef.repetitions,
            lapTime: exercise.currentRepetitionTime,
            heartRate: exercise.heartRate,
            strokes: exercise.strokeCount
        )
        
        // Добавляем в массив данных об отрезках
        lapData.append(lapRecord)
    }
    
    private func sendWorkoutDataToPhone() {
        // TBA
    }
    
    // MARK: - Public Methods
    func startSession() {
        guard sessionState == .notStarted else { return }
        
        sessionStartTime = Date()
        
        // Показываем превью первого упражнения
        if !exercises.isEmpty {
            currentExerciseIndex = 0
            prepareExercisePreview(exercises[currentExerciseIndex])
            sessionState = .previewingExercise
        } else {
            // Если нет упражнений, завершаем тренировку
            completeSession()
        }
    }
    
    // Начать выполнение текущего упражнения
    func startCurrentExercise() {
        guard sessionState == .previewingExercise,
              let preview = nextExercisePreview else { return }
        
        // Устанавливаем текущее упражнение и сбрасываем превью
        currentExercise = preview
        nextExercisePreview = nil
        
        // Запускаем HealthKit мониторинг
        healthManager.startWorkout(poolLength: Double(workout.poolSize))
        
        // Запускаем таймеры
        startTimers()
        
        // Сохраняем время начала упражнения
        exerciseStartTime = Date()
        
        // Обновляем состояние
        sessionState = .exerciseActive
    }
    
    // Завершить текущее упражнение и перейти к следующему
    func completeCurrentExercise() {
        guard sessionState == .exerciseActive,
              let currentExercise = currentExercise,
              let exerciseStartTime = exerciseStartTime else { return }
        
        // Останавливаем таймеры упражнения
        stopExerciseTimer()
        
        // Формируем данные о выполненном упражнении
        let completedExercise = SwimWorkoutModels.CompletedExerciseData(
            exerciseId: currentExercise.exerciseId,
            startTime: exerciseStartTime,
            endTime: Date(),
            laps: lapData.filter { $0.exerciseId == currentExercise.exerciseId }
        )
        
        // Добавляем в список выполненных
        completedExercises.append(completedExercise)
        
        // Определяем, есть ли следующее упражнение
        let nextIndex = currentExerciseIndex + 1
        if nextIndex < exercises.count {
            // Переходим к следующему упражнению
            currentExerciseIndex = nextIndex
            prepareExercisePreview(exercises[nextIndex])
            sessionState = .previewingExercise
            
            // Сбрасываем время упражнения
            exerciseTime = 0
        } else {
            // Это было последнее упражнение, завершаем тренировку
            completeSession()
        }
    }
    
    // Завершить всю тренировку
    func completeSession() {
        // Останавливаем HealthKit-мониторинг
        healthManager.stopWorkout()
        
        // Останавливаем все таймеры
        stopAllTimers()
        
        // Меняем состояние
        sessionState = .completed
        
        // Отправляем данные на телефон (в будущем)
        sendWorkoutDataToPhone()
    }
}
