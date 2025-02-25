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
    @objc(addLapsDataObject:)
    @NSManaged public func addToLapsData(_ value: LapEntity)

    @objc(removeLapsDataObject:)
    @NSManaged public func removeFromLapsData(_ value: LapEntity)

    @objc(addLapsData:)
    @NSManaged public func addToLapsData(_ values: NSSet)

    @objc(removeLapsData:)
    @NSManaged public func removeFromLapsData(_ values: NSSet)
}

extension StartEntity : Identifiable {

}
