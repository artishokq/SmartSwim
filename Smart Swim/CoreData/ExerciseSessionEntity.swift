//
//  ExerciseSessionEntity.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 24.03.2025.
//
//

import Foundation
import CoreData

@objc(ExerciseSessionEntity)
public class ExerciseSessionEntity: NSManagedObject {

}

extension ExerciseSessionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseSessionEntity> {
        return NSFetchRequest<ExerciseSessionEntity>(entityName: "ExerciseSessionEntity")
    }

    @NSManaged public var endTime: Date?
    @NSManaged public var exerciseDescription: String?
    @NSManaged public var exerciseOriginalId: String?
    @NSManaged public var hasInterval: Bool
    @NSManaged public var id: UUID?
    @NSManaged public var intervalMinutes: Int16
    @NSManaged public var intervalSeconds: Int16
    @NSManaged public var meters: Int16
    @NSManaged public var orderIndex: Int16
    @NSManaged public var repetitions: Int16
    @NSManaged public var startTime: Date?
    @NSManaged public var style: Int16
    @NSManaged public var type: Int16
    @NSManaged public var laps: NSSet?
    @NSManaged public var workoutSession: WorkoutSessionEntity?
    @NSManaged public var heartRateReadings: NSSet?

    var heartRates: [Double] {
        return (heartRateReadings?.allObjects as? [HeartRateEntity])?.map { $0.value } ?? []
    }
    
    var averageHeartRate: Double {
        let rates = heartRates.filter { $0 > 0 }
        return rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
    }
    
    var minHeartRate: Double {
        return heartRates.filter { $0 > 0 }.min() ?? 0
    }
    
    var maxHeartRate: Double {
        return heartRates.max() ?? 0
    }
    
    var heartRatesWithTimestamps: [(timestamp: Date, value: Double)] {
        return (heartRateReadings?.allObjects as? [HeartRateEntity])?
            .compactMap { entity in
                if let timestamp = entity.timestamp {
                    return (timestamp: timestamp, value: entity.value)
                }
                return nil
            }
            .sorted { $0.timestamp < $1.timestamp } ?? []
    }
}

// MARK: Generated accessors for laps
extension ExerciseSessionEntity {

    @objc(addLapsObject:)
    @NSManaged public func addToLaps(_ value: LapSessionEntity)

    @objc(removeLapsObject:)
    @NSManaged public func removeFromLaps(_ value: LapSessionEntity)

    @objc(addLaps:)
    @NSManaged public func addToLaps(_ values: NSSet)

    @objc(removeLaps:)
    @NSManaged public func removeFromLaps(_ values: NSSet)

}

// MARK: Generated accessors for heartRateReadings
extension ExerciseSessionEntity {

    @objc(addHeartRateReadingsObject:)
    @NSManaged public func addToHeartRateReadings(_ value: HeartRateEntity)

    @objc(removeHeartRateReadingsObject:)
    @NSManaged public func removeFromHeartRateReadings(_ value: HeartRateEntity)

    @objc(addHeartRateReadings:)
    @NSManaged public func addToHeartRateReadings(_ values: NSSet)

    @objc(removeHeartRateReadings:)
    @NSManaged public func removeFromHeartRateReadings(_ values: NSSet)

}

extension ExerciseSessionEntity : Identifiable {

}
