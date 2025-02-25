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
    // Создаёт новый старт в CoreData
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
    
    // Получить старт по идентификатору
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
    
    // Обновить общее время старта
    func updateStartTotalTime(_ start: StartEntity, totalTime: Double) {
        start.totalTime = totalTime
        _ = saveContext()
    }
}

// MARK: - Lap CRUD
extension CoreDataManager {
    // Создаёт новый отрезок в CoreData
    @discardableResult
    func createLap(lapTime: Double, pulse: Int16, strokes: Int16, lapNumber: Int16, startEntity: StartEntity) -> LapEntity? {
        let lapEntity = LapEntity(context: context)
        lapEntity.lapTime = lapTime
        lapEntity.pulse = pulse
        lapEntity.strokes = strokes
        lapEntity.lapNumber = lapNumber
        lapEntity.start = startEntity // Привязываем к старту
        
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
    
    // Обновить данные отрезка
    func updateLapData(lap: LapEntity, lapTime: Double, pulse: Int16, strokes: Int16) {
        lap.lapTime = lapTime
        lap.pulse = pulse
        lap.strokes = strokes
        _ = saveContext()
    }
}
