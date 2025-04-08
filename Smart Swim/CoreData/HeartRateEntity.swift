//
//  HeartRateEntity.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 08.04.2025.
//
//

import Foundation
import CoreData

@objc(HeartRateEntity)
public class HeartRateEntity: NSManagedObject {
    
}

extension HeartRateEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<HeartRateEntity> {
        return NSFetchRequest<HeartRateEntity>(entityName: "HeartRateEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var value: Double
    @NSManaged public var exerciseSession: ExerciseSessionEntity?
    
}

extension HeartRateEntity : Identifiable {
    
}
