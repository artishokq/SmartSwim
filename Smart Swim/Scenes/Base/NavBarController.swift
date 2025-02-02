//
//  NavBarController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

final class NavBarController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
    
    private func configure() {
        view.backgroundColor = Resources.Colors.tabAndNavBar
        navigationBar.isTranslucent = false
        // Чтобы NavBar не менял цвет при скроле
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Resources.Colors.tabAndNavBar
        navigationBar.standardAppearance = appearance

        navigationBar.standardAppearance.titleTextAttributes = [
            .foregroundColor: Resources.Colors.titleWhite,
            .font: Resources.Fonts.NavBarTitle
        ]
    }
}
