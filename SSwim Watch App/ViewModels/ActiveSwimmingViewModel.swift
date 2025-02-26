//
//  ActiveSwimmingViewModel.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 26.02.2025.
//

import SwiftUI
import Combine

class ActiveSwimmingViewModel: ObservableObject {
    // MARK: - Constants
    private enum Constants {
        static let startStatus = "started"
        static let stopStatus = "stopped"
        static let rootViewNotification = "ReturnToRootView"
        static let poolLengthReceiveTimeout: TimeInterval = 1.0
        static let maxRetries = 3
    }
    
    // MARK: - Published Properties
    @Published var session = SwimSession(poolLength: 25.0, swimmingStyle: 0, totalMeters: 0)
    @Published var command = ""
    
    // MARK: - Private Properties
    private let healthService = HealthKitService.shared
    private let watchSession = WatchSessionService.shared
    private var cancellables = Set<AnyCancellable>()
    private var hasUpdatedPoolLength = false
    private var retryCount = 0
    
    // MARK: - Initialization
    init() {
        // Сразу после инициализации устанавливаем длину бассейна из сервиса
        session.poolLength = watchSession.getCurrentPoolLength()
        print("[ViewModel] Начальная длина бассейна: \(session.poolLength)м")
        
        setupSubscriptions()
    }
    
    // MARK: - Private Methods
    private func setupSubscriptions() {
        // Подписка на обновления пульса
        healthService.heartRatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] heartRate in
                self?.session.heartRate = heartRate
                // Отправляем на телефон
                self?.watchSession.sendHeartRateToPhone(heartRate: Int(heartRate))
            }
            .store(in: &cancellables)
        
        // Подписка на обновления счетчика гребков
        healthService.strokeCountPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] strokeCount in
                self?.session.strokeCount = strokeCount
                // Отправляем на телефон
                self?.watchSession.sendStrokeCountToPhone(strokeCount: strokeCount)
            }
            .store(in: &cancellables)
        
        // Подписка на состояние тренировки
        healthService.workoutStatePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] isActive in
                self?.session.isActive = isActive
            }
            .store(in: &cancellables)
        
        // Подписка на обновления длины бассейна с высоким приоритетом
        watchSession.poolLengthPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] poolLength in
                guard let self = self else { return }
                print("[ViewModel] Получена длина бассейна: \(poolLength)м")
                
                // Обновляем значение в нашей модели
                self.session.poolLength = poolLength
                self.hasUpdatedPoolLength = true
                
                // Если тренировка уже активна и длина бассейна изменилась, перезапускаем тренировку
                if self.session.isActive && poolLength != self.healthService.getCurrentWorkoutPoolLength() {
                    print("[ViewModel] Перезапуск тренировки с новой длиной бассейна: \(poolLength)м")
                    self.restartWorkoutIfNeeded(with: poolLength)
                }
            }
            .store(in: &cancellables)
        
        // Остальные подписки
        watchSession.swimmingStylePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] style in
                self?.session.swimmingStyle = style
            }
            .store(in: &cancellables)
        
        watchSession.totalMetersPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] meters in
                self?.session.totalMeters = meters
            }
            .store(in: &cancellables)
        
        watchSession.commandPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] command in
                guard let self = self else { return }
                print("[ViewModel] Получена команда: \(command)")
                self.command = command
            }
            .store(in: &cancellables)
    }
    
    private func restartWorkoutIfNeeded(with poolLength: Double) {
        // Останавливаем текущую тренировку
        healthService.stopWorkout()
        
        // Запускаем новую с правильной длиной бассейна
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.healthService.startWorkout(poolLength: poolLength)
        }
    }
    
    private func ensurePoolLength(completion: @escaping () -> Void) {
        // Сначала запрашиваем актуальное значение длины бассейна
        print("[ViewModel] Запрашиваем актуальную длину бассейна...")
        
        let requestSuccess = watchSession.requestPoolLengthFromPhone()
        
        if requestSuccess {
            // Если запрос отправлен успешно, ждем ответа
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.poolLengthReceiveTimeout) {
                // Обновляем длину бассейна в сессии
                let poolLength = self.watchSession.getCurrentPoolLength()
                self.session.poolLength = poolLength
                print("[ViewModel] Получена длина бассейна для тренировки: \(poolLength)м")
                completion()
            }
        } else {
            // Если запрос не удался, увеличиваем счетчик повторных попыток
            retryCount += 1
            
            if retryCount < Constants.maxRetries {
                // Пробуем другой способ получения параметров
                let allParamsSuccess = watchSession.requestAllParameters()
                
                if allParamsSuccess {
                    // Если запрос отправлен успешно, ждем ответа
                    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.poolLengthReceiveTimeout) {
                        // Обновляем длину бассейна в сессии
                        let poolLength = self.watchSession.getCurrentPoolLength()
                        self.session.poolLength = poolLength
                        print("[ViewModel] Получена длина бассейна через запрос всех параметров: \(poolLength)м")
                        completion()
                    }
                } else {
                    // Если ничего не помогло, используем текущее значение
                    print("[ViewModel] Не удалось получить данные от iPhone, используем текущее значение: \(self.session.poolLength)м")
                    completion()
                }
            } else {
                // Исчерпали попытки, используем текущее значение
                print("[ViewModel] Исчерпаны все попытки, используем текущее значение: \(self.session.poolLength)м")
                completion()
            }
        }
    }
    
    // MARK: - Public Methods
    func clearCommands() {
        command = ""
    }
    
    func startWorkout() {
        retryCount = 0 // Сбрасываем счетчик попыток
        
        // Получаем актуальное значение длины бассейна перед запуском
        ensurePoolLength { [weak self] in
            guard let self = self else { return }
            
            let poolLength = self.session.poolLength
            print("[ViewModel] Запуск тренировки с длиной бассейна: \(poolLength)м")
            
            // Запуск тренировки с актуальной длиной бассейна
            self.healthService.startWorkout(poolLength: poolLength)
            
            // Уведомляем телефон
            self.watchSession.sendStatusToPhone(status: Constants.startStatus)
        }
    }
    
    func stopWorkout() {
        // Останавливаем тренировку
        healthService.stopWorkout()
        // Уведомляем телефон
        watchSession.sendStatusToPhone(status: Constants.stopStatus)
    }
    
    func navigateToRoot() {
        // Сбрасываем состояние
        command = ""
        // Уведомляем приложение о переходе на главный экран
        NotificationCenter.default.post(name: NSNotification.Name(Constants.rootViewNotification), object: nil)
    }
}
