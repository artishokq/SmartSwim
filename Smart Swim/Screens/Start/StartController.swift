//
//  StartController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

final class StartController: BaseController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Контрольный старт"
        navigationController?.tabBarItem.title = Resources.Strings.TabBar.start
    }
}
