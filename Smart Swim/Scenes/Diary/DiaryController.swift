//
//  DiaryController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

final class DiaryController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let backgroundColor = UIColor(hexString: "#242531")
        static let diaryTabBarTitle: String = "Дневник"
        static let diaryTitle: String = "Дневник"
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.backgroundColor
        title = Constants.diaryTitle
        navigationController?.tabBarItem.title = Constants.diaryTabBarTitle
    }
}
