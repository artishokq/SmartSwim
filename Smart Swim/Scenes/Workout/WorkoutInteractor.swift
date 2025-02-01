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
}

protocol WorkoutDataStore {
    // Data store properties
}

final class WorkoutInteractor: WorkoutBusinessLogic, WorkoutDataStore {
    var presenter: WorkoutPresentationLogic?
    
    func createWorkout(request: WorkoutModels.Create.Request) {
        let response = WorkoutModels.Create.Response()
        presenter?.presentWorkoutCreation(response: response)
    }
    
    func showInfo(request: WorkoutModels.Info.Request) {
        let response = WorkoutModels.Info.Response()
        presenter?.presentInfo(response: response)
    }
}
