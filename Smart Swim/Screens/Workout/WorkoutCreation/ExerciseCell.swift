//
//  ExerciseCell.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 15.01.2025.
//

import UIKit

// ExerciseCell.swift
protocol ExerciseCellDelegate: AnyObject {
    func exerciseCell(_ cell: ExerciseCell, didUpdate exercise: Exercise)
}

final class ExerciseCell: UITableViewCell {
    // MARK: - Constants
    private enum Constants {
        static let cellCornerRadius: CGFloat = 12
    }
    
    // MARK: - Fields
    static let identifier = "ExerciseCell"
    weak var delegate: ExerciseCellDelegate?
    private var exercise: Exercise?
    
    private let typeSegmentControl: UISegmentedControl = UISegmentedControl()
    private let metersTextField: UITextField = UITextField()
    private let repsTextField: UITextField = UITextField()
    private let intervalLabel: UILabel = UILabel()
    private let hasIntervalSwitch: UISwitch = UISwitch()
    private let intervalStackView: UIStackView = UIStackView()
    private let minutesTextField: UITextField = UITextField()
    private let secondsTextField: UITextField = UITextField()
    private let styleSegmentControl: UISegmentedControl = UISegmentedControl()
    private let descriptionTextField: UITextField = UITextField()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configurations
    private func configureUI() {
        backgroundColor = Resources.Colors.createCellBackgroundColor
        selectionStyle = .none
        layer.cornerRadius = Constants.cellCornerRadius
        
        typeSegmentControlConfiguration()
        metersTextFieldConfiguration()
        repsTextFieldConfiguration()
        intervalLabelConfiguration()
        hasIntervalSwitchConfiguration()
        intervalStackViewConfiguration()
        minutesTextFieldConfiguration()
        secondsTextFieldConfiguration()
        styleSegmentControlConfiguration()
        descriptionTextFieldConfiguration()
        
        addSubviews()
        setupConstraints()
    }
    
