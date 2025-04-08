//
//  CoreDataManager.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 21.01.2025.
//

import Foundation
import CoreData

final class CoreDataManager {
    // MARK: - Singleton
    static let shared = CoreDataManager()
    
    // MARK: - Persistent Container
    let persistentContainer: NSPersistentContainer
    
    // MARK: - Main Context
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Инициализация
    private init() {
        persistentContainer = NSPersistentContainer(name: "CoreData")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unresolved error \(error.localizedDescription)")
            }
            
            if let url = description.url {
                print("Core Data store URL: \(url)")
            }
        }
    }
    
    // MARK: - Сохранение контекста
    @discardableResult
    func saveContext() -> Bool {
        guard context.hasChanges else { return true }
        do {
            try context.save()
            return true
        } catch {
            print("Error saving context: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Workout CRUD
extension CoreDataManager {
    // Создаёт тренировку в CoreData без добавления упражнений
    @discardableResult
    func createWorkout(name: String,
                       poolSize: Int16) -> WorkoutEntity? {
        
        let newWorkout = WorkoutEntity(context: context)
        newWorkout.name = name
        newWorkout.poolSize = poolSize
        
        if saveContext() {
            return newWorkout
        } else {
            context.delete(newWorkout)
            return nil
        }
    }
    
    // Создаёт тренировку и автоматически добавляет к ней массив упражнений.
    @discardableResult
    func createWorkout(name: String,
                       poolSize: Int16,
                       exercises: [Exercise]) -> WorkoutEntity? {
        
        // 1. Сначала создаём саму тренировку
        guard let workoutEntity = createWorkout(name: name, poolSize: poolSize) else {
            return nil
        }
        
        // 2. Для каждого Exercise из массива создаём ExerciseEntity и привязываем к тренировке
        for (index, exercise) in exercises.enumerated() {
            createExercise(
                for: workoutEntity,
                description: exercise.description,
                style: exercise.style.rawValue,
                type: exercise.type.rawValue,
                hasInterval: exercise.hasInterval,
                intervalMinutes: Int16(exercise.intervalMinutes ?? 0),
                intervalSeconds: Int16(exercise.intervalSeconds ?? 0),
                meters: exercise.meters,
                orderIndex: Int16(index),
                repetitions: exercise.repetitions
            )
        }
        
        // 3. Возвращаем созданную тренировку (если нужно, можно сделать повторный saveContext здесь)
        return workoutEntity
    }
    
    func fetchAllWorkouts() -> [WorkoutEntity] {
        let request: NSFetchRequest<WorkoutEntity> = WorkoutEntity.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch workouts: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteWorkout(_ workout: WorkoutEntity) {
        context.delete(workout)
        _ = saveContext()
    }
}

// MARK: - Exercise CRUD
extension CoreDataManager {
    @discardableResult
    func createExercise(for workout: WorkoutEntity,
                        description: String?,
                        style: Int16,
                        type: Int16,
                        hasInterval: Bool,
                        intervalMinutes: Int16,
                        intervalSeconds: Int16,
                        meters: Int16,
                        orderIndex: Int16,
                        repetitions: Int16) -> ExerciseEntity? {
        
        let exerciseEntity = ExerciseEntity(context: context)
        exerciseEntity.exerciseDescription = description
        exerciseEntity.style = style
        exerciseEntity.type = type
        exerciseEntity.hasInterval = hasInterval
        exerciseEntity.intervalMinutes = intervalMinutes
        exerciseEntity.intervalSeconds = intervalSeconds
        exerciseEntity.meters = meters
        exerciseEntity.orderIndex = orderIndex
        exerciseEntity.repetitions = repetitions
        
        // Привязываем к тренировке
        exerciseEntity.workout = workout
        
        if saveContext() {
            return exerciseEntity
        } else {
            context.delete(exerciseEntity)
            return nil
        }
    }
    
    func fetchAllExercises() -> [ExerciseEntity] {
        let request: NSFetchRequest<ExerciseEntity> = ExerciseEntity.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch exercises: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteExercise(_ exercise: ExerciseEntity) {
        context.delete(exercise)
        _ = saveContext()
    }
}

// MARK: - Start CRUD
extension CoreDataManager {
    // Создаёт новый старт в CoreData без добавления отрезков
    @discardableResult
    func createStart(poolSize: Int16, totalMeters: Int16, swimmingStyle: Int16, date: Date = Date()) -> StartEntity? {
        let startEntity = StartEntity(context: context)
        startEntity.poolSize = poolSize
        startEntity.totalMeters = totalMeters
        startEntity.swimmingStyle = swimmingStyle
        startEntity.date = date
        startEntity.totalTime = 0 // Начальное значение общего времени
        
        if saveContext() {
            return startEntity
        } else {
            context.delete(startEntity)
            return nil
        }
    }
    
    @discardableResult
    func createStart(poolSize: Int16, totalMeters: Int16, swimmingStyle: Int16, laps: [LapData], date: Date = Date()) -> StartEntity? {
        // 1. Создаём сам StartEntity
        guard let startEntity = createStart(poolSize: poolSize, totalMeters: totalMeters, swimmingStyle: swimmingStyle, date: date) else {
            return nil
        }
        
        // 2. Для каждого отрезка из массива создаём LapEntity и привязываем его к старту
        for (index, lap) in laps.enumerated() {
            _ = createLap(lapTime: lap.lapTime,
                          pulse: lap.pulse,
                          strokes: lap.strokes,
                          lapNumber: Int16(index + 1),
                          startEntity: startEntity)
        }
        
        return startEntity
    }
    
    // Получает все старты из CoreData
    func fetchAllStarts() -> [StartEntity] {
        let request: NSFetchRequest<StartEntity> = StartEntity.fetchRequest()
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch starts: \(error.localizedDescription)")
            return []
        }
    }
    
    func fetchStartsWithCriteria(totalMeters: Int16, swimmingStyle: Int16, poolSize: Int16) -> [StartEntity] {
        let request: NSFetchRequest<StartEntity> = StartEntity.fetchRequest()
        
        // Set up the predicates to match our criteria
        let predicate = NSPredicate(format: "totalMeters == %d AND swimmingStyle == %d AND poolSize == %d",
                                    totalMeters, swimmingStyle, poolSize)
        request.predicate = predicate
        
        // Sort by time (ascending = fastest first)
        let sortDescriptor = NSSortDescriptor(key: "totalTime", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching starts with criteria: \(error)")
            return []
        }
    }
    
    // Получает старт по идентификатору
    func fetchStart(byID id: NSManagedObjectID) -> StartEntity? {
        do {
            return try context.existingObject(with: id) as? StartEntity
        } catch {
            print("Failed to fetch start by ID: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Удаляет старт из CoreData
    func deleteStart(_ start: StartEntity) {
        context.delete(start)
        _ = saveContext()
    }
    
    // Обновляет общее время старта
    func updateStartTotalTime(_ start: StartEntity, totalTime: Double) {
        start.totalTime = totalTime
        _ = saveContext()
    }
    
    func updateStartRecommendation(_ start: StartEntity, recommendation: String) {
        start.recommendation = recommendation
        _ = saveContext()
    }
    
    func startHasRecommendation(_ start: StartEntity) -> Bool {
        return start.recommendation != nil && !start.recommendation!.isEmpty
    }
}


// MARK: - Lap CRUD
extension CoreDataManager {
    @discardableResult
    func createLap(lapTime: Double, pulse: Int16, strokes: Int16, lapNumber: Int16, startEntity: StartEntity) -> LapEntity? {
        let lapEntity = LapEntity(context: context)
        lapEntity.lapTime = lapTime
        lapEntity.pulse = pulse
        lapEntity.strokes = strokes
        lapEntity.lapNumber = lapNumber
        
        // Устанавливаем связь с StartEntity; обратное отношение обновится автоматически.
        lapEntity.start = startEntity
        
        if saveContext() {
            return lapEntity
        } else {
            context.delete(lapEntity)
            return nil
        }
    }
    
    // Получает все отрезки для определённого старта
    func fetchLaps(for start: StartEntity) -> [LapEntity] {
        let request: NSFetchRequest<LapEntity> = LapEntity.fetchRequest()
        request.predicate = NSPredicate(format: "start == %@", start)
        request.sortDescriptors = [NSSortDescriptor(key: "lapNumber", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch laps: \(error.localizedDescription)")
            return []
        }
    }
    
    // Удаляет отрезок
    func deleteLap(_ lap: LapEntity) {
        if let start = lap.start {
            start.removeFromLaps(lap)
        }
        context.delete(lap)
        _ = saveContext()
    }
}

// MARK: - WorkoutSession CRUD
extension CoreDataManager {
    // Создаёт запись о завершённой тренировке со всеми связанными данными
    @discardableResult
    func createWorkoutSession(
        date: Date,
        totalTime: Double,
        totalCalories: Double,
        poolSize: Int16,
        workoutOriginalId: String,
        workoutName: String,
        exercisesData: [CompletedExerciseData]
    ) -> WorkoutSessionEntity? {
        
        // Создаём основную запись о тренировке
        let workoutSession = WorkoutSessionEntity(context: context)
        workoutSession.id = UUID()
        workoutSession.date = date
        workoutSession.totalTime = totalTime
        workoutSession.totalCalories = totalCalories
        workoutSession.poolSize = poolSize
        workoutSession.workoutOriginalId = workoutOriginalId
        workoutSession.workoutName = workoutName
        
        // Создаём и добавляем упражнения
        for exerciseData in exercisesData {
            let exerciseSession = createExerciseSession(
                for: workoutSession,
                exerciseData: exerciseData
            )
            
            // Добавляем данные о пульсе, если они есть
            if let exerciseSession = exerciseSession,
               !exerciseData.heartRateReadings.isEmpty {
                addHeartRateReadings(
                    readings: exerciseData.heartRateReadings,
                    exerciseSession: exerciseSession
                )
            }
        }
        
        if saveContext() {
            return workoutSession
        } else {
            context.delete(workoutSession)
            return nil
        }
    }
    
    // Создаёт запись об упражнении с данными об отрезках
    @discardableResult
    private func createExerciseSession(
        for workoutSession: WorkoutSessionEntity,
        exerciseData: CompletedExerciseData
    ) -> ExerciseSessionEntity? {
        
        let exerciseSession = ExerciseSessionEntity(context: context)
        exerciseSession.id = UUID()
        exerciseSession.startTime = exerciseData.startTime
        exerciseSession.endTime = exerciseData.endTime
        exerciseSession.orderIndex = Int16(exerciseData.orderIndex)
        
        // Сохраняем свойства упражнения (снимок)
        exerciseSession.exerciseOriginalId = exerciseData.exerciseId
        exerciseSession.exerciseDescription = exerciseData.description
        exerciseSession.style = Int16(exerciseData.style)
        exerciseSession.type = Int16(exerciseData.type)
        exerciseSession.hasInterval = exerciseData.hasInterval
        exerciseSession.intervalMinutes = Int16(exerciseData.intervalMinutes)
        exerciseSession.intervalSeconds = Int16(exerciseData.intervalSeconds)
        exerciseSession.meters = Int16(exerciseData.meters)
        exerciseSession.repetitions = Int16(exerciseData.repetitions)
        
        // Устанавливаем связь с тренировкой
        exerciseSession.workoutSession = workoutSession
        
        // Создаём отрезки для этого упражнения
        for lapData in exerciseData.laps {
            createLapSessionForExercise(
                exerciseSession: exerciseSession,
                lapData: lapData
            )
        }
        
        return exerciseSession
    }
    
    // Создаёт запись об отрезке для упражнения
    @discardableResult
    private func createLapSessionForExercise(
        exerciseSession: ExerciseSessionEntity,
        lapData: CompletedLapData
    ) -> LapSessionEntity? {
        
        let lap = LapSessionEntity(context: context)
        lap.id = UUID()
        lap.lapNumber = Int16(lapData.lapNumber)
        lap.distance = Int16(lapData.distance)
        lap.lapTime = lapData.lapTime
        lap.heartRate = lapData.heartRate
        lap.strokes = Int16(lapData.strokes)
        lap.timestamp = lapData.timestamp
        
        // Устанавливаем связь с упражнением
        lap.exerciseSession = exerciseSession
        
        return lap
    }
    
    // Получает все записи о тренировках
    func fetchAllWorkoutSessions() -> [WorkoutSessionEntity] {
        let request: NSFetchRequest<WorkoutSessionEntity> = WorkoutSessionEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch workout sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    // Получает запись о тренировке по ID
    func fetchWorkoutSession(byID id: UUID) -> WorkoutSessionEntity? {
        let request: NSFetchRequest<WorkoutSessionEntity> = WorkoutSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            return results.first
        } catch {
            print("Failed to fetch workout session by ID: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Удаляет запись о тренировке
    func deleteWorkoutSession(_ workoutSession: WorkoutSessionEntity) {
        context.delete(workoutSession)
        _ = saveContext()
    }
    
    // Получает все упражнения для записи о тренировке
    func fetchExerciseSessions(for workoutSession: WorkoutSessionEntity) -> [ExerciseSessionEntity] {
        let request: NSFetchRequest<ExerciseSessionEntity> = ExerciseSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "workoutSession == %@", workoutSession)
        request.sortDescriptors = [NSSortDescriptor(key: "orderIndex", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch exercise sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    // Получает все отрезки для упражнения
    func fetchLapSessions(for exerciseSession: ExerciseSessionEntity) -> [LapSessionEntity] {
        let request: NSFetchRequest<LapSessionEntity> = LapSessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "exerciseSession == %@", exerciseSession)
        request.sortDescriptors = [NSSortDescriptor(key: "lapNumber", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch lap sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    // Получает статистику по тренировкам (количество, общее время, калории)
    func getWorkoutSessionsStats() -> (count: Int, totalTime: Double, totalCalories: Double) {
        let sessions = fetchAllWorkoutSessions()
        let count = sessions.count
        let totalTime = sessions.reduce(0) { $0 + $1.totalTime }
        let totalCalories = sessions.reduce(0) { $0 + $1.totalCalories }
        
        return (count, totalTime, totalCalories)
    }
    
    func updateWorkoutSessionRecommendation(_ workoutSession: WorkoutSessionEntity, recommendation: String) {
        workoutSession.recommendation = recommendation
        _ = saveContext()
    }
    
    func workoutSessionHasRecommendation(_ workoutSession: WorkoutSessionEntity) -> Bool {
        return workoutSession.recommendation != nil && !workoutSession.recommendation!.isEmpty
    }
}

// MARK: - HeartRate CRUD
extension CoreDataManager {
    @discardableResult
    func createHeartRateReading(
        value: Double,
        timestamp: Date,
        exerciseSession: ExerciseSessionEntity
    ) -> HeartRateEntity {
        let heartRate = HeartRateEntity(context: context)
        heartRate.id = UUID()
        heartRate.value = value
        heartRate.timestamp = timestamp
        heartRate.exerciseSession = exerciseSession
        exerciseSession.addToHeartRateReadings(heartRate)
        
        saveContext()
        return heartRate
    }
    
    func addHeartRateReadings(
        readings: [(value: Double, timestamp: Date)],
        exerciseSession: ExerciseSessionEntity
    ) {
        for reading in readings {
            createHeartRateReading(
                value: reading.value,
                timestamp: reading.timestamp,
                exerciseSession: exerciseSession
            )
        }
    }
    
    func fetchHeartRateReadings(for exerciseSession: ExerciseSessionEntity) -> [HeartRateEntity] {
        let request: NSFetchRequest<HeartRateEntity> = HeartRateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "exerciseSession == %@", exerciseSession)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch heart rate readings: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteHeartRateReadings(for exerciseSession: ExerciseSessionEntity) {
        guard let heartRates = exerciseSession.heartRateReadings as? Set<HeartRateEntity> else {
            return
        }
        
        for heartRate in heartRates {
            context.delete(heartRate)
        }
        
        saveContext()
    }
}
