//
//  StartWaitingViewModel.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import SwiftUI
import Combine

class StartWaitingViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isReadyToStart = false
    @Published var command = ""
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var startService: StartService?
    
    // MARK: - Initialization
    init() {
        isReadyToStart = false
    }
    
    // MARK: - Public Methods
    func setupWithService(startService: StartService) {
        self.startService = startService
        setupSubscriptions()
    }
    
    func requestParameters(startService: StartService) {
        if self.startService == nil {
            setupWithService(startService: startService)
        }
        startService.resetAndRequestParameters()
        isReadyToStart = startService.isReadyToStart
    }
    
    func resetParameters(startService: StartService) {
        if self.startService == nil {
            setupWithService(startService: startService)
        }
        startService.resetParameters()
        isReadyToStart = false
    }
    
    func resetCommand() {
        command = ""
        startService?.resetCommand()
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        guard let startService = startService else { return }
        startService.$isReadyToStart
            .receive(on: RunLoop.main)
            .sink { [weak self] isReady in
                guard let self = self else { return }
                
                if self.isReadyToStart != isReady {
                    self.isReadyToStart = isReady
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
        
        startService.$command
            .receive(on: RunLoop.main)
            .sink { [weak self] command in
                guard let self = self else { return }
                
                if !command.isEmpty {
                    DispatchQueue.main.async {
                        self.command = command
                        self.objectWillChange.send()
                    }
                }
            }
            .store(in: &cancellables)
    }
}
