//
//  HealthManager.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 25.02.2025.
//

import Foundation
import HealthKit
import Combine

class HealthManager: ObservableObject {
    static let shared = HealthManager()
    
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    private var strokeCountQuery: HKQuery?
    
    @Published var heartRate: Double = 0
    @Published var strokeCount: Int = 0
    private var lastStrokeCount: Double = 0
    
    private init() {}
    
    func requestAuthorization() {
        // Типы данных, которые нам нужны
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let swimmingStrokes = HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount)!
        
        // Запрашиваем разрешение
        healthStore.requestAuthorization(toShare: [], read: [heartRateType, swimmingStrokes]) { success, error in
            if success {
                print("HealthKit Authorization successful.")
            } else if let error = error {
                print("HealthKit Authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    func startHeartRateMonitoring() {
        // Остановим предыдущий запрос, если он существует
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        
        // Получаем тип данных пульса
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        // Запрос на получение последних данных о пульсе
        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, error in
            guard let samples = samples as? [HKQuantitySample], let mostRecentSample = samples.last else {
                return
            }
            
            // Получаем значение пульса и обновляем UI
            let heartRate = mostRecentSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async {
                self?.heartRate = heartRate
            }
        }
        
        // Обновление данных при изменении
        query.updateHandler = { [weak self] _, samples, _, _, error in
            guard let samples = samples as? [HKQuantitySample], let mostRecentSample = samples.last else {
                return
            }
            
            let heartRate = mostRecentSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
            DispatchQueue.main.async {
                self?.heartRate = heartRate
            }
        }
        
        // Запускаем запрос
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    func startStrokeCountMonitoring() {
        // Сбрасываем счетчик гребков
        lastStrokeCount = 0
        strokeCount = 0
        
        // Остановим предыдущий запрос, если он существует
        if let query = strokeCountQuery {
            healthStore.stop(query)
        }
        
        // Получаем тип данных для гребков
        guard let strokeType = HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount) else { return }
        
        // Начальный запрос для получения актуальных данных
        let startDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        
        let query = HKObserverQuery(sampleType: strokeType, predicate: predicate) { [weak self] query, completionHandler, error in
            if let error = error {
                print("Error observing stroke count: \(error.localizedDescription)")
                completionHandler()
                return
            }
            
            let quantityQuery = HKSampleQuery(sampleType: strokeType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                    completionHandler()
                    return
                }
                
                // Вычисляем общее количество гребков за период
                let totalStrokes = samples.reduce(0.0) { result, sample in
                    result + sample.quantity.doubleValue(for: HKUnit.count())
                }
                
                // Если это первые данные, сохраняем как начальные
                if self?.lastStrokeCount == 0 {
                    self?.lastStrokeCount = totalStrokes
                }
                
                // Вычисляем разницу (новые гребки)
                let newStrokes = Int(totalStrokes - (self?.lastStrokeCount ?? 0))
                if newStrokes > 0 {
                    self?.lastStrokeCount = totalStrokes
                    DispatchQueue.main.async {
                        self?.strokeCount += newStrokes
                    }
                }
                
                completionHandler()
            }
            
            self?.healthStore.execute(quantityQuery)
        }
        
        // Запускаем запрос
        healthStore.execute(query)
        strokeCountQuery = query
        
        // Включаем фоновое обновление для получения уведомлений
        healthStore.enableBackgroundDelivery(for: strokeType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery: \(error.localizedDescription)")
            }
        }
    }
    
    func stopMonitoring() {
        // Останавливаем запросы
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
        
        if let query = strokeCountQuery {
            healthStore.stop(query)
            strokeCountQuery = nil
        }
    }
}
