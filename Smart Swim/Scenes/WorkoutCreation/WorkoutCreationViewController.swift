//
//  WorkoutCreationViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit

protocol WorkoutCreationDisplayLogic: AnyObject {
    func displayCreateWorkout(viewModel: WorkoutCreationModels.CreateWorkout.ViewModel)
    func displayAddExercise(viewModel: WorkoutCreationModels.AddExercise.ViewModel)
    func displayDeleteExercise(viewModel: WorkoutCreationModels.DeleteExercise.ViewModel)
    func displayUpdateExercise(viewModel: WorkoutCreationModels.UpdateExercise.ViewModel)
}

final class WorkoutCreationViewController: UIViewController, WorkoutCreationDisplayLogic {
    // MARK: - Constants
    private enum Constants {
        static let tableViewLeftPadding: CGFloat = 14
        static let tableViewRightPadding: CGFloat = 14
        
        static let sectionSpacing: CGFloat = 14
        static let sectionHeaderTopPadding: CGFloat = 0
        
        static let alertTitle: String = "Ошибка"
        static let alertDefaultMessage: String = "Не удалось создать тренировку."
    }
    
    // MARK: - Fields
    var interactor: WorkoutCreationBusinessLogic?
    var router: WorkoutCreationRoutingLogic?
    
    private var exercises: [Exercise] = []
    private var workoutName: String?
    private var poolSize: PoolSize?
    
    private let titleLabel: UILabel = UILabel()
    private let addButton: UIBarButtonItem = UIBarButtonItem()
    private let createButton: UIBarButtonItem = UIBarButtonItem()
    private let tableView: UITableView = UITableView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        configureUI()
    }
    
    // MARK: - Configurations
    private func configure() {
        let interactor = WorkoutCreationInteractor()
        let presenter = WorkoutCreationPresenter()
        let router = WorkoutCreationRouter()
        
        interactor.presenter = presenter
        presenter.viewController = self
        router.viewController = self
        
        self.interactor = interactor
        self.router = router
    }
    
    private func configureUI() {
        view.backgroundColor = Resources.Colors.createBackgroundColor
        titleLabel.textColor = Resources.Colors.titleWhite
        titleLabel.text = Resources.Strings.Workout.constructorTitle
        titleLabel.font = Resources.Fonts.constructorTitle
        titleLabel.textAlignment = .center
        
        navigationItem.titleView = titleLabel
        
        configureTableView()
        configureAddButton()
        configureCreateButton()
    }
    
    private func configureTableView() {
        tableView.backgroundColor = Resources.Colors.createBackgroundColor
        tableView.frame = .zero
        tableView.register(HeaderCell.self, forCellReuseIdentifier: HeaderCell.identifier)
        tableView.register(ExerciseCell.self, forCellReuseIdentifier: ExerciseCell.identifier)
        tableView.sectionHeaderTopPadding = Constants.sectionHeaderTopPadding
        
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.pinTop(to: view.safeAreaLayoutGuide.topAnchor)
        tableView.pinBottom(to: view.bottomAnchor)
        tableView.pinLeft(to: view.leadingAnchor, Constants.tableViewLeftPadding)
        tableView.pinRight(to: view.trailingAnchor, Constants.tableViewRightPadding)
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let newExercise = Exercise(
            type: .warmup,
            meters: 0,
            repetitions: 0,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: ""
        )
        let request = WorkoutCreationModels.AddExercise.Request(exercise: newExercise)
        interactor?.addExercise(request: request)
    }
    
    // MARK: - Actions
    @objc private func createButtonTapped() {
        // Передаем данные в Interactor
        let request = WorkoutCreationModels.CreateWorkout.Request(
            name: workoutName ?? "",
            poolSize: poolSize ?? .poolSize25,
            exercises: exercises
        )
        interactor?.createWorkout(request: request)
    }
    
    // MARK: - Display Logic
    func displayCreateWorkout(viewModel: WorkoutCreationModels.CreateWorkout.ViewModel) {
        if viewModel.success {
            // Отправляем уведомление о создании тренировки
            NotificationCenter.default.post(name: .workoutCreated, object: nil)
            // После уведомления переходим к списку тренировок (главный экран)
            router?.routeToWorkoutList()
        } else {
            showAlert(title: Constants.alertTitle, message: viewModel.errorMessage ?? Constants.alertDefaultMessage)
        }
    }
    
    func displayAddExercise(viewModel: WorkoutCreationModels.AddExercise.ViewModel) {
        exercises = viewModel.exercises
        tableView.reloadData()
    }
    
    func displayDeleteExercise(viewModel: WorkoutCreationModels.DeleteExercise.ViewModel) {
        exercises = viewModel.exercises
        tableView.reloadData()
    }
    
    func displayUpdateExercise(viewModel: WorkoutCreationModels.UpdateExercise.ViewModel) {
        exercises = viewModel.exercises
        tableView.reloadData()
    }
}

// MARK: - TableView DataSource & Delegate
extension WorkoutCreationViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return exercises.count + 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Каждая секция содержит только одну ячейку
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Устанавливаем отступ между секциями
        return section == 0 ? 0 : Constants.sectionSpacing
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Делаем header прозрачным
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HeaderCell.identifier,
                for: indexPath) as! HeaderCell
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: ExerciseCell.identifier,
                for: indexPath) as! ExerciseCell
            cell.configure(with: exercises[indexPath.section - 1], number: indexPath.section, indexPath: indexPath)
            cell.delegate = self
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let request = WorkoutCreationModels.DeleteExercise.Request(index: indexPath.section - 1)
            interactor?.deleteExercise(request: request)
        }
    }
}

// MARK: - HeaderCell Delegate
extension WorkoutCreationViewController: HeaderCellDelegate {
    func headerCell(_ cell: HeaderCell, didUpdateName name: String) {
        workoutName = name
    }
    
    func headerCell(_ cell: HeaderCell, didSelectPoolSize poolSize: PoolSize) {
        self.poolSize = poolSize
    }
}

// MARK: - ExerciseCellDelegate
extension WorkoutCreationViewController: ExerciseCellDelegate {
    func exerciseCell(_ cell: ExerciseCell, didRequestDeletionAt indexPath: IndexPath) {
        let request = WorkoutCreationModels.DeleteExercise.Request(index: indexPath.section - 1)
        interactor?.deleteExercise(request: request)
    }
    
    func exerciseCell(_ cell: ExerciseCell, didUpdate exercise: Exercise) {
        if let indexPath = tableView.indexPath(for: cell) {
            let request = WorkoutCreationModels.UpdateExercise.Request(
                exercise: exercise,
                index: indexPath.section - 1
            )
            interactor?.updateExercise(request: request)
        }
    }
}
