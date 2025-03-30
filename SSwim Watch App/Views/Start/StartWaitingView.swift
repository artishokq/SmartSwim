//
//  StartWaitingView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import SwiftUI

struct StartWaitingView: View {
    // MARK: - Constants
    private enum Constants {
        static let waitingTitle = "Ожидание старта"
        static let setupInstructions = "Настройте параметры на iPhone и нажмите Старт"
        
        static let iphoneIconName: String = "iphone.circle"
        
        static let stackSpacing: CGFloat = 15
        static let iconSize: CGFloat = 45
        static let textHorizontalPadding: CGFloat = 5
        static let navigationDelay: TimeInterval = 0.2
        
        static let iconColor = Color.blue
    }
    
    // MARK: - Properties
    @StateObject private var viewModel = StartWaitingViewModel()
    @EnvironmentObject private var startService: StartService
    @State private var shouldNavigate = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.stackSpacing) {
                Text(Constants.waitingTitle)
                    .font(.headline)
                
                Image(systemName: Constants.iphoneIconName)
                    .font(.system(size: Constants.iconSize))
                    .foregroundColor(Constants.iconColor)
                
                Text(Constants.setupInstructions)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Constants.textHorizontalPadding)
                
                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(false)
        .navigationDestination(isPresented: $shouldNavigate) {
            ActiveSwimmingView()
        }
        .onAppear {
            viewModel.setupWithService(startService: startService)
            // Запрашиваем параметры при появлении
            startService.resetAndRequestParameters()
        }
        .onChange(of: startService.command) { _, newCommand in
            if newCommand == "start" {
                DispatchQueue.main.async {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.navigationDelay) {
                        shouldNavigate = true
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if !shouldNavigate {
                                shouldNavigate = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    shouldNavigate = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            viewModel.resetCommand()
        }
    }
}

// MARK: - Previews
struct StartWaitingView_Previews: PreviewProvider {
    static var previews: some View {
        StartWaitingView()
            .environmentObject(ServiceLocator.shared.startService)
    }
}
