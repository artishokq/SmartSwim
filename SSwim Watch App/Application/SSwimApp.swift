//
//  SSwimApp.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import SwiftUI

@main
struct SSwim_Watch_AppApp: App {
    // Для отслеживания состояния приложения
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Инициализация сервисов при запуске
    init() {
        ServiceLocator.shared.initializeServices()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                // Передаем нужные сервисы через environment
                MainView()
                    .environmentObject(ServiceLocator.shared.startService)
                    .environmentObject(ServiceLocator.shared.workoutService)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReturnToRootView"))) { _ in
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Запрашиваем тренировки при переходе приложения в активное состояние
                ServiceLocator.shared.workoutService.loadWorkouts()
            }
        }
    }
}
