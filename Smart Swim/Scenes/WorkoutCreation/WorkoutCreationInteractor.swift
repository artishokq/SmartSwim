//
//  WorkoutCreationInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 23.01.2025.
//

import UIKit

protocol WorkoutCreationBusinessLogic {
    func createWorkout(request: WorkoutCreationModels.CreateWorkout.Request)
    func addExercise(request: WorkoutCreationModels.AddExercise.Request)
    func deleteExercise(request: WorkoutCreationModels.DeleteExercise.Request)
    func updateExercise(request: WorkoutCreationModels.UpdateExercise.Request)
}

protocol WorkoutCreationDataStore {
    
}

final class WorkoutCreationInteractor: WorkoutCreationBusinessLogic {
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
    var presenter: WorkoutCreationPresentationLogic?
    var exercises: [Exercise] = []
    
    // MARK: - Create Workout
    func createWorkout(request: WorkoutCreationModels.CreateWorkout.Request) {
        // 1. Проверяем название тренировки
        // Убираем пробелы в начале и конце строки
        let trimmedName = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Проверка на пустое или состоящее только из пробелов
        if trimmedName.isEmpty {
            let response = WorkoutCreationModels.CreateWorkout.Response(
                success: false,
                errorMessage: Constants.nameErrorMessage
            )
            presenter?.presentCreateWorkout(response: response)
            return
        }
        
        // Проверяем длину (не больше 30 символов)
        if trimmedName.count > 30 {
            let response = WorkoutCreationModels.CreateWorkout.Response(
                success: false,
                errorMessage: Constants.nameErrorMessageLength
            )
            presenter?.presentCreateWorkout(response: response)
            return
        }
        
        // Проверяем размер бассейна (либо 25, либо 50)
        let allowedPoolSizes = [25, 50]
        if !allowedPoolSizes.contains(Int(request.poolSize.rawValue)) {
            let response = WorkoutCreationModels.CreateWorkout.Response(
                success: false,
                errorMessage: Constants.poolSizeErrorMessage
            )
            presenter?.presentCreateWorkout(response: response)
            return
        }
        
        // Проверяем, что есть хотя бы одно упражнение
        if request.exercises.isEmpty {
            let response = WorkoutCreationModels.CreateWorkout.Response(
                success: false,
                errorMessage: Constants.exercizeEmptyMessage
            )
            presenter?.presentCreateWorkout(response: response)
            return
        }
        
        // Проверяем каждое упражнение
        for exercise in request.exercises {
            if exercise.meters <= 0 {
                let response = WorkoutCreationModels.CreateWorkout.Response(
                    success: false,
                    errorMessage: Constants.metersErrorMessage
                )
                presenter?.presentCreateWorkout(response: response)
                return
            }
            
            if exercise.repetitions <= 0 {
                let response = WorkoutCreationModels.CreateWorkout.Response(
                    success: false,
                    errorMessage: Constants.repetitionsErrorMessage
                )
                presenter?.presentCreateWorkout(response: response)
                return
            }
            
            if exercise.hasInterval {
                if exercise.intervalMinutes == nil || exercise.intervalSeconds == nil {
                    let response = WorkoutCreationModels.CreateWorkout.Response(
                        success: false,
                        errorMessage: Constants.minsAndSecondsEmptyMessage
                    )
                    presenter?.presentCreateWorkout(response: response)
                    return
                }
                
                if exercise.intervalMinutes! < 0 || exercise.intervalSeconds! < 0 {
                    let response = WorkoutCreationModels.CreateWorkout.Response(
                        success: false,
                        errorMessage: Constants.minsAndSecondsErrorMessage
                    )
                    presenter?.presentCreateWorkout(response: response)
                    return
                }
            }
        }
        
        // Если все проверки пройдены, сохраняем тренировку в CoreData
        let success = CoreDataManager.shared.createWorkout(
            name: request.name,
            poolSize: Int16(request.poolSize.rawValue),
            exercises: request.exercises
        ) != nil
        
        let response = WorkoutCreationModels.CreateWorkout.Response(
            success: success,
            errorMessage: success ? nil : Constants.workoutSavingErrorMessage
        )
        
        presenter?.presentCreateWorkout(response: response)
    }
    
    // MARK: - Add Exercise
    func addExercise(request: WorkoutCreationModels.AddExercise.Request) {
        exercises.append(request.exercise) // Добавляем новое упражнение
        let response = WorkoutCreationModels.AddExercise.Response(exercises: exercises)
        presenter?.presentAddExercise(response: response)
    }
    
    // MARK: - Delete Exercise
    func deleteExercise(request: WorkoutCreationModels.DeleteExercise.Request) {
        guard request.index >= 0 && request.index < exercises.count else {
            return // Если индекс некорректен, ничего не делаем
        }
        exercises.remove(at: request.index) // Удаляем упражнение
        let response = WorkoutCreationModels.DeleteExercise.Response(exercises: exercises)
        presenter?.presentDeleteExercise(response: response)
    }
    
    // MARK: - Update Exercise
    func updateExercise(request: WorkoutCreationModels.UpdateExercise.Request) {
        exercises[request.index] = request.exercise // Обновляем упражнение
        let response = WorkoutCreationModels.UpdateExercise.Response(exercises: exercises)
        presenter?.presentUpdateExercise(response: response)
    }
}
