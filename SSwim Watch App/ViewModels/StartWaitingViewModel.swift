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
    private let watchSession = WatchSessionService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupSubscriptions()
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Listen for ready state
        watchSession.isReadyToStartPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isReady in
                guard let self = self else { return }
                
                // Обновляем состояние и принудительно уведомляем наблюдателей
                if self.isReadyToStart != isReady {
                    self.isReadyToStart = isReady
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
        
        // Listen for commands
        watchSession.commandPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] command in
                guard let self = self else { return }
                
                print("StartWaitingViewModel: Получена команда: \(command)")
                
                // Используем DispatchQueue для надежного обновления UI
                DispatchQueue.main.async {
                    self.command = command
                    
                    // Принудительно уведомляем наблюдателей
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func resetCommand() {
        command = ""
    }
}
