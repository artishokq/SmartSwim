//
//  CreateWorkoutViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit

final class CreateWorkoutViewController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let tableViewLeftPadding: CGFloat = 14
        static let tableViewRightPadding: CGFloat = 14
        
        static let sectionSpacing: CGFloat = 14
        
        static let createButtonAlertTitle: String = "Ошибка"
        static let createButtonAlertMessage: String = "Введите название тренировки"
    }
    
    // MARK: - Fields
    private var workout: Workout?
    private var exercises: [Exercise] = []
    
    private let titleLabel: UILabel = UILabel()
    private let addButton: UIBarButtonItem = UIBarButtonItem()
    private let createButton: UIBarButtonItem = UIBarButtonItem()
    private let tableView: UITableView = UITableView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        workout = Workout(
            name: "",
            poolSize: .poolSize25,
            exercises: []
        )
        
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
        
        configureTableView()
        configureAddButton()
        configureCreateButton()
    }
    
    private func configureTableView() {
        tableView.backgroundColor = Resources.Colors.createBackgroundColor
        tableView.frame = .zero
        tableView.register(HeaderCell.self, forCellReuseIdentifier: HeaderCell.identifier)
        tableView.register(ExerciseCell.self, forCellReuseIdentifier: ExerciseCell.identifier)
        tableView.sectionHeaderTopPadding = 0
        
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
    
    // MARK: - Actions
    @objc private func addButtonTapped() {
        let newExercise = Exercise(
            type: .warmup,
            meters: nil,
            repetitions: nil,
            hasInterval: false,
            intervalMinutes: nil,
            intervalSeconds: nil,
            style: .freestyle,
            description: ""
        )
        exercises.append(newExercise)
        
        tableView.insertSections(IndexSet(integer: exercises.count), with: .automatic)
    }
    
    @objc private func createButtonTapped() {
        guard let workoutName = workout?.name, !workoutName.isEmpty else {
            let alert = UIAlertController(
                title: Constants.createButtonAlertTitle,
                message: Constants.createButtonAlertMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        if let workout = workout {
            // Вызываем метод создания тренировки в CoreData
            CoreDataManager.shared.createWorkout(
                name: workout.name,
                poolSize: Int16(workout.poolSize.rawValue),
                exercises: workout.exercises  // <-- Массив Exercise
            )
            
            // Закрываем экран
            dismiss(animated: true)
        }
    }
}

// MARK: - TableView DataSource & Delegate
extension CreateWorkoutViewController: UITableViewDataSource, UITableViewDelegate {
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
            cell.configure(with: exercises[indexPath.section - 1], number: indexPath.section)
            cell.delegate = self
            return cell
        }
    }
}

// MARK: - HeaderCell Delegate
extension CreateWorkoutViewController: HeaderCellDelegate {
    func headerCell(_ cell: HeaderCell, didUpdateName name: String) {
        workout?.name = name
    }
    
    func headerCell(_ cell: HeaderCell, didSelectPoolSize poolSize: PoolSize) {
        workout?.poolSize = poolSize
    }
}

// MARK: - ExerciseCell Delegate
extension CreateWorkoutViewController: ExerciseCellDelegate {
    func exerciseCell(_ cell: ExerciseCell, didRequestDeletionAt indexPath: IndexPath) {
        // Удаляем из массива данных
        exercises.remove(at: indexPath.section - 1)
        
        // Удаляем секцию из таблицы
        tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
        
        // Обновляем нумерацию оставшихся ячеек
        // Начинаем с секции, где было удаление, и идем до последнего упражнения
        if indexPath.section <= exercises.count {
            for section in indexPath.section...exercises.count {
                if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: section)) as? ExerciseCell {
                    cell.configure(with: exercises[section - 1], number: section)
                }
            }
        }
        
        // Обновляем данные тренировки
        workout?.exercises = exercises
    }
    
    func exerciseCell(_ cell: ExerciseCell, didUpdate exercise: Exercise) {
        if let indexPath = tableView.indexPath(for: cell) {
            exercises[indexPath.section - 1] = exercise
            workout?.exercises = exercises
        }
    }
}
