//
//  WorkoutModels.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

enum WorkoutModels {
    // MARK: - Create
    enum Create {
        struct Request {
            // Ничего не передаём
        }
        
        struct Response {
            // Ничего не передаём
        }
        
        struct ViewModel {
            // Ничего не передаём
        }
    }
    
    // MARK: - Info
    enum Info {
        struct Request {
            // Ничего не передаём
        }
        
        struct Response {
            // Ничего не передаём
        }
        
        struct ViewModel {
            // Ничего не передаём
        }
    }
    
    // MARK: - Fetch Workouts
    enum FetchWorkouts {
        struct Request {}
        
        struct Response {
            struct WorkoutData {
                let name: String
                let exercises: [ExerciseData]
                let totalVolume: Int
            }
            
            struct ExerciseData {
                let meters: Int16
                let styleDescription: String
                let type: ExerciseType
                let exerciseDescription: String?
                let formattedString: String
                let repetitions: Int16
            }
            
            let workouts: [WorkoutData]
        }
        
        struct ViewModel {
            struct DisplayedWorkout {
                let name: String
                let totalVolume: Int
                let exercises: [String]
            }
            let workouts: [DisplayedWorkout]
        }
    }
    
    // MARK: - Delete Workout
    enum DeleteWorkout {
        struct Request {
            let index: Int
        }
        
        struct Response {
            let deletedIndex: Int
        }
        
        struct ViewModel {
            let deletedIndex: Int
        }
    }
    
    // MARK: - Edit Workout
    enum EditWorkout {
        struct Request {
            let index: Int
        }
        
        struct Response {
            let index: Int
        }
        
        struct ViewModel {
            let index: Int
        }
    }
}
