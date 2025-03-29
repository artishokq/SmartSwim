//
//  WorkoutSessionEntity+CoreDataClass.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 24.03.2025.
//
//

import Foundation
import CoreData

@objc(WorkoutSessionEntity)
public class WorkoutSessionEntity: NSManagedObject {

}

extension WorkoutSessionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkoutSessionEntity> {
        return NSFetchRequest<WorkoutSessionEntity>(entityName: "WorkoutSessionEntity")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var poolSize: Int16
    @NSManaged public var totalCalories: Double
    @NSManaged public var totalTime: Double
    @NSManaged public var workoutName: String?
    @NSManaged public var workoutOriginalId: String?
    @NSManaged public var exerciseSessions: NSSet?

}

// MARK: Generated accessors for exerciseSessions
extension WorkoutSessionEntity {

    @objc(addExerciseSessionsObject:)
    @NSManaged public func addToExerciseSessions(_ value: ExerciseSessionEntity)

    @objc(removeExerciseSessionsObject:)
    @NSManaged public func removeFromExerciseSessions(_ value: ExerciseSessionEntity)

    @objc(addExerciseSessions:)
    @NSManaged public func addToExerciseSessions(_ values: NSSet)

    @objc(removeExerciseSessions:)
    @NSManaged public func removeFromExerciseSessions(_ values: NSSet)

}

extension WorkoutSessionEntity : Identifiable {

}
