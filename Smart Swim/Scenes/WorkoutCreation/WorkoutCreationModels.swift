//
//  WorkoutCreationModels.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 23.01.2025.
//

import Foundation

enum WorkoutCreationModels {
    // MARK: - Create Workout
    enum CreateWorkout {
        struct Request {
            var name: String
            var poolSize: PoolSize
            var exercises: [Exercise]
        }
        
        struct Response {
            var success: Bool
            var errorMessage: String?
        }
        
        struct ViewModel {
            var success: Bool
            var errorMessage: String?
        }
    }
    
    // MARK: - Add Exercise
    enum AddExercise {
        struct Request {
            var exercise: Exercise
        }
        
        struct Response {
            var exercises: [Exercise]
        }
        
        struct ViewModel {
            var exercises: [Exercise]
        }
    }
    
    // MARK: - Delete Exercise
    enum DeleteExercise {
        struct Request {
            var index: Int
        }
        
        struct Response {
            var exercises: [Exercise]
        }
        
        struct ViewModel {
            var exercises: [Exercise]
        }
    }
    
    // MARK: - Update Exercise
    enum UpdateExercise {
        struct Request {
            var exercise: Exercise
            var index: Int
        }
        
        struct Response {
            var exercises: [Exercise]
        }
        
        struct ViewModel {
            var exercises: [Exercise]
        }
    }
}
