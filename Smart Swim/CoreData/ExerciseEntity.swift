//
//  ExerciseEntity.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 21.01.2025.
//
//

import Foundation
import CoreData

@objc(ExerciseEntity)
public class ExerciseEntity: NSManagedObject {

}

extension ExerciseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExerciseEntity> {
        return NSFetchRequest<ExerciseEntity>(entityName: "ExerciseEntity")
    }

    @NSManaged public var exerciseDescription: String?
    @NSManaged public var hasInterval: Bool
    @NSManaged public var intervalMinutes: Int16
    @NSManaged public var intervalSeconds: Int16
    @NSManaged public var meters: Int16
    @NSManaged public var orderIndex: Int16
    @NSManaged public var repetitions: Int16
    @NSManaged public var style: Int16
    @NSManaged public var type: Int16
    @NSManaged public var workout: WorkoutEntity?
}

extension ExerciseEntity : Identifiable {

}
