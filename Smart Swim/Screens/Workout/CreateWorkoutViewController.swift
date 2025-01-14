//
//  CreateWorkoutViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit

final class CreateWorkoutViewController: UIViewController {
    // MARK: - Fields
    private let titleLabel: UILabel = UILabel()
    private let addButton: UIBarButtonItem = UIBarButtonItem()
    private let createButton: UIBarButtonItem = UIBarButtonItem()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - Configurations
    private func configureUI() {
        view.backgroundColor = Resources.Colors.createBackgroundColor
        titleLabel.textColor = Resources.Colors.titleWhite
        titleLabel.text = Resources.Strings.Workout.constructorTitle
        titleLabel.font = Resources.Fonts.constructorTitle
        titleLabel.textAlignment = .center
        
        navigationItem.titleView = titleLabel
        
        configureAddButton()
        configureCreateButton()
    }
    
    private func configureAddButton() {
        addButton.title = Resources.Strings.Workout.addButtonTitle
        addButton.style = .done
        addButton.target = self
        addButton.action = #selector(addButtonTapped)
        
        addButton.tintColor = Resources.Colors.blueColor
        navigationItem.leftBarButtonItem = addButton
    }
    
    private func configureCreateButton() {
        createButton.title = Resources.Strings.Workout.createButtonTitle
        createButton.style = .done
        createButton.target = self
        createButton.action = #selector(createButtonTapped)
        
        createButton.tintColor = Resources.Colors.blueColor
        navigationItem.rightBarButtonItem = createButton
    }
    
    @objc private func addButtonTapped() {
        
    }
    
    @objc private func createButtonTapped() {
        
    }
}
