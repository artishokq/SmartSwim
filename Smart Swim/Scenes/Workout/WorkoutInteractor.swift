//
//  WorkoutInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol WorkoutBusinessLogic {
    func createWorkout(request: WorkoutModels.Create.Request)
    func showInfo(request: WorkoutModels.Info.Request)
    func fetchWorkouts(request: WorkoutModels.FetchWorkouts.Request)
    func deleteWorkout(request: WorkoutModels.DeleteWorkout.Request)
    func editWorkout(request: WorkoutModels.EditWorkout.Request)
}

protocol WorkoutDataStore {
    var workouts: [WorkoutEntity]? { get set }
}

protocol CoreDataManagerProtocol {
    func fetchAllWorkouts() -> [WorkoutEntity]
    func deleteWorkout(_ workout: WorkoutEntity)
}

final class WorkoutInteractor: WorkoutBusinessLogic, WorkoutDataStore {
    var presenter: WorkoutPresentationLogic?
    var workouts: [WorkoutEntity]?
    var coreDataManager: CoreDataManagerProtocol
    
    init(coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared) {
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - Create Workout Button
    func createWorkout(request: WorkoutModels.Create.Request) {
        let response = WorkoutModels.Create.Response()
        presenter?.presentWorkoutCreation(response: response)
    }
    
    // MARK: - Show Info Button
    func showInfo(request: WorkoutModels.Info.Request) {
        let response = WorkoutModels.Info.Response()
        presenter?.presentInfo(response: response)
    }
    
    // MARK: - Fetch Workouts
    func fetchWorkouts(request: WorkoutModels.FetchWorkouts.Request) {
        // Use injected coreDataManager instead of directly accessing shared instance
        let workoutEntities = coreDataManager.fetchAllWorkouts()
        self.workouts = workoutEntities
        
        let workoutData = workoutEntities.map { entity -> WorkoutModels.FetchWorkouts.Response.WorkoutData in
            let exercises = (entity.exercises?.allObjects as? [ExerciseEntity])?
                .sorted { $0.orderIndex < $1.orderIndex }
                .enumerated()
                .map { index, exercise -> WorkoutModels.FetchWorkouts.Response.ExerciseData in
                    let formattedString = formatExercise(exercise: exercise, index: index)
                    
                    return WorkoutModels.FetchWorkouts.Response.ExerciseData(
                        meters: exercise.meters,
                        styleDescription: getStyleDescription(SwimStyle(rawValue: exercise.style) ?? .any),
                        type: ExerciseType(rawValue: exercise.type) ?? .main,
                        exerciseDescription: exercise.exerciseDescription,
                        formattedString: formattedString,
                        repetitions: exercise.repetitions
                    )
                } ?? []
            
            let totalVolume = exercises.reduce(0) { $0 + Int($1.meters) * Int($1.repetitions) }
            
            return WorkoutModels.FetchWorkouts.Response.WorkoutData(
                name: entity.name ?? "Без названия",
                exercises: exercises,
                totalVolume: totalVolume
            )
        }
        
        let response = WorkoutModels.FetchWorkouts.Response(workouts: workoutData)
        presenter?.presentWorkouts(response: response)
    }
    
    // MARK: - Workout Deletion
    func deleteWorkout(request: WorkoutModels.DeleteWorkout.Request) {
        guard let workouts = workouts,
              request.index < workouts.count else {
            return
        }
        
        let workoutToDelete = workouts[request.index]
        coreDataManager.deleteWorkout(workoutToDelete)
        
        // Удаляем из локального массива интерактора
        self.workouts?.remove(at: request.index)
        
        // Сообщаем презентеру
        let response = WorkoutModels.DeleteWorkout.Response(deletedIndex: request.index)
        presenter?.presentDeleteWorkout(response: response)
    }
    
    // MARK: - Edit Workout
    func editWorkout(request: WorkoutModels.EditWorkout.Request) {
        let response = WorkoutModels.EditWorkout.Response(index: request.index)
        presenter?.presentEditWorkout(response: response)
    }
    
    // MARK: - Private Methods
    private func getStyleDescription(_ style: SwimStyle) -> String {
        switch style {
        case .freestyle: return "кроль"
        case .breaststroke: return "брасс"
        case .backstroke: return "на спине"
        case .butterfly: return "баттерфляй"
        case .medley: return "комплекс"
        case .any: return "любой стиль"
        }
    }
    
    private func getTypeDescription(_ type: ExerciseType) -> String? {
        switch type {
        case .warmup: return "Разминка"
        case .cooldown: return "Заминка"
        case .main: return nil
        }
    }
    
    private func formatExercise(exercise: ExerciseEntity, index: Int) -> String {
        let exerciseNumber = "\(index + 1). "
        
        // Собираем первую строку без номера
        var mainLineParts: [String] = []
        
        // Добавляем тип упражнения (разминка/заминка)
        if let type = ExerciseType(rawValue: exercise.type),
           let typeDescription = getTypeDescription(type) {
            mainLineParts.append(typeDescription)
        }
        
        // Форматируем дистанцию
        if exercise.repetitions > 1 {
            mainLineParts.append("\(exercise.repetitions)x\(exercise.meters)м")
        } else {
            mainLineParts.append("\(exercise.meters)м")
        }
        
        // Добавляем стиль
        let style = SwimStyle(rawValue: exercise.style) ?? .any
        mainLineParts.append(getStyleDescription(style))
        
        // Собираем первую строку с отступом
        let mainLine = mainLineParts.joined(separator: " ")
        var result = exerciseNumber + mainLine
        
        // Для последующих строк добавляем отступ, равный длине номера
        let padding = String(repeating: " ", count: exerciseNumber.count)
        
        // Добавляем интервал если есть
        if exercise.hasInterval {
            var intervalParts: [String] = ["Режим"]
            if exercise.intervalMinutes > 0 {
                intervalParts.append("\(exercise.intervalMinutes) мин")
            }
            if exercise.intervalSeconds > 0 {
                intervalParts.append("\(exercise.intervalSeconds) сек")
            }
            result += "\n " + padding + intervalParts.joined(separator: " ")
        }
        
        // Добавляем описание если есть
        if let description = exercise.exerciseDescription, !description.isEmpty {
            result += "\n " + padding + description
        }
        
        return result
    }
}

extension CoreDataManager: CoreDataManagerProtocol {}
