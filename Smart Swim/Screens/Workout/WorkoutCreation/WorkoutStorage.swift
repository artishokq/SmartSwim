//
//  WorkoutStorage.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit

final class WorkoutStorage {
    static let shared = WorkoutStorage()
    private init() {}
    
    private let defaults = UserDefaults.standard
    private let workoutsKey = "savedWorkouts"
    
    // Сохранение тренировки
    func saveWorkout(_ workout: Workout) {
        var workouts = getAllWorkouts()
        workouts.append(workout)
        if let encoded = try? JSONEncoder().encode(workouts) {
            defaults.set(encoded, forKey: workoutsKey)
        }
    }
    
    // Получение всех тренировок
    func getAllWorkouts() -> [Workout] {
        if let savedWorkouts = defaults.object(forKey: workoutsKey) as? Data,
           let decodedWorkouts = try? JSONDecoder().decode([Workout].self, from: savedWorkouts) {
            return decodedWorkouts
        }
        return []
    }
    
    // Удаление тренировки
    func deleteWorkout(at index: Int) {
        var workouts = getAllWorkouts()
        guard index < workouts.count else { return }
        workouts.remove(at: index)
        if let encoded = try? JSONEncoder().encode(workouts) {
            defaults.set(encoded, forKey: workoutsKey)
        }
    }
    
    // Обновление тренировки
    func updateWorkout(_ workout: Workout, at index: Int) {
        var workouts = getAllWorkouts()
        guard index < workouts.count else { return }
        workouts[index] = workout
        if let encoded = try? JSONEncoder().encode(workouts) {
            defaults.set(encoded, forKey: workoutsKey)
        }
    }
}
