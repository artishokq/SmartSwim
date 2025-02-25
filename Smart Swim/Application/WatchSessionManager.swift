//
//  WatchSessionManager.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import WatchConnectivity
import Foundation

protocol WatchDataDelegate: AnyObject {
    func didReceiveHeartRate(_ pulse: Int)
    func didReceiveStrokeCount(_ strokes: Int)
    func didReceiveWatchStatus(_ status: String)
}

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    
    weak var delegate: WatchDataDelegate?
    
    private var isSessionActive = false
    
    private override init() {
        super.init()
        startSession()
    }
    
    func startSession() {
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendCommandToWatch(_ command: String) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["command": command], replyHandler: nil) { error in
                print("Error sending command to Watch: \(error.localizedDescription)")
            }
        } else {
            print("Watch is not reachable")
        }
    }
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isSessionActive = activationState == .activated
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let heartRate = message["heartRate"] as? Int {
                self.delegate?.didReceiveHeartRate(heartRate)
            }
            
            if let strokeCount = message["strokeCount"] as? Int {
                self.delegate?.didReceiveStrokeCount(strokeCount)
            }
            
            if let watchStatus = message["watchStatus"] as? String {
                self.delegate?.didReceiveWatchStatus(watchStatus)
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        isSessionActive = false
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        isSessionActive = false
        // Reactivate session if needed
        WCSession.default.activate()
    }
}
