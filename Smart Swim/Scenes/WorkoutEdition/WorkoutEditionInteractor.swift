//
//  WorkoutEditionInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 28.02.2025.
//

import UIKit

protocol WorkoutEditionBusinessLogic {
    func loadWorkout(request: WorkoutEditionModels.LoadWorkout.Request)
    func updateWorkout(request: WorkoutEditionModels.UpdateWorkout.Request)
    func addExercise(request: WorkoutEditionModels.AddExercise.Request)
    func deleteExercise(request: WorkoutEditionModels.DeleteExercise.Request)
    func updateExercise(request: WorkoutEditionModels.UpdateExercise.Request)
}

protocol WorkoutEditionDataStore {
    var workoutIndex: Int? { get set }
    var workouts: [WorkoutEntity]? { get set }
    var exercises: [Exercise] { get set }
}

final class WorkoutEditionInteractor: WorkoutEditionBusinessLogic, WorkoutEditionDataStore {
    // MARK: - Constants
    private enum Constants {
        static let nameErrorMessage: String = "Название тренировки не может быть пустым или состоять только из пробелов."
        static let nameErrorMessageLength: String = "Название тренировки не может превышать 30 символов."
        static let poolSizeErrorMessage: String = "Размер бассейна может быть только 25 или 50 метров."
        static let exercizeEmptyMessage: String = "Добавьте хотя бы одно упражнение."
        static let metersErrorMessage: String = "Количество метров должно быть больше 0."
        static let repetitionsErrorMessage: String = "Количество повторений должно быть больше 0."
        static let minsAndSecondsEmptyMessage: String = "Укажите минуты и секунды для интервала."
        static let minsAndSecondsErrorMessage: String = "Минуты и секунды интервала должны быть неотрицательными."
        static let workoutSavingErrorMessage: String = "Не удалось сохранить тренировку."
    }
    
    // MARK: - Fields
    var presenter: WorkoutEditionPresentationLogic?
    var workoutIndex: Int?
    var workouts: [WorkoutEntity]?
    var exercises: [Exercise] = []
    
    // MARK: - Load Workout
    func loadWorkout(request: WorkoutEditionModels.LoadWorkout.Request) {
        self.workoutIndex = request.workoutIndex
        
        // Загружаем тренировки, если они еще не загружены
        if workouts == nil {
            workouts = CoreDataManager.shared.fetchAllWorkouts()
        }
        
        guard let workouts = workouts,
              request.workoutIndex < workouts.count else {
            return
        }
        
        let workoutEntity = workouts[request.workoutIndex]
        let name = workoutEntity.name ?? ""
        let poolSize = PoolSize(rawValue: workoutEntity.poolSize) ?? .poolSize25
        
        // Получаем упражнения тренировки
        let exerciseEntities = workoutEntity.exercises?.allObjects as? [ExerciseEntity] ?? []
        let sortedExercises = exerciseEntities.sorted { $0.orderIndex < $1.orderIndex }
        
        // Преобразуем ExerciseEntity в Exercise
        exercises = sortedExercises.map { entity -> Exercise in
            return Exercise(
                type: ExerciseType(rawValue: entity.type) ?? .main,
                meters: entity.meters,
                repetitions: entity.repetitions,
                hasInterval: entity.hasInterval,
                intervalMinutes: entity.hasInterval ? entity.intervalMinutes : nil,
                intervalSeconds: entity.hasInterval ? entity.intervalSeconds : nil,
                style: SwimStyle(rawValue: entity.style) ?? .freestyle,
                description: entity.exerciseDescription ?? ""
            )
        }
        
        let response = WorkoutEditionModels.LoadWorkout.Response(
            name: name,
            poolSize: poolSize,
            exercises: exercises
        )
        
        presenter?.presentLoadWorkout(response: response)
    }
    
