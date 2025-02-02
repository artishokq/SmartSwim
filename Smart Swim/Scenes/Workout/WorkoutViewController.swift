//
//  ViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.01.2025.
//

import UIKit

protocol WorkoutDisplayLogic: AnyObject {
    func displayWorkoutCreation(viewModel: WorkoutModels.Create.ViewModel)
    func displayInfo(viewModel: WorkoutModels.Info.ViewModel)
    func displayWorkouts(viewModel: WorkoutModels.FetchWorkouts.ViewModel)
}

final class WorkoutViewController: UIViewController, WorkoutDisplayLogic {
    // MARK: - Constants
    private enum Constants {
        static let sectionSpacing: CGFloat = 14
        static let sectionHeaderTopPadding: CGFloat = 0
        
        static let tableViewRightPadding: CGFloat = 16
        static let tableViewLeftPadding: CGFloat = 16
    }
    
    // MARK: - Fields
    private let tableView = UITableView()
    private let createButton: UIButton = UIButton(type: .system)
    private let infoButton: UIButton = UIButton(type: .system)
    
    private var displayedWorkouts: [WorkoutModels.FetchWorkouts.ViewModel.DisplayedWorkout] = []
    
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
        configureTableView()
        fetchWorkouts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchWorkouts()
    }
    
    // MARK: - Configurations
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
    
    private func configureCreateButton() {
        createButton.setImage(Resources.Images.Workout.createButtonImage, for: .normal)
        createButton.tintColor = Resources.Colors.createButtonColor
        
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
    }
    
    private func configureInfoButton() {
        infoButton.setImage(Resources.Images.Workout.infoButtonImage, for: .normal)
        infoButton.tintColor = Resources.Colors.infoButtonColor
        
        infoButton.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
    }
    
    private func configureTableView() {
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(WorkoutCell.self, forCellReuseIdentifier: WorkoutCell.identifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = Constants.sectionHeaderTopPadding
        
        // Констрейнты
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.pinTop(to: view.safeAreaLayoutGuide.topAnchor)
        tableView.pinBottom(to: view.bottomAnchor)
        tableView.pinLeft(to: view.leadingAnchor, Constants.tableViewLeftPadding)
        tableView.pinRight(to: view.trailingAnchor, Constants.tableViewRightPadding)
    }
    
    // MARK: - Actions Configuration
    @objc private func infoButtonTapped() {
        let request = WorkoutModels.Info.Request()
        interactor?.showInfo(request: request)
    }
    
    @objc private func createButtonTapped() {
        let request = WorkoutModels.Create.Request()
        interactor?.createWorkout(request: request)
    }
    
    // MARK: - Display logic
    func displayWorkoutCreation(viewModel: WorkoutModels.Create.ViewModel) {
        router?.routeToWorkoutCreation()
    }
    
    func displayInfo(viewModel: WorkoutModels.Info.ViewModel) {
        router?.routeToInfo()
    }
    
    func displayWorkouts(viewModel: WorkoutModels.FetchWorkouts.ViewModel) {
        displayedWorkouts = viewModel.workouts
        tableView.reloadData()
    }
    
    // MARK: - Private Methods
    private func fetchWorkouts() {
        let request = WorkoutModels.FetchWorkouts.Request()
        interactor?.fetchWorkouts(request: request)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension WorkoutViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return displayedWorkouts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Каждая секция содержит только одну ячейку
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Устанавливаем отступ между секциями
        return Constants.sectionSpacing
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Делаем header прозрачным
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WorkoutCell.identifier, for: indexPath) as? WorkoutCell else {
            return UITableViewCell()
        }
        
        let workout = displayedWorkouts[indexPath.section]
        cell.configure(with: workout)
        
        return cell
    }
}
