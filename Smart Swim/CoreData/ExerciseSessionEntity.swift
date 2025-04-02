//
//  ExerciseSessionEntity+CoreDataClass.swift
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

extension ExerciseSessionEntity : Identifiable {

}
