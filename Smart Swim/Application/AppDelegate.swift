//
//  AppDelegate.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.01.2025.
//

import UIKit
import CoreData
import YandexMapsMobile

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        WatchSessionManager.shared.activateSessionAndSendWorkouts()
        
        let apiKey: String = {
            if let key = Bundle.main.object(forInfoDictionaryKey: "YANDEX_API_KEY") as? String, !key.isEmpty {
                return key
            }
            print("YANDEX_API_KEY не задан в Info.plist")
            return ""
        }()
        
        YMKMapKit.setApiKey(apiKey)
        let _ = YMKMapKit.sharedInstance()
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        
    }
}
