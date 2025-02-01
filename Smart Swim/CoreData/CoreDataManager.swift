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
        persistentContainer = NSPersistentContainer(name: "WorkoutCoreData")
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
