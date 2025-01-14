//
//  ViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.01.2025.
//

import UIKit

protocol WorkoutDisplayLogic: AnyObject {
    func displayCreateWorkout(viewModel: Workout.Create.ViewModel)
    func displayInfo(viewModel: Workout.Info.ViewModel)
}

final class WorkoutViewController: UIViewController, WorkoutDisplayLogic {
    // MARK: - Fields
    private let createButton: UIButton = UIButton(type: .system)
    private let infoButton: UIButton = UIButton(type: .system)
    
    var interactor: WorkoutBusinessLogic?
    var router: (NSObjectProtocol & WorkoutRoutingLogic & WorkoutDataPassing)?
    
    // MARK: - Object lifecycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - Configurations
    private func configureCreateButton() {
        createButton.setImage(Resources.Images.Workout.createButtonImage, for: .normal)
        createButton.tintColor = Resources.Colors.createButtonColor
        
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
    }
    
    @objc private func createButtonTapped() {
        let request = Workout.Create.Request()
        interactor?.createWorkout(request: request)
    }
    
    private func configureInfoButton() {
        infoButton.setImage(Resources.Images.Workout.infoButtonImage, for: .normal)
        infoButton.tintColor = Resources.Colors.infoButtonColor
        
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
    }
    
    @objc private func infoButtonTapped() {
        let request = Workout.Info.Request()
        interactor?.showInfo(request: request)
    }
    
    private func configure() {
        let viewController = self
        let interactor = WorkoutInteractor()
        let presenter = WorkoutPresenter()
        let router = WorkoutRouter()
        
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    private func configureUI() {
        view.backgroundColor = Resources.Colors.background
        title = Resources.Strings.Workout.workoutTitle
        navigationController?.tabBarItem.title = Resources.Strings.TabBar.workout
        
        configureCreateButton()
        configureInfoButton()
        
        // Add buttons to navigation bar
        let createBarButton = UIBarButtonItem(customView: createButton)
        let infoBarButton = UIBarButtonItem(customView: infoButton)
        
        navigationItem.leftBarButtonItem = createBarButton
        navigationItem.rightBarButtonItem = infoBarButton
    }
    
    // MARK: - Display logic
    func displayCreateWorkout(viewModel: Workout.Create.ViewModel) {
        router?.routeToCreateWorkout()
    }
    
    func displayInfo(viewModel: Workout.Info.ViewModel) {
        router?.routeToInfo()
    }
}
