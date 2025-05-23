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
        
        static let swimIcon: String = "figure.pool.swim"
        static let swimIconSize: CGFloat = 22
        
        static let mainStackSpacing: CGFloat = 10
        static let itemsStackSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 8
        static let topPadding: CGFloat = 8
        
        static let swimIconColor: Color = Color.blue
        static let buttonBackgroundColor: Color = Color.gray.opacity(0.2)
        
        static let startsButtonMinHeight: CGFloat = 60
        static let startsButtonPadding: CGFloat = 14
        
        static let workoutSectionSpace: CGFloat = 8
    }
    
    // MARK: - Properties
    @State private var refreshTrigger = false
    @StateObject private var viewModel = MainViewModel()
    @EnvironmentObject private var startService: StartService
    @EnvironmentObject private var workoutService: WorkoutService
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Constants.mainStackSpacing) {
                    // Заголовок приложения
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
                                    .font(.system(size: Constants.swimIconSize))
                                Text(Constants.startsButtonText)
                                    .font(.headline)
                                Spacer()
                            }
                            .padding(.vertical, Constants.startsButtonPadding)
                            .padding(.horizontal)
                            .frame(maxWidth: .infinity)
                            .background(Constants.buttonBackgroundColor)
                            .cornerRadius(Constants.cornerRadius)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // MARK: - Секция тренировок
                        VStack(alignment: .leading, spacing: Constants.workoutSectionSpace) {
                            Text(Constants.workoutsTitle)
                                .font(.headline)
                            // Встроенный список тренировок
                            WorkoutListView()
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
        .onAppear {
            workoutService.loadWorkouts()
            
            // Принудительно обновляем UI через определенные интервалы
            for delay in [0.5, 1.5, 3.0, 5.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [self] in
                    refreshTrigger.toggle()
                    
                    // Также пробуем загрузить тренировки еще раз, если их еще нет
                    if workoutService.workouts.isEmpty && !workoutService.isLoading {
                        workoutService.loadWorkouts()
                    }
                }
            }
        }
        .onChange(of: refreshTrigger) { _, _ in
            // Пустое действие, нужно только для обновления View
        }
    }
}

// MARK: - Previews
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(ServiceLocator.shared.startService)
            .environmentObject(ServiceLocator.shared.workoutService)
    }
}
