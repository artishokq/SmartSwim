//
//  InfoViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit

final class InfoViewController: UIViewController {
    // MARK: - Fields
    private let titleLabel: UILabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    // MARK: - Configurations
    private func configureUI() {
        view.backgroundColor = Resources.Colors.infoBackgroundColor
        
        titleLabel.textColor = Resources.Colors.titleWhite
        titleLabel.textAlignment = .center
        titleLabel.font = Resources.Fonts.infoTitle
        titleLabel.text = Resources.Strings.Workout.infoTitle
        navigationItem.titleView = titleLabel
    }
}
