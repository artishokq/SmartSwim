//
//  InfoViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit

final class InfoViewController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let infoTitle = "Информация"
        static let infoTitleFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let infoBackgroundColor = UIColor(hexString: "#242531")
        static let titleWhite = UIColor(hexString: "#FFFFFF") ?? .white
    }
    
    // MARK: - Fields
    private let titleLabel: UILabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    // MARK: - Configurations
    private func configureUI() {
        view.backgroundColor = Constants.infoBackgroundColor
        
        titleLabel.textColor = Constants.titleWhite
        titleLabel.textAlignment = .center
        titleLabel.font = Constants.infoTitleFont
        titleLabel.text = Constants.infoTitle
        navigationItem.titleView = titleLabel
    }
}
