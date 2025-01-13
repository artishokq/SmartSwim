//
//  ViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.01.2025.
//

import UIKit

final class WorkoutController: BaseController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Конструктор тренировок"
        navigationController?.tabBarItem.title = Resources.Strings.TabBar.workout
    }
}
