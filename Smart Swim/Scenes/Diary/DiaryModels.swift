//
//  DiaryModels.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import UIKit
import CoreData

enum DiaryModels {
    enum FetchStarts {
        struct Request {
            
        }
        
        struct Response {
            struct StartData {
                let id: NSManagedObjectID
                let date: Date
                let totalMeters: Int16
                let swimmingStyle: Int16
                let totalTime: Double
            }
            
            let starts: [StartData]
        }
        
        struct ViewModel {
            struct DisplayedStart {
                let id: NSManagedObjectID
                let dateString: String
                let metersString: String
                let styleString: String
                let timeString: String
            }
            
            let starts: [DisplayedStart]
        }
    }
    
    enum DeleteStart {
        struct Request {
            let id: NSManagedObjectID
            let index: Int
        }
        
        struct Response {
            let index: Int
        }
        
        struct ViewModel {
            let index: Int
        }
    }
    
    enum ShowStartDetail {
        struct Request {
            let startID: NSManagedObjectID
        }
        
        struct Response {
            let startID: NSManagedObjectID
        }
        
        struct ViewModel {
            let startID: NSManagedObjectID
        }
    }
    
    enum CreateStart {
        struct Request {
            
        }
        
        struct Response {
            
        }
        
        struct ViewModel {
            
        }
    }
}
