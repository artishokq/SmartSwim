//
//  WatchSessionManager.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import WatchConnectivity
import SwiftUI

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    
    private override init() { super.init() }
    
    func startSession() {
        if WCSession.default.isReachable {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let pulse = message["pulse"] as? Int {
            
        }
        
        if let strokes = message["strokes"] as? Int {
            
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        
    }
}
