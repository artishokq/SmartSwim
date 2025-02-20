//
//  WatchSessionManager.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    
    private override init() { super.init() }
    
    func startSession() {
        if WCSession.default.isReachable {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendDataToWatch(data: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil) { error in
                print("Error sending message to Watch: \(error.localizedDescription)")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
}
