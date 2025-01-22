//
//  StartController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

final class StartController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Resources.Colors.background
        
        title = "Контрольный старт"
        navigationController?.tabBarItem.title = Resources.Strings.TabBar.start
    }
}