    private func typeSegmentControlConfiguration() {
        let items = ["Разминка", "Основное", "Заминка"]
        typeSegmentControl.removeAllSegments()
        for (index, title) in items.enumerated() {
            typeSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        typeSegmentControl.selectedSegmentIndex = 0
        typeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func metersTextFieldConfiguration() {
        metersTextField.placeholder = "Метры"
        metersTextField.borderStyle = .roundedRect
        metersTextField.keyboardType = .numberPad
        metersTextField.backgroundColor = .white
        metersTextField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func repsTextFieldConfiguration() {
        repsTextField.placeholder = "Повторения"
        repsTextField.borderStyle = .roundedRect
        repsTextField.keyboardType = .numberPad
        repsTextField.backgroundColor = .white
        repsTextField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func intervalLabelConfiguration() {
        intervalLabel.text = "Режим"
        intervalLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func hasIntervalSwitchConfiguration() {
        hasIntervalSwitch.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func intervalStackViewConfiguration() {
        intervalStackView.axis = .horizontal
        intervalStackView.spacing = 8
        intervalStackView.distribution = .fillEqually
        intervalStackView.isHidden = true
        intervalStackView.translatesAutoresizingMaskIntoConstraints = false
        
        intervalStackView.addArrangedSubview(minutesTextField)
        intervalStackView.addArrangedSubview(secondsTextField)
    }
    
    private func minutesTextFieldConfiguration() {
        minutesTextField.placeholder = "Мин"
        minutesTextField.borderStyle = .roundedRect
        minutesTextField.keyboardType = .numberPad
        minutesTextField.backgroundColor = .white
    }
    
    private func secondsTextFieldConfiguration() {
        secondsTextField.placeholder = "Сек"
        secondsTextField.borderStyle = .roundedRect
        secondsTextField.keyboardType = .numberPad
        secondsTextField.backgroundColor = .white
    }
    
    private func styleSegmentControlConfiguration() {
        let items = ["Кроль", "Брасс", "Спина", "Батт", "Компл"]
        styleSegmentControl.removeAllSegments()
        for (index, title) in items.enumerated() {
            styleSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        styleSegmentControl.selectedSegmentIndex = 0
        styleSegmentControl.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func descriptionTextFieldConfiguration() {
        descriptionTextField.placeholder = "Описание"
        descriptionTextField.borderStyle = .roundedRect
        descriptionTextField.backgroundColor = .white
        descriptionTextField.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func addSubviews() {
        contentView.addSubview(typeSegmentControl)
        contentView.addSubview(metersTextField)
        contentView.addSubview(repsTextField)
        contentView.addSubview(intervalLabel)
        contentView.addSubview(hasIntervalSwitch)
        contentView.addSubview(intervalStackView)
        contentView.addSubview(styleSegmentControl)
        contentView.addSubview(descriptionTextField)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Тип упражнения
            typeSegmentControl.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            typeSegmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            typeSegmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Метры
            metersTextField.topAnchor.constraint(equalTo: typeSegmentControl.bottomAnchor, constant: 16),
            metersTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            metersTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            
            // Повторения
            repsTextField.topAnchor.constraint(equalTo: typeSegmentControl.bottomAnchor, constant: 16),
            repsTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            repsTextField.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.45),
            
            // Режим - label и switch
            intervalLabel.topAnchor.constraint(equalTo: metersTextField.bottomAnchor, constant: 16),
            intervalLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            hasIntervalSwitch.centerYAnchor.constraint(equalTo: intervalLabel.centerYAnchor),
            hasIntervalSwitch.leadingAnchor.constraint(equalTo: intervalLabel.trailingAnchor, constant: 8),
            
            // Stack view для интервала
            intervalStackView.topAnchor.constraint(equalTo: intervalLabel.bottomAnchor, constant: 8),
            intervalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            intervalStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Стиль плавания
            styleSegmentControl.topAnchor.constraint(equalTo: intervalStackView.bottomAnchor, constant: 16),
            styleSegmentControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            styleSegmentControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            // Описание
            descriptionTextField.topAnchor.constraint(equalTo: styleSegmentControl.bottomAnchor, constant: 16),
            descriptionTextField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionTextField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionTextField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        typeSegmentControl.addTarget(self, action: #selector(updateExercise), for: .valueChanged)
        metersTextField.addTarget(self, action: #selector(updateExercise), for: .editingChanged)
        repsTextField.addTarget(self, action: #selector(updateExercise), for: .editingChanged)
        hasIntervalSwitch.addTarget(self, action: #selector(intervalSwitchChanged), for: .valueChanged)
        minutesTextField.addTarget(self, action: #selector(updateExercise), for: .editingChanged)
        secondsTextField.addTarget(self, action: #selector(updateExercise), for: .editingChanged)
        styleSegmentControl.addTarget(self, action: #selector(updateExercise), for: .valueChanged)
        descriptionTextField.addTarget(self, action: #selector(updateExercise), for: .editingChanged)
    }
    
    // MARK: - Configuration Methods
    func configure(with exercise: Exercise) {
        self.exercise = exercise
        
        typeSegmentControl.selectedSegmentIndex = {
            switch exercise.type {
            case .warmup: return 0
            case .main: return 1
            case .cooldown: return 2
            }
        }()
        
        metersTextField.text = "\(exercise.meters)"
        repsTextField.text = "\(exercise.repetitions)"
        hasIntervalSwitch.isOn = exercise.hasInterval
        intervalStackView.isHidden = !exercise.hasInterval
        
        if exercise.hasInterval {
            minutesTextField.text = exercise.intervalMinutes.map { "\($0)" }
            secondsTextField.text = exercise.intervalSeconds.map { "\($0)" }
        } else {
            minutesTextField.text = ""
            secondsTextField.text = ""
        }
        
        styleSegmentControl.selectedSegmentIndex = {
            switch exercise.style {
            case .freestyle: return 0
            case .breaststroke: return 1
            case .backstroke: return 2
            case .butterfly: return 3
            case .medley: return 4
            }
        }()
        
        descriptionTextField.text = exercise.description
    }
    
    // MARK: - Actions
    @objc private func intervalSwitchChanged() {
        intervalStackView.isHidden = !hasIntervalSwitch.isOn
        updateExercise()
    }
    
    @objc private func updateExercise() {
        let type: ExerciseType = {
            switch typeSegmentControl.selectedSegmentIndex {
            case 0: return .warmup
            case 1: return .main
            default: return .cooldown
            }
        }()
        
        let style: SwimStyle = {
            switch styleSegmentControl.selectedSegmentIndex {
            case 0: return .freestyle
            case 1: return .breaststroke
            case 2: return .backstroke
            case 3: return .butterfly
            default: return .medley
            }
        }()
        
        let updatedExercise = Exercise(
            type: type,
            meters: Int(metersTextField.text ?? "0") ?? 0,
            repetitions: Int(repsTextField.text ?? "1") ?? 1,
            hasInterval: hasIntervalSwitch.isOn,
            intervalMinutes: hasIntervalSwitch.isOn ? Int(minutesTextField.text ?? "0") : nil,
            intervalSeconds: hasIntervalSwitch.isOn ? Int(secondsTextField.text ?? "0") : nil,
            style: style,
            description: descriptionTextField.text ?? ""
        )
        
        exercise = updatedExercise
        delegate?.exerciseCell(self, didUpdate: updatedExercise)
    }
}
