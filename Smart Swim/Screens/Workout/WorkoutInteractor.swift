//
//  WorkoutInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol WorkoutBusinessLogic {
    func createWorkout(request: Workout.Create.Request)
    func showInfo(request: Workout.Info.Request)
}

protocol WorkoutDataStore {
    // Data store properties
}

final class WorkoutInteractor: WorkoutBusinessLogic, WorkoutDataStore {
    var presenter: WorkoutPresentationLogic?
    
    func createWorkout(request: Workout.Create.Request) {
        let response = Workout.Create.Response()
        presenter?.presentCreateWorkout(response: response)
    }
    
    func showInfo(request: Workout.Info.Request) {
        let response = Workout.Info.Response()
        presenter?.presentInfo(response: response)
    }
}
