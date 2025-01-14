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
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configure() {
        tabBar.tintColor = Resources.Colors.active
        tabBar.barTintColor = Resources.Colors.inactive
        tabBar.backgroundColor = Resources.Colors.tabAndNavBar
        tabBar.layer.masksToBounds = true
        
        let workoutController = WorkoutViewController()
        let startController = StartController()
        let diaryController = DiaryController()
        
        let workoutNavigation = NavBarController(rootViewController: workoutController)
        let startNavigation = NavBarController(rootViewController: startController)
        let diaryNavigation = NavBarController(rootViewController: diaryController)
        
        startNavigation.tabBarItem = UITabBarItem(title: Resources.Strings.TabBar.start,
                                                  image: Resources.Images.TabBar.start,
                                                  tag: Tabs.start.rawValue)
        
        workoutNavigation.tabBarItem = UITabBarItem(title: Resources.Strings.TabBar.workout,
                                                    image: Resources.Images.TabBar.workout,
                                                    tag: Tabs.workout.rawValue)
        
        diaryNavigation.tabBarItem = UITabBarItem(title: Resources.Strings.TabBar.diary,
                                                  image: Resources.Images.TabBar.diary,
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
