//
//  MainView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import SwiftUI

struct MainView: View {
    // MARK: - Constants
    private enum Constants {
        static let appTitle: String = "Smart Swim"
        static let startsButtonText: String = "Старты"
        static let workoutsTitle: String = "Тренировки"
        static let workoutsFutureMessage: String = "Список тренировок будет доступен в будущем"
        
        static let swimIcon: String = "figure.pool.swim"
        
        static let mainStackSpacing: CGFloat = 10
        static let itemsStackSpacing: CGFloat = 12
        static let historyStackSpacing: CGFloat = 8
        static let cornerRadius: CGFloat = 8
        static let topPadding: CGFloat = 8
        
        static let swimIconColor: Color = Color.blue
        static let buttonBackgroundColor: Color = Color.gray.opacity(0.2)
        static let futureMessageColor: Color = Color.gray
    }
    
    // MARK: - Properties
    @StateObject private var viewModel = MainViewModel()
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.mainStackSpacing) {
                    // Заголовок, который будет прокручиваться вместе с содержимым
                    Text(Constants.appTitle)
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, Constants.topPadding)
                    
                    VStack(spacing: Constants.itemsStackSpacing) {
                        // MARK: - Кнопка "Старты"
                        Button(action: {
                            viewModel.startNewWorkout()
                        }) {
                            HStack {
                                Image(systemName: Constants.swimIcon)
                                    .foregroundColor(Constants.swimIconColor)
                                Text(Constants.startsButtonText)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Constants.buttonBackgroundColor)
                            .cornerRadius(Constants.cornerRadius)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // MARK: - Секция тренировок
                        VStack(alignment: .leading, spacing: Constants.historyStackSpacing) {
                            Text(Constants.workoutsTitle)
                                .font(.headline)
                            
                            VStack {
                                Text(Constants.workoutsFutureMessage)
                                    .font(.footnote)
                                    .foregroundColor(Constants.futureMessageColor)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                            }
                            .background(Constants.buttonBackgroundColor)
                            .cornerRadius(Constants.cornerRadius)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
            }
            .navigationDestination(isPresented: $viewModel.navigateToStartView) {
                StartWaitingView()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Previews
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
