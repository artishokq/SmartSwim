//
//  DiaryCreateStartViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import UIKit

class DiaryCreateStartViewController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let backgroundColor = UIColor(hexString: "#242531")
        static let titleText = "Создание старта"
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Constants.backgroundColor
        title = Constants.titleText
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
