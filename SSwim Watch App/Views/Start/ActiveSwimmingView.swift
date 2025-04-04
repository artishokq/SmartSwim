//
//  ActiveSwimmingView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import SwiftUI

struct ActiveSwimmingView: View {
    // MARK: - Constants
    private enum Constants {
        static let activeTitle: String = "Плавание активно"
        static let poolLengthFormat: String = "Бассейн: %dм"
        static let heartRateFormat: String = "Пульс: %d уд/м"
        static let stopCommand: String = "stop"
        
        static let heartIcon = "heart.fill"
        
        static let mainStackSpacing: CGFloat = 12
        static let metricsStackSpacing: CGFloat = 12
        static let rootNavigationDelay: TimeInterval = 0.5
        
        static let activeTitleColor = Color.green
        static let poolInfoColor = Color.gray
        static let heartIconColor = Color.red
    }
    
    // MARK: - Properties
    @StateObject private var viewModel = ActiveSwimmingViewModel()
    @EnvironmentObject private var startService: StartService
    @Environment(\.presentationMode) var presentationMode
    @State private var shouldNavigateToRoot = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.mainStackSpacing) {
            Text(Constants.activeTitle)
                .font(.headline)
                .foregroundColor(Constants.activeTitleColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
            
            Text(String(format: Constants.poolLengthFormat, Int(startService.session.poolLength)))
                .font(.headline)
                .foregroundColor(Constants.poolInfoColor)
            
            // MARK: - Metrics
            HStack {
                Image(systemName: Constants.heartIcon)
                    .foregroundColor(Constants.heartIconColor)
                Text(String(format: Constants.heartRateFormat, Int(startService.session.heartRate)))
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.setupWithService(startService: startService)
            viewModel.clearCommands()
            viewModel.startWorkout()
        }
        .onChange(of: viewModel.command) { _, newCommand in
            if newCommand == Constants.stopCommand {
                viewModel.stopWorkout()
                
                startService.resetParameters()
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.rootNavigationDelay) {
                    shouldNavigateToRoot = true
                }
            }
        }
        .navigationDestination(isPresented: $shouldNavigateToRoot) {
            MainView()
                .navigationBarBackButtonHidden(true)
        }
        .onDisappear {
            startService.resetParameters()
        }
    }
}

// MARK: - Previews
struct ActiveSwimmingView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveSwimmingView()
            .environmentObject(ServiceLocator.shared.startService)
    }
}
