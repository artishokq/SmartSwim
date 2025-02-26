//
//  SSwimApp.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import SwiftUI

@main
struct SSwim_Watch_AppApp: App {
    @State private var navigateToRoot = false
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                MainView()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ReturnToRootView"))) { _ in
                self.navigateToRoot = true
            }
        }
    }
}
