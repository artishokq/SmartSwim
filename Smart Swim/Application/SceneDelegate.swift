//
//  SceneDelegate.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.01.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let tabBarController = TabBarController(nibName: nil, bundle: nil)
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Создаётся новое окно с рамками, соответствующими координатному пространству
        window = UIWindow(frame: windowScene.coordinateSpace.bounds)
        // Связывает созданное окно с конкретной сценой (UIWindowScene), что необходимо для правильного отображения окна на экране
        window?.windowScene = windowScene
        // Устанавливается корневой контроллер окна – в данном случае это UITabBarController
        window?.rootViewController = tabBarController
        // Это метод, который делает окно основным (ключевым) и видимым на экране
        window?.makeKeyAndVisible()
    }
}
