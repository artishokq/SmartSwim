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
    func exerciseCell(_ cell: ExerciseCell, didRequestDeletionAt indexPath: IndexPath)
}

final class ExerciseCell: UITableViewCell {
    // MARK: - Constants
    private enum Constants {
        static let cellCornerRadius: CGFloat = 18
        
        static let textFieldHeight: CGFloat = 38
        static let textFieldCornerRadius: CGFloat = 6
        
        static let toolBarDoneButton: String = "Готово"
        
        static let exerciseNumberLabelTopPadding: CGFloat = 9
        static let exerciseNumberLabelLeftPadding: CGFloat = 9
        static let exerciseNumberText: String = "Задание"
        
        static let typeItems: [String] = ["Разминка", "Основное", "Заминка"]
        static let typeSegmentControlCornerRadius: CGFloat = 6
        static let typeSegmentControlTopPadding: CGFloat = 12
        static let typeSegmentControlRightPadding: CGFloat = 9
        static let typeSegmentControlLeftPadding: CGFloat = 9
        static let typeSegmentControlHeight: CGFloat = 38
        
        static let metersValues: [Int] = Array(stride(from: 25, through: 5000, by: 25))
        static let metersPlaceholder: String = "Метры"
        static let metersTextFieldTopPadding: CGFloat = 12
        static let metersTextFieldLeftPadding: CGFloat = 9
        static let metersTextFieldRightPadding: CGFloat = 6
        
        static let repsValues: [Int] = Array(1...50)
        static let repsPlaceholder: String = "Повторения"
        static let repsTextFieldTopPadding: CGFloat = 12
        static let repsTextFieldRightPadding: CGFloat = 9
        static let repsTextFieldLeftPadding: CGFloat = 6
        
        static let intervalLabel: String = "Режим"
        static let intervalLabelTopPadding: CGFloat = 16
        static let intervalLabelLeftPadding: CGFloat = 9
        static let intervalSwitchLeftPadding: CGFloat = 8
        static let intervalStackViewTopPadding: CGFloat = 16
        static let intervalStackViewLeftPadding: CGFloat = 9
        static let intervalStackViewRightPadding: CGFloat = 9
        
        static let minutesValues: [Int] = Array(0...59)
        static let minutesPlaceholder: String = "Минуты"
        static let minutesTextFieldRightPadding: CGFloat = 6
        
        static let secondsValues: [Int] = Array(0...59)
        static let secondsPlaceholder: String = "Секунды"
        static let secondsTextFieldLeftPadding: CGFloat = 6
        
        static let styleItems: [String] = ["Кроль", "Брасс", "Спина", "Батт", "К/П", "Любой"]
        static let styleSegmentControlCornerRadius: CGFloat = 6
        static let styleSegmentControlTopPadding: CGFloat = 12
        static let styleSegmentControlRightPadding: CGFloat = 9
        static let styleSegmentControlLeftPadding: CGFloat = 9
        static let styleSegmentControlHeight: CGFloat = 38
        
        static let descriptionPlaceholder: String = "Описание"
        static let descriptionTextViewCornerRadius: CGFloat = 6
        static let descriptionTextViewTopPadding: CGFloat = 12
        static let descriptionTextViewLeftPadding: CGFloat = 9
        static let descriptionTextViewRightPadding: CGFloat = 9
        static let descriptionTextViewHeight: CGFloat = 50
        
        static let deleteButtonTopPadding: CGFloat = 9
        static let deleteButtonRightPadding: CGFloat = 9
        static let deleteButtonBottomPadding: CGFloat = 9
        static let deleteButtonTitle: String = "Удаление задания"
        static let deleteButtonMessage: String = "Вы уверены, что хотите удалить это задание?"
        static let deleteButtonCancelTitle: String = "Отмена"
        static let deleteButtonDeleteTitle: String = "Удалить"
    }
    
    // MARK: - Fields
    static let identifier = "ExerciseCell"
    weak var delegate: ExerciseCellDelegate?
    private var exercise: Exercise?
    
