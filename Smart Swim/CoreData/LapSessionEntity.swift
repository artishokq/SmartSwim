//
//  LapSessionEntity+CoreDataClass.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 24.03.2025.
//
//

import Foundation
import CoreData

@objc(LapSessionEntity)
public class LapSessionEntity: NSManagedObject {

}

extension LapSessionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LapSessionEntity> {
        return NSFetchRequest<LapSessionEntity>(entityName: "LapSessionEntity")
    }

    @NSManaged public var distance: Int16
    @NSManaged public var heartRate: Double
    @NSManaged public var id: UUID?
    @NSManaged public var lapNumber: Int16
    @NSManaged public var lapTime: Double
    @NSManaged public var strokes: Int16
    @NSManaged public var timestamp: Date?
    @NSManaged public var exerciseSession: ExerciseSessionEntity?

}

extension LapSessionEntity : Identifiable {

}
