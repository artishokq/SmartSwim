//
//  ActiveSwimmingViewModel.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import SwiftUI
import Combine

final class ActiveSwimmingViewModel: ObservableObject {
    // MARK: - Constants
    private enum Constants {
        static let startStatus = "started"
        static let stopStatus = "stopped"
        static let rootViewNotification = "ReturnToRootView"
    }
    
    // MARK: - Published Properties
    @Published var command = ""
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var startService: StartService?
    
    // MARK: - Initialization
    init() {
    }
    
    // MARK: - Public Methods
    func setupWithService(startService: StartService) {
        self.startService = startService
        setupSubscriptions()
    }
    
    func clearCommands() {
        command = ""
        startService?.resetCommand()
    }
    
    func startWorkout() {
        guard let startService = startService else {
            return
        }
        
        startService.startWorkout()
    }
    
    func stopWorkout() {
        guard let startService = startService else {
            return
        }
        
        startService.stopWorkout()
    }
    
    func navigateToRoot() {
        command = ""
        NotificationCenter.default.post(name: NSNotification.Name(Constants.rootViewNotification), object: nil)
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        guard let startService = startService else { return }
        
        startService.$command
            .receive(on: RunLoop.main)
            .sink { [weak self] command in
                guard let self = self else { return }
                
                if !command.isEmpty {
                    self.command = command
                }
            }
            .store(in: &cancellables)
    }
}