    private let exerciseNumberLabel: UILabel = UILabel()
    private let typeSegmentControl: UISegmentedControl = UISegmentedControl()
    private let metersTextField: UITextField = UITextField()
    private let repsTextField: UITextField = UITextField()
    private let intervalLabel: UILabel = UILabel()
    private let hasIntervalSwitch: UISwitch = UISwitch()
    private let minutesTextField: UITextField = UITextField()
    private let secondsTextField:UITextField = UITextField()
    private let intervalStackView: UIStackView = UIStackView()
    private let styleSegmentControl: UISegmentedControl = UISegmentedControl()
    private let descriptionTextView: UITextView = UITextView()
    private let deleteButton: UIButton = UIButton()
    
    private let metersPicker = UIPickerView()
    private let repsPicker = UIPickerView()
    private let minutesPicker = UIPickerView()
    private let secondsPicker = UIPickerView()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
        configureActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configurations
    private func configureUI() {
        backgroundColor = Resources.Colors.createCellBackgroundColor
        selectionStyle = .none
        layer.cornerRadius = Constants.cellCornerRadius
        descriptionTextView.delegate = self
        
        contentView.addSubview(exerciseNumberLabel)
        contentView.addSubview(typeSegmentControl)
        contentView.addSubview(metersTextField)
        contentView.addSubview(repsTextField)
        contentView.addSubview(intervalLabel)
        contentView.addSubview(hasIntervalSwitch)
        contentView.addSubview(intervalStackView)
        contentView.addSubview(styleSegmentControl)
        contentView.addSubview(descriptionTextView)
        contentView.addSubview(deleteButton)
        
        exerciseNumberLabelConfiguration()
        typeSegmentControlConfiguration()
        metersTextFieldConfiguration()
        repsTextFieldConfiguration()
        intervalLabelConfiguration()
        hasIntervalSwitchConfiguration()
        intervalStackViewConfiguration()
        minutesTextFieldConfiguration()
        secondsTextFieldConfiguration()
        styleSegmentControlConfiguration()
        descriptionTextViewConfiguration()
        deleteButtonConfiguration()
        configurePickers()
    }
    
    private func configureTextField(_ textField: UITextField, placeholder: String) {
        textField.backgroundColor = Resources.Colors.fieldsBackgroundColor
        textField.layer.cornerRadius = Constants.textFieldCornerRadius
        textField.textColor = Resources.Colors.titleWhite
        textField.font = Resources.Fonts.fieldsAndPlaceholdersFont
        textField.placeholder = placeholder
        textField.textAlignment = .center
    }
    
    private func configurePickers() {
        [metersPicker, repsPicker, minutesPicker, secondsPicker].forEach { picker in
            picker.delegate = self
            picker.dataSource = self
        }
        
        metersPicker.tag = 0
        repsPicker.tag = 1
        minutesPicker.tag = 2
        secondsPicker.tag = 3
        
        metersTextField.inputView = metersPicker
        repsTextField.inputView = repsPicker
        minutesTextField.inputView = minutesPicker
        secondsTextField.inputView = secondsPicker
        
        let metersToolbar = createToolbar(for: metersTextField)
        let repsToolbar = createToolbar(for: repsTextField)
        let minutesToolbar = createToolbar(for: minutesTextField)
        let secondsToolbar = createToolbar(for: secondsTextField)
        
        metersTextField.inputAccessoryView = metersToolbar
        repsTextField.inputAccessoryView = repsToolbar
        minutesTextField.inputAccessoryView = minutesToolbar
        secondsTextField.inputAccessoryView = secondsToolbar
    }
    
