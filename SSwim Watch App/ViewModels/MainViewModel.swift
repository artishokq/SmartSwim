//
//  MainViewModel.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import SwiftUI
import Combine

final class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var navigateToStartView = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let communicationService: WatchCommunicationService
    
    // MARK: - Initialization
    init(communicationService: WatchCommunicationService = ServiceLocator.shared.communicationService) {
        self.communicationService = communicationService
        communicationService.startSession()
    }
    
    // MARK: - Public Methods
    func startNewWorkout() {
        navigateToStartView = true
    }
}
