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
        static let activeTitle = "Плавание активно"
        static let poolLengthFormat = "Бассейн: %dм"
        static let heartRateFormat = "Пульс: %d уд/м"
        static let strokeCountFormat = "Гребки: %d"
        static let stopCommand = "stop"
        
        static let heartIcon = "heart.fill"
        static let swimIcon = "figure.pool.swim"
        
        static let mainStackSpacing: CGFloat = 15
        static let metricsStackSpacing: CGFloat = 12
        static let rootNavigationDelay: TimeInterval = 0.5
        
        static let activeTitleColor = Color.green
        static let poolInfoColor = Color.gray
        static let heartIconColor = Color.red
        static let swimIconColor = Color.blue
    }
    
    // MARK: - Properties
    @StateObject private var viewModel = ActiveSwimmingViewModel()
    @Environment(\.presentationMode) var presentationMode
    @State private var shouldNavigateToRoot = false
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.mainStackSpacing) {
            Text(Constants.activeTitle)
                .font(.headline)
                .foregroundColor(Constants.activeTitleColor)
            
            Text(String(format: Constants.poolLengthFormat, Int(viewModel.session.poolLength)))
                .font(.footnote)
                .foregroundColor(Constants.poolInfoColor)
            
            // MARK: - Metrics
            VStack(alignment: .leading, spacing: Constants.metricsStackSpacing) {
                HStack {
                    Image(systemName: Constants.heartIcon)
                        .foregroundColor(Constants.heartIconColor)
                    Text(String(format: Constants.heartRateFormat, Int(viewModel.session.heartRate)))
                }
                
                HStack {
                    Image(systemName: Constants.swimIcon)
                        .foregroundColor(Constants.swimIconColor)
                    Text(String(format: Constants.strokeCountFormat, viewModel.session.strokeCount))
                }
            }
            .padding()
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            // Чистим предыдущие команды при появлении экрана
            viewModel.clearCommands()
            // Запускаем тренировку
            viewModel.startWorkout()
            print("Плавание активно с длиной бассейна: \(viewModel.session.poolLength)м")
        }
        // Используем новый синтаксис onChange начиная с watchOS 10
        .onChange(of: viewModel.command) { _, newCommand in
            if newCommand == Constants.stopCommand {
                print("Получена команда остановки")
                viewModel.stopWorkout()
                
                // Используем более надежный механизм навигации
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.rootNavigationDelay) {
                    shouldNavigateToRoot = true
                }
            }
        }
        // Используем современный подход к навигации
        .navigationDestination(isPresented: $shouldNavigateToRoot) {
            MainView()
                .navigationBarBackButtonHidden(true)
        }
    }
}

// MARK: - Previews
struct ActiveSwimmingView_Previews: PreviewProvider {
    static var previews: some View {
        ActiveSwimmingView()
    }
}
