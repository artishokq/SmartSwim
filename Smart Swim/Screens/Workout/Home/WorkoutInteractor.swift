//
//  WorkoutInteractor.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol WorkoutBusinessLogic {
    func createWorkout(request: WorkoutHomeModels.Create.Request)
    func showInfo(request: WorkoutHomeModels.Info.Request)
}

protocol WorkoutDataStore {
    // Data store properties
}

final class WorkoutInteractor: WorkoutBusinessLogic, WorkoutDataStore {
    var presenter: WorkoutPresentationLogic?
    
    func createWorkout(request: WorkoutHomeModels.Create.Request) {
        let response = WorkoutHomeModels.Create.Response()
        presenter?.presentCreateWorkout(response: response)
    }
    
    func showInfo(request: WorkoutHomeModels.Info.Request) {
        let response = WorkoutHomeModels.Info.Response()
        presenter?.presentInfo(response: response)
    }
}
