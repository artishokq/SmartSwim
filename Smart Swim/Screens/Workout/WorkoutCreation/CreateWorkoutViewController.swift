//
//  CreateWorkoutViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit

final class CreateWorkoutViewController: UIViewController {
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
        
        tableView.delegate = self
        tableView.dataSource = self
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.pinTop(to: view.safeAreaLayoutGuide.topAnchor)
        tableView.pinBottom(to: view.bottomAnchor)
        tableView.pinLeft(to: view.leadingAnchor, 9)
        tableView.pinRight(to: view.trailingAnchor, 9)
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
        
        let indexPath = IndexPath(row: exercises.count - 1, section: 1)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }
    
    @objc private func createButtonTapped() {
        guard let workoutName = workout?.name, !workoutName.isEmpty else {
            // Show error - name required
            let alert = UIAlertController(
                title: "Ошибка",
                message: "Введите название тренировки",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Save workout using WorkoutStorage
        if let workout = workout {
            WorkoutStorage.shared.saveWorkout(workout)
            dismiss(animated: true)
        }
        
    }
}

// MARK: - TableView DataSource & Delegate
extension CreateWorkoutViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // Header section and Exercises section
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        return exercises.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: HeaderCell.identifier, for: indexPath) as! HeaderCell
            cell.delegate = self
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: ExerciseCell.identifier, for: indexPath) as! ExerciseCell
            cell.configure(with: exercises[indexPath.row])
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
    func exerciseCell(_ cell: ExerciseCell, didUpdate exercise: Exercise) {
        if let indexPath = tableView.indexPath(for: cell) {
            exercises[indexPath.row] = exercise
            workout?.exercises = exercises
        }
    }
}
