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
        // Строковые константы
        static let waitingTitle = "Ожидание старта"
        static let setupInstructions = "Настройте параметры на iPhone и нажмите Старт"
        static let parametersReceived = "Параметры получены!"
        
        // Числовые константы
        static let stackSpacing: CGFloat = 15
        static let iconSize: CGFloat = 45
        static let textHorizontalPadding: CGFloat = 5
        static let successVerticalPadding: CGFloat = 8
        static let navigationDelay: TimeInterval = 0.2
        
        // Цвета
        static let iconColor = Color.blue
        static let successColor = Color.green
    }
    
    // MARK: - Properties
    @StateObject private var viewModel = StartWaitingViewModel()
    
    // Разделяем состояние навигации и состояние получения команды
    @State private var shouldNavigate = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.stackSpacing) {
                Text(Constants.waitingTitle)
                    .font(.headline)
                
                Image(systemName: "iphone.circle")
                    .font(.system(size: Constants.iconSize))
                    .foregroundColor(Constants.iconColor)
                
                Text(Constants.setupInstructions)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Constants.textHorizontalPadding)
                
                if viewModel.isReadyToStart {
                    Text(Constants.parametersReceived)
                        .foregroundColor(Constants.successColor)
                        .padding(.vertical, Constants.successVerticalPadding)
                }
                
                // Добавляем невидимую кнопку для обновления представления при необходимости
                Button(action: {
                    // Ничего не делаем, это просто для форсирования обновления UI
                }) {
                    Color.clear
                        .frame(width: 1, height: 1)
                }
                .opacity(0)
                .accessibilityHidden(true)
            }
            .padding(.horizontal)
        }
        .navigationBarBackButtonHidden(viewModel.isReadyToStart)
        .navigationDestination(isPresented: $shouldNavigate) {
            ActiveSwimmingView()
        }
        .onChange(of: viewModel.command) { _, newCommand in
            if newCommand == "start" {
                print("Получена команда старта, выполняем переход...")
                
                // Сначала убеждаемся, что находимся в основном потоке
                DispatchQueue.main.async {
                    // Добавляем небольшую задержку для надежности
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.navigationDelay) {
                        shouldNavigate = true
                        
                        // Дополнительно запускаем таймер для проверки, произошел ли переход
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            if !shouldNavigate {
                                print("Таймаут ожидания перехода, форсируем...")
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
    }
}
