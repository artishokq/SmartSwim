//
//  StartEntity.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 19.02.2025.
//
//

import Foundation
import CoreData

@objc(StartEntity)
public class StartEntity: NSManagedObject {

}

extension StartEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StartEntity> {
        return NSFetchRequest<StartEntity>(entityName: "StartEntity")
    }

    @NSManaged public var poolSize: Int16
    @NSManaged public var totalMeters: Int16
    @NSManaged public var swimmingStyle: Int16
    @NSManaged public var date: Date
    @NSManaged public var totalTime: Double
    @NSManaged public var laps: NSSet?
}

extension StartEntity {
    @objc(addLapsObject:)
    @NSManaged public func addToLaps(_ value: LapEntity)

    @objc(removeLapsObject:)
    @NSManaged public func removeFromLaps(_ value: LapEntity)

    @objc(addLaps:)
    @NSManaged public func addToLaps(_ values: NSSet)

    @objc(removeLaps:)
    @NSManaged public func removeFromLaps(_ values: NSSet)
}

extension StartEntity : Identifiable {

}
