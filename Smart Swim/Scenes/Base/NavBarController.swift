//
//  NavBarController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

final class NavBarController: UINavigationController {
    // MARK: - Constants
    private enum Constants {
        static let tabAndNavBarColor = UIColor(hexString: "#3A3C5D")
        static let titleWhite = UIColor(hexString: "#FFFFFF") ?? .white
        static let NavBarTitle = UIFont.systemFont(ofSize: 20, weight: .semibold)
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    private func configure() {
        view.backgroundColor = Constants.tabAndNavBarColor
        navigationBar.isTranslucent = false
        // Чтобы NavBar не менял цвет при скроле
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Constants.tabAndNavBarColor
        navigationBar.standardAppearance = appearance

        navigationBar.standardAppearance.titleTextAttributes = [
            .foregroundColor: Constants.titleWhite,
            .font: Constants.NavBarTitle
        ]
    }
}
