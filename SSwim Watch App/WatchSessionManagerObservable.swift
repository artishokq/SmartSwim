//
//  WatchSessionManagerObservable.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import WatchConnectivity
import SwiftUI
import Combine

class WatchSessionManagerObservable: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchSessionManagerObservable()
    
    @Published var commandFromPhone: String = ""
    @Published var isConnectedToPhone: Bool = false
    
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
    
    func sendMessageToPhone(message: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message to phone: \(error.localizedDescription)")
            }
        } else {
            print("Phone is not reachable")
        }
    }
    
    func sendHeartRateToPhone(heartRate: Int) {
        sendMessageToPhone(message: ["heartRate": heartRate])
    }
    
    func sendStrokeCountToPhone(strokeCount: Int) {
        sendMessageToPhone(message: ["strokeCount": strokeCount])
    }
    
    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnectedToPhone = activationState == .activated
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let command = message["command"] as? String {
                self.commandFromPhone = command
            }
        }
    }
}
