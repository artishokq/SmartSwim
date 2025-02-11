//
//  TabBarController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 12.01.2025.
//

import UIKit

enum Tabs: Int {
    case workout
    case start
    case diary
}

final class TabBarController: UITabBarController {
    // MARK: - Constants
    private enum Constants {
        static let diaryImage = UIImage(named: "diaryTab")
        static let startImage = UIImage(named: "startTab")
        static let workoutImage = UIImage(named: "workoutTab")
        
        static let startTitle = "Старт"
        static let workoutTitle = "Тренировка"
        static let diaryTitle = "Дневник"
        
        static let activeColor = UIColor(hexString: "#93DBFA")
        static let inactiveColor = UIColor(hexString: "#B7C4E6")
        static let tabAndNavBarColor = UIColor(hexString: "#3A3C5D")
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configuration
    private func configure() {
        tabBar.tintColor = Constants.activeColor
        tabBar.barTintColor = Constants.inactiveColor
        tabBar.isTranslucent = false
        tabBar.backgroundColor = Constants.tabAndNavBarColor
        tabBar.layer.masksToBounds = true
        // Чтобы TabBar не менял цвет при скроле
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Constants.tabAndNavBarColor
        tabBar.standardAppearance = appearance
        
        let workoutController = WorkoutViewController()
        let startController = StartViewController()
        let diaryController = DiaryController()
        
        let workoutNavigation = NavBarController(rootViewController: workoutController)
        let startNavigation = NavBarController(rootViewController: startController)
        let diaryNavigation = NavBarController(rootViewController: diaryController)
        
        startNavigation.tabBarItem = UITabBarItem(title: Constants.startTitle,
                                                  image: Constants.startImage,
                                                  tag: Tabs.start.rawValue)
        
        workoutNavigation.tabBarItem = UITabBarItem(title: Constants.workoutTitle,
                                                    image: Constants.workoutImage,
                                                    tag: Tabs.workout.rawValue)
        
        diaryNavigation.tabBarItem = UITabBarItem(title: Constants.diaryTitle,
                                                  image: Constants.diaryImage,
                                                  tag: Tabs.diary.rawValue)
        
        startNavigation.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
        workoutNavigation.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
        diaryNavigation.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 0)
        
        setViewControllers([
            startNavigation,
            workoutNavigation,
            diaryNavigation
        ], animated: false)
    }
}
