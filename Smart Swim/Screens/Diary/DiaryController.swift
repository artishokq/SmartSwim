//
//  DiaryController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

final class DiaryController: BaseController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Дневник"
        navigationController?.tabBarItem.title = Resources.Strings.TabBar.diary
    }
}