    // MARK: - Update Workout
    func updateWorkout(request: WorkoutEditionModels.UpdateWorkout.Request) {
        // 1. Проверяем название тренировки
        let trimmedName = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Проверка на пустое или состоящее только из пробелов
        if trimmedName.isEmpty {
            let response = WorkoutEditionModels.UpdateWorkout.Response(
                success: false,
                errorMessage: Constants.nameErrorMessage
            )
            presenter?.presentUpdateWorkout(response: response)
            return
        }
        
        // Проверяем длину (не больше 30 символов)
        if trimmedName.count > 30 {
            let response = WorkoutEditionModels.UpdateWorkout.Response(
                success: false,
                errorMessage: Constants.nameErrorMessageLength
            )
            presenter?.presentUpdateWorkout(response: response)
            return
        }
        
        // Проверяем размер бассейна (либо 25, либо 50)
        let allowedPoolSizes = [25, 50]
        if !allowedPoolSizes.contains(Int(request.poolSize.rawValue)) {
            let response = WorkoutEditionModels.UpdateWorkout.Response(
                success: false,
                errorMessage: Constants.poolSizeErrorMessage
            )
            presenter?.presentUpdateWorkout(response: response)
            return
        }
        
        // Проверяем, что есть хотя бы одно упражнение
        if request.exercises.isEmpty {
            let response = WorkoutEditionModels.UpdateWorkout.Response(
                success: false,
                errorMessage: Constants.exercizeEmptyMessage
            )
            presenter?.presentUpdateWorkout(response: response)
            return
        }
        
        // Проверяем каждое упражнение
        for exercise in request.exercises {
            if exercise.meters <= 0 {
                let response = WorkoutEditionModels.UpdateWorkout.Response(
                    success: false,
                    errorMessage: Constants.metersErrorMessage
                )
                presenter?.presentUpdateWorkout(response: response)
                return
            }
            
            if exercise.repetitions <= 0 {
                let response = WorkoutEditionModels.UpdateWorkout.Response(
                    success: false,
                    errorMessage: Constants.repetitionsErrorMessage
                )
                presenter?.presentUpdateWorkout(response: response)
                return
            }
            
            if exercise.hasInterval {
                if exercise.intervalMinutes == nil || exercise.intervalSeconds == nil {
                    let response = WorkoutEditionModels.UpdateWorkout.Response(
                        success: false,
                        errorMessage: Constants.minsAndSecondsEmptyMessage
                    )
                    presenter?.presentUpdateWorkout(response: response)
                    return
                }
                
                if exercise.intervalMinutes! < 0 || exercise.intervalSeconds! < 0 {
                    let response = WorkoutEditionModels.UpdateWorkout.Response(
                        success: false,
                        errorMessage: Constants.minsAndSecondsErrorMessage
                    )
                    presenter?.presentUpdateWorkout(response: response)
                    return
                }
            }
        }
        
        // Если все проверки пройдены, обновляем тренировку в CoreData
        guard let workoutIndex = workoutIndex,
              let workouts = workouts,
              workoutIndex < workouts.count else {
            let response = WorkoutEditionModels.UpdateWorkout.Response(
                success: false,
                errorMessage: Constants.workoutSavingErrorMessage
            )
            presenter?.presentUpdateWorkout(response: response)
            return
        }
        
        let workoutEntity = workouts[workoutIndex]
        
        // Обновляем данные тренировки
        workoutEntity.name = request.name
        workoutEntity.poolSize = request.poolSize.rawValue
        
        // Удаляем все текущие упражнения
        if let existingExercises = workoutEntity.exercises {
            for exercise in existingExercises {
                if let exerciseEntity = exercise as? ExerciseEntity {
                    CoreDataManager.shared.deleteExercise(exerciseEntity)
                }
            }
        }
        
        // Добавляем новые упражнения
        for (index, exercise) in request.exercises.enumerated() {
            _ = CoreDataManager.shared.createExercise(
                for: workoutEntity,
                description: exercise.description,
                style: exercise.style.rawValue,
                type: exercise.type.rawValue,
                hasInterval: exercise.hasInterval,
                intervalMinutes: exercise.intervalMinutes ?? 0,
                intervalSeconds: exercise.intervalSeconds ?? 0,
                meters: exercise.meters,
                orderIndex: Int16(index),
                repetitions: exercise.repetitions
            )
        }
        
        // Сохраняем изменения
        let success = CoreDataManager.shared.saveContext()
        let response = WorkoutEditionModels.UpdateWorkout.Response(
            success: success,
            errorMessage: success ? nil : Constants.workoutSavingErrorMessage
        )
        
        presenter?.presentUpdateWorkout(response: response)
    }
    
    // MARK: - Add Exercise
    func addExercise(request: WorkoutEditionModels.AddExercise.Request) {
        exercises.append(request.exercise) // Добавляем новое упражнение
        let response = WorkoutEditionModels.AddExercise.Response(exercises: exercises)
        presenter?.presentAddExercise(response: response)
    }
    
    // MARK: - Delete Exercise
    func deleteExercise(request: WorkoutEditionModels.DeleteExercise.Request) {
        guard request.index >= 0 && request.index < exercises.count else {
            return // Если индекс некорректен, ничего не делаем
        }
        exercises.remove(at: request.index) // Удаляем упражнение
        let response = WorkoutEditionModels.DeleteExercise.Response(exercises: exercises)
        presenter?.presentDeleteExercise(response: response)
    }
    
    // MARK: - Update Exercise
    func updateExercise(request: WorkoutEditionModels.UpdateExercise.Request) {
        exercises[request.index] = request.exercise // Обновляем упражнение
        let response = WorkoutEditionModels.UpdateExercise.Response(exercises: exercises)
        presenter?.presentUpdateExercise(response: response)
    }
}
