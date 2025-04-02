//
//  LapEntity.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 19.02.2025.
//
//

import Foundation
import CoreData

@objc(LapEntity)
public class LapEntity: NSManagedObject {

}

extension LapEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LapEntity> {
        return NSFetchRequest<LapEntity>(entityName: "LapEntity")
    }

    @NSManaged public var lapTime: Double
    @NSManaged public var pulse: Int16
    @NSManaged public var strokes: Int16
    @NSManaged public var lapNumber: Int16
    @NSManaged public var start: StartEntity?
}

extension LapEntity : Identifiable {

}
