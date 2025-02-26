//
//  MainViewModel.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import SwiftUI
import Combine

class MainViewModel: ObservableObject {
    @Published var navigateToStartView = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        WatchSessionService.shared.startSession()
    }
    
    func startNewWorkout() {
        navigateToStartView = true
    }
}
