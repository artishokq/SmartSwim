//
//  WorkoutKitManager.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 29.03.2025.
//

import Foundation
import HealthKit
import Combine

final class WorkoutKitManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    // MARK: - Singleton
    static let shared = WorkoutKitManager()
    
    // MARK: - Publishers
    let heartRatePublisher = PassthroughSubject<Double, Never>()
    let strokeCountPublisher = PassthroughSubject<Int, Never>()
    let caloriesPublisher = PassthroughSubject<Double, Never>()
    let workoutStatePublisher = PassthroughSubject<Bool, Never>()
    let errorPublisher = PassthroughSubject<String, Never>()
    let lapCompletedPublisher = PassthroughSubject<Int, Never>()
    
    // MARK: - Private Properties
    private let healthStore = HKHealthStore()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var processedEventTimestamps = Set<TimeInterval>()
    private var lapCounter: Int = 0
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Public Methods
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
            HKObjectType.workoutType()
        ]
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
    }
    
    func startWorkout(workout: SwimWorkoutModels.SwimWorkout) {
        if workoutSession != nil {
            stopWorkout()
        }
        
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .swimming
        configuration.locationType = .indoor
        configuration.swimmingLocationType = .pool
        configuration.lapLength = HKQuantity(unit: HKUnit.meter(), doubleValue: Double(workout.poolSize))
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                                 workoutConfiguration: configuration)
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { (success, error) in
                if let error = error {
                    self.errorPublisher.send("Ошибка начала сбора данных: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    self.workoutStatePublisher.send(true)
                }
            }
            
        } catch {
            errorPublisher.send("Ошибка создания сессии тренировки: \(error.localizedDescription)")
        }
    }
    
    func stopWorkout() {
        guard let workoutSession = workoutSession else {
            print("stopWorkout: workoutSession уже nil, выходим")
            return
        }
        
        print("stopWorkout: workoutSession существует, продолжаем завершение тренировки")
        
        workoutSession.end()
        workoutBuilder?.endCollection(withEnd: Date()) { [weak self] (success, error) in
            guard let self = self else { return }
            if !success {
                print("stopWorkout: Ошибка завершения сбора данных: \(String(describing: error))")
                self.errorPublisher.send("Ошибка завершения сбора данных: \(String(describing: error))")
                return
            }
            
            self.workoutBuilder?.finishWorkout { (workout, error) in
                if let error = error {
                    print("stopWorkout: Ошибка сохранения тренировки: \(error.localizedDescription)")
                    self.errorPublisher.send("Ошибка сохранения тренировки: \(error.localizedDescription)")
                    return
                }
                
                DispatchQueue.main.async {
                    print("stopWorkout: Завершили тренировку успешно, изменяем состояние")
                    self.workoutStatePublisher.send(false)
                    self.workoutSession = nil
                    self.workoutBuilder = nil
                }
            }
        }
    }
    
    
    // MARK: - HKWorkoutSessionDelegate
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.workoutStatePublisher.send(toState == .running)
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        errorPublisher.send("Ошибка тренировки: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.workoutStatePublisher.send(false)
        }
    }
    
    // MARK: - HKLiveWorkoutBuilderDelegate
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            if quantityType.identifier == HKQuantityTypeIdentifier.heartRate.rawValue {
                let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
                if let value = statistics?.mostRecentQuantity()?.doubleValue(for: heartRateUnit) {
                    DispatchQueue.main.async {
                        self.heartRatePublisher.send(value)
                    }
                }
            }
            else if quantityType.identifier == HKQuantityTypeIdentifier.swimmingStrokeCount.rawValue {
                let strokeUnit = HKUnit.count()
                if let value = statistics?.sumQuantity()?.doubleValue(for: strokeUnit) {
                    let newCount = Int(value)
                    DispatchQueue.main.async {
                        self.strokeCountPublisher.send(newCount)
                    }
                }
            }
            else if quantityType.identifier == HKQuantityTypeIdentifier.activeEnergyBurned.rawValue {
                let calorieUnit = HKUnit.kilocalorie()
                if let value = statistics?.sumQuantity()?.doubleValue(for: calorieUnit) {
                    DispatchQueue.main.async {
                        self.caloriesPublisher.send(value)
                    }
                }
            }
        }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        let workoutEvents = workoutBuilder.workoutEvents
        for event in workoutEvents {
            let eventTimeStamp = event.dateInterval.start.timeIntervalSince1970
            
            if processedEventTimestamps.contains(eventTimeStamp) {
                continue
            }
            
            if event.type == .lap {
                self.lapCounter += 1
                
                DispatchQueue.main.async {
                    self.lapCompletedPublisher.send(self.lapCounter)
                }
            }
            
            processedEventTimestamps.insert(eventTimeStamp)
        }
    }
}