    private func createToolbar(for textField: UITextField) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(
            title: Constants.toolBarDoneButton,
            style: .done,
            target: self,
            action: #selector(doneButtonTapped))
        
        doneButton.tintColor = Resources.Colors.blueColor
        
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil)
        
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        doneButton.tag = textField.hash
        return toolbar
    }
    
    // НОМЕР ЗАДАНИЯ
    private func exerciseNumberLabelConfiguration() {
        exerciseNumberLabel.font = Resources.Fonts.fieldsAndPlaceholdersFont
        exerciseNumberLabel.textColor = Resources.Colors.titleWhite
        
        exerciseNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        exerciseNumberLabel.pinTop(to: contentView.topAnchor, Constants.exerciseNumberLabelTopPadding)
        exerciseNumberLabel.pinLeft(to: contentView.leadingAnchor, Constants.exerciseNumberLabelLeftPadding)
    }
    
    // ВЫБОР ТИПА ТРЕНИРОВКИ (РАЗМИНКА / ОСНОВНОЕ / ЗАМИНКА)
    private func typeSegmentControlConfiguration() {
        typeSegmentControl.removeAllSegments()
        for (index, title) in Constants.typeItems.enumerated() {
            typeSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        typeSegmentControl.selectedSegmentIndex = 0
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Resources.Colors.titleWhite,
            .font: Resources.Fonts.fieldsAndPlaceholdersFont
        ]
        
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Resources.Colors.titleWhite,
            .font: Resources.Fonts.fieldsAndPlaceholdersFont
        ]
        
        typeSegmentControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        typeSegmentControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        typeSegmentControl.layer.cornerRadius = Constants.typeSegmentControlCornerRadius
        typeSegmentControl.backgroundColor = Resources.Colors.fieldsBackgroundColor
        typeSegmentControl.selectedSegmentTintColor = Resources.Colors.blueColor
        
        // Констрейнты
        typeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        typeSegmentControl.pinTop(to: exerciseNumberLabel.bottomAnchor, Constants.typeSegmentControlTopPadding)
        typeSegmentControl.pinLeft(to: contentView.leadingAnchor, Constants.typeSegmentControlLeftPadding)
        typeSegmentControl.pinRight(to: contentView.trailingAnchor, Constants.typeSegmentControlRightPadding)
        typeSegmentControl.setHeight(Constants.typeSegmentControlHeight)
    }
    
    // КОЛИЧЕСТВО МЕТРОВ
    private func metersTextFieldConfiguration() {
        configureTextField(metersTextField, placeholder: Constants.metersPlaceholder)
        
        // Констрейнты
        metersTextField.translatesAutoresizingMaskIntoConstraints = false
        metersTextField.pinTop(to: typeSegmentControl.bottomAnchor, Constants.metersTextFieldTopPadding)
        metersTextField.pinLeft(to: contentView.leadingAnchor, Constants.metersTextFieldLeftPadding)
        metersTextField.pinRight(to: contentView.centerXAnchor, Constants.metersTextFieldRightPadding)
        metersTextField.setHeight(Constants.textFieldHeight)
    }
    
    // КОЛИЧЕСТВО ПОВТОРЕНИЙ
    private func repsTextFieldConfiguration() {
        configureTextField(repsTextField, placeholder: Constants.repsPlaceholder)
        
        // Констрейнты
        repsTextField.translatesAutoresizingMaskIntoConstraints = false
        repsTextField.pinTop(to: typeSegmentControl.bottomAnchor, Constants.repsTextFieldTopPadding)
        repsTextField.pinLeft(to: contentView.centerXAnchor, Constants.repsTextFieldLeftPadding)
        repsTextField.pinRight(to: contentView.trailingAnchor, Constants.repsTextFieldRightPadding)
        repsTextField.setHeight(Constants.textFieldHeight)
    }
    
    // РЕЖИМ
    private func intervalLabelConfiguration() {
        intervalLabel.text = Constants.intervalLabel
        
        // Констрейнты
        intervalLabel.translatesAutoresizingMaskIntoConstraints = false
        intervalLabel.pinTop(to: metersTextField.bottomAnchor, Constants.intervalLabelTopPadding)
        intervalLabel.pinLeft(to: contentView.leadingAnchor, Constants.intervalLabelLeftPadding)
    }
    
    // ПЕРЕКЛЮЧАТЕЛЬ РЕЖИМА
    private func hasIntervalSwitchConfiguration() {
        // Констрейнты
        hasIntervalSwitch.translatesAutoresizingMaskIntoConstraints = false
        hasIntervalSwitch.pinCenterY(to: intervalLabel.centerYAnchor)
        hasIntervalSwitch.pinLeft(to: intervalLabel.trailingAnchor, Constants.intervalSwitchLeftPadding)
    }
    
    // STACKVIEW МИНУТ И СЕКУНД
    private func intervalStackViewConfiguration() {
        intervalStackView.axis = .horizontal
        intervalStackView.distribution = .fillEqually
        intervalStackView.isHidden = true
        
        intervalStackView.addArrangedSubview(minutesTextField)
        intervalStackView.addArrangedSubview(secondsTextField)
        
        // Констрейнты
        intervalStackView.translatesAutoresizingMaskIntoConstraints = false
        intervalStackView.pinTop(to: intervalLabel.bottomAnchor, Constants.intervalStackViewTopPadding)
        intervalStackView.pinLeft(to: contentView.leadingAnchor, Constants.intervalStackViewLeftPadding)
        intervalStackView.pinRight(to: contentView.trailingAnchor, Constants.intervalStackViewRightPadding)
    }
    
    // КОЛИЧЕСТВО МИНУТ
    private func minutesTextFieldConfiguration() {
        configureTextField(minutesTextField, placeholder: Constants.minutesPlaceholder)
        
        // Констрейнты
        minutesTextField.translatesAutoresizingMaskIntoConstraints = false
        minutesTextField.pinTop(to: intervalStackView)
        minutesTextField.pinLeft(to: intervalStackView)
        minutesTextField.pinRight(to: intervalStackView.centerXAnchor, Constants.minutesTextFieldRightPadding)
        minutesTextField.setHeight(Constants.textFieldHeight)
    }
    
    // КОЛИЧЕСТВО СЕКУНД
    private func secondsTextFieldConfiguration() {
        configureTextField(secondsTextField, placeholder: Constants.secondsPlaceholder)
        
        // Констрейнты
        secondsTextField.translatesAutoresizingMaskIntoConstraints = false
        secondsTextField.pinTop(to: intervalStackView)
        secondsTextField.pinLeft(to: intervalStackView.centerXAnchor, Constants.secondsTextFieldLeftPadding)
        secondsTextField.pinRight(to: intervalStackView)
        secondsTextField.setHeight(Constants.textFieldHeight)
    }
    
    // СТИЛЬ ПЛАВАНИЯ
    private func styleSegmentControlConfiguration() {
        styleSegmentControl.removeAllSegments()
        for (index, title) in Constants.styleItems.enumerated() {
            styleSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        styleSegmentControl.selectedSegmentIndex = 0
        
        styleSegmentControl.layer.cornerRadius = Constants.styleSegmentControlCornerRadius
        styleSegmentControl.backgroundColor = Resources.Colors.fieldsBackgroundColor
        styleSegmentControl.selectedSegmentTintColor = Resources.Colors.blueColor
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Resources.Colors.titleWhite,
            .font: Resources.Fonts.fieldsAndPlaceholdersSmallerFont
        ]
        
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Resources.Colors.titleWhite,
            .font: Resources.Fonts.fieldsAndPlaceholdersSmallerFont
        ]
        
        styleSegmentControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        styleSegmentControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        // Констрейнты
        styleSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        styleSegmentControl.pinTop(to: intervalStackView.bottomAnchor, Constants.styleSegmentControlTopPadding)
        styleSegmentControl.pinLeft(to: contentView.leadingAnchor, Constants.styleSegmentControlLeftPadding)
        styleSegmentControl.pinRight(to: contentView.trailingAnchor, Constants.styleSegmentControlRightPadding)
        styleSegmentControl.setHeight(Constants.styleSegmentControlHeight)
    }
    
    // ОПИСАНИЕ ТРЕНИРОВКИ
    private func descriptionTextViewConfiguration() {
        descriptionTextView.backgroundColor = Resources.Colors.fieldsBackgroundColor
        descriptionTextView.layer.cornerRadius = Constants.descriptionTextViewCornerRadius
        descriptionTextView.textColor = Resources.Colors.titleWhite
        descriptionTextView.font = Resources.Fonts.fieldsAndPlaceholdersFont
        if descriptionTextView.text.isEmpty {
            descriptionTextView.text = Constants.descriptionPlaceholder
            descriptionTextView.textColor = .gray
        } else {
            descriptionTextView.textColor = Resources.Colors.titleWhite
        }
        
        // Констрейнты
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        descriptionTextView.pinTop(to: styleSegmentControl.bottomAnchor, Constants.descriptionTextViewTopPadding)
        descriptionTextView.pinLeft(to: contentView.leadingAnchor, Constants.descriptionTextViewLeftPadding)
        descriptionTextView.pinRight(to: contentView.trailingAnchor, Constants.descriptionTextViewRightPadding)
        descriptionTextView.setHeight(Constants.descriptionTextViewHeight)
    }
    
    private func deleteButtonConfiguration() {
        deleteButton.setImage(Resources.Images.Workout.deleteButtonImage, for: .normal)
        
        // Констрейнты
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.pinTop(to: descriptionTextView.bottomAnchor, Constants.deleteButtonTopPadding)
        deleteButton.pinRight(to: contentView.trailingAnchor, Constants.deleteButtonRightPadding)
        deleteButton.pinBottom(to: contentView.bottomAnchor, Constants.deleteButtonBottomPadding)
    }
    
    private func configureActions() {
        typeSegmentControl.addTarget(self, action: #selector(updateExercise), for: .valueChanged)
        hasIntervalSwitch.addTarget(self, action: #selector(intervalSwitchChanged), for: .valueChanged)
        styleSegmentControl.addTarget(self, action: #selector(updateExercise), for: .valueChanged)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    func configure(with exercise: Exercise, number: Int) {
        self.exercise = exercise
        
        exerciseNumberLabel.text = "\(Constants.exerciseNumberText) \(number)"
        
        typeSegmentControl.selectedSegmentIndex = {
            switch exercise.type {
            case .warmup: return 0
            case .main: return 1
            case .cooldown: return 2
            }
        }()
        
        if let meters = exercise.meters {
            metersTextField.text = "\(meters) м"
            if let index = Constants.metersValues.firstIndex(of: meters) {
                metersPicker.selectRow(index, inComponent: 0, animated: false)
            }
        }
        
        if let reps = exercise.repetitions {
            repsTextField.text = "\(reps) повт"
            if let index = Constants.repsValues.firstIndex(of: reps) {
                repsPicker.selectRow(index, inComponent: 0, animated: false)
            }
        }
        
        hasIntervalSwitch.isOn = exercise.hasInterval
        intervalStackView.isHidden = !exercise.hasInterval
        
        if exercise.hasInterval {
            if let minutes = exercise.intervalMinutes {
                minutesTextField.text = "\(minutes) мин"
                if let index = Constants.minutesValues.firstIndex(of: minutes) {
                    minutesPicker.selectRow(index, inComponent: 0, animated: false)
                }
            }
            
            if let seconds = exercise.intervalSeconds {
                secondsTextField.text = "\(seconds) сек"
                if let index = Constants.secondsValues.firstIndex(of: seconds) {
                    secondsPicker.selectRow(index, inComponent: 0, animated: false)
                }
            }
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
        
        if !exercise.description.isEmpty {
            descriptionTextView.text = exercise.description
            descriptionTextView.textColor = Resources.Colors.titleWhite
        } else {
            descriptionTextView.text = Constants.descriptionPlaceholder
            descriptionTextView.textColor = .gray
        }
    }
    
    private func getValueForPicker(_ picker: UIPickerView, row: Int) -> String {
        switch picker.tag {
        case 0: return "\(Constants.metersValues[row]) м"
        case 1: return "\(Constants.repsValues[row]) повт"
        case 2: return "\(Constants.minutesValues[row]) мин"
        case 3: return "\(Constants.secondsValues[row]) сек"
        default: return ""
        }
    }
    
    // MARK: - Actions
    @objc private func doneButtonTapped(_ sender: UIBarButtonItem) {
        [metersTextField, repsTextField, minutesTextField, secondsTextField].forEach { textField in
            if textField.hash == sender.tag {
                textField.resignFirstResponder()
                
                // Обновляем значение в текстовом поле при закрытии
                let picker = textField.inputView as! UIPickerView
                let selectedRow = picker.selectedRow(inComponent: 0)
                
                textField.text = getValueForPicker(picker, row: selectedRow)
                updateExercise()
            }
        }
    }
    
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
        
        let selectedMeters = Constants.metersValues[metersPicker.selectedRow(inComponent: 0)]
        let selectedReps = Constants.repsValues[repsPicker.selectedRow(inComponent: 0)]
        let description = descriptionTextView.textColor == .gray ? "" : (descriptionTextView.text ?? "")
        
        let updatedExercise = Exercise(
            type: type,
            meters: selectedMeters,
            repetitions: selectedReps,
            hasInterval: hasIntervalSwitch.isOn,
            intervalMinutes: hasIntervalSwitch.isOn ? Constants.minutesValues[minutesPicker.selectedRow(inComponent: 0)] : nil,
            intervalSeconds: hasIntervalSwitch.isOn ? Constants.secondsValues[secondsPicker.selectedRow(inComponent: 0)] : nil,
            style: style,
            description: description
        )
        
        exercise = updatedExercise
        delegate?.exerciseCell(self, didUpdate: updatedExercise)
    }
    
    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: Constants.deleteButtonTitle,
            message: Constants.deleteButtonMessage,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: Constants.deleteButtonCancelTitle, style: .cancel)
        
        let deleteAction = UIAlertAction(
            title: Constants.deleteButtonDeleteTitle,
            style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            if let indexPath = self.getIndexPath() {
                self.delegate?.exerciseCell(self, didRequestDeletionAt: indexPath)
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        // Находим текущий ViewController
        if let viewController = self.findViewController() {
            viewController.present(alert, animated: true)
        }
    }
    
    private func getIndexPath() -> IndexPath? {
        guard let tableView = self.superview as? UITableView else { return nil }
        return tableView.indexPath(for: self)
    }
    
    private func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
}

// MARK: - UIPickerViewDelegate & DataSource
extension ExerciseCell: UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: return Constants.metersValues.count
        case 1: return Constants.repsValues.count
        case 2: return Constants.minutesValues.count
        case 3: return Constants.secondsValues.count
        default: return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0: return "\(Constants.metersValues[row]) м"
        case 1: return "\(Constants.repsValues[row]) повт"
        case 2: return "\(Constants.minutesValues[row]) мин"
        case 3: return "\(Constants.secondsValues[row]) сек"
        default: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        updateExercise()
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title: String
        switch pickerView.tag {
        case 0: title = "\(Constants.metersValues[row]) м"
        case 1: title = "\(Constants.repsValues[row]) повт"
        case 2: title = "\(Constants.minutesValues[row]) мин"
        case 3: title = "\(Constants.secondsValues[row]) сек"
        default: return nil
        }
        
        return NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: Resources.Colors.titleWhite,
                .font: Resources.Fonts.fieldsAndPlaceholdersFont
            ]
        )
    }
    
    func textViewDidChange(_ textView: UITextView) {
        updateExercise()
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .gray {
            textView.text = nil
            textView.textColor = Resources.Colors.titleWhite
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = Constants.descriptionPlaceholder
            textView.textColor = .gray
        }
    }
}
