//
//  ExerciseCell.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 15.01.2025.
//

import UIKit

protocol ExerciseCellDelegate: AnyObject {
    func exerciseCell(_ cell: ExerciseCell, didUpdate exercise: Exercise)
    func exerciseCell(_ cell: ExerciseCell, didRequestDeletionAt indexPath: IndexPath)
}

final class ExerciseCell: UITableViewCell {
    // MARK: - Constants
    private enum Constants {
        static let cellCornerRadius: CGFloat = 20
        
        static let textFieldHeight: CGFloat = 38
        static let textFieldCornerRadius: CGFloat = 9
        
        static let toolBarDoneButton: String = "Готово"
        
        static let exerciseNumberLabelTopPadding: CGFloat = 10
        static let exerciseNumberLabelLeftPadding: CGFloat = 9
        static let exerciseNumberText: String = "Задание"
        
        static let typeItems: [String] = ["Разминка", "Основное", "Заминка"]
        static let typeSegmentControlCornerRadius: CGFloat = 9
        static let typeSegmentControlTopPadding: CGFloat = 9
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
        static let styleSegmentControlCornerRadius: CGFloat = 9
        static let styleSegmentControlTopPadding: CGFloat = 12
        static let styleSegmentControlRightPadding: CGFloat = 9
        static let styleSegmentControlLeftPadding: CGFloat = 9
        static let styleSegmentControlHeight: CGFloat = 38
        
        static let descriptionPlaceholder: String = "Описание"
        static let descriptionTextViewCornerRadius: CGFloat = 9
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
    private var indexPath: IndexPath?
    
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
    
    // MARK: - UI Configuration
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
    
    // MARK: - Text Field Configuration
    private func configureTextField(_ textField: UITextField, placeholder: String) {
        textField.backgroundColor = Resources.Colors.fieldsBackgroundColor
        textField.layer.cornerRadius = Constants.textFieldCornerRadius
        textField.textColor = Resources.Colors.titleWhite
        textField.font = Resources.Fonts.fieldsAndPlaceholdersFont
        textField.placeholder = placeholder
        textField.textAlignment = .center
    }
    
    // MARK: - Exercise Number Label Configuration
    private func exerciseNumberLabelConfiguration() {
        exerciseNumberLabel.font = Resources.Fonts.fieldsAndPlaceholdersFont
        exerciseNumberLabel.textColor = Resources.Colors.titleWhite
        
        exerciseNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        exerciseNumberLabel.pinTop(to: contentView.topAnchor, Constants.exerciseNumberLabelTopPadding)
        exerciseNumberLabel.pinLeft(to: contentView.leadingAnchor, Constants.exerciseNumberLabelLeftPadding)
    }
    
    // MARK: - Type Segment Control Configuration
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
    
    // MARK: - Meters Text Field Configuration
    private func metersTextFieldConfiguration() {
        configureTextField(metersTextField, placeholder: Constants.metersPlaceholder)
        
        // Констрейнты
        metersTextField.translatesAutoresizingMaskIntoConstraints = false
        metersTextField.pinTop(to: typeSegmentControl.bottomAnchor, Constants.metersTextFieldTopPadding)
        metersTextField.pinLeft(to: contentView.leadingAnchor, Constants.metersTextFieldLeftPadding)
        metersTextField.pinRight(to: contentView.centerXAnchor, Constants.metersTextFieldRightPadding)
        metersTextField.setHeight(Constants.textFieldHeight)
    }
    
    // MARK: - Reps Text Field Configuration
    private func repsTextFieldConfiguration() {
        configureTextField(repsTextField, placeholder: Constants.repsPlaceholder)
        
        // Констрейнты
        repsTextField.translatesAutoresizingMaskIntoConstraints = false
        repsTextField.pinTop(to: typeSegmentControl.bottomAnchor, Constants.repsTextFieldTopPadding)
        repsTextField.pinLeft(to: contentView.centerXAnchor, Constants.repsTextFieldLeftPadding)
        repsTextField.pinRight(to: contentView.trailingAnchor, Constants.repsTextFieldRightPadding)
        repsTextField.setHeight(Constants.textFieldHeight)
    }
    
    // MARK: - Interval Label Configuration
    private func intervalLabelConfiguration() {
        intervalLabel.text = Constants.intervalLabel
        
        // Констрейнты
        intervalLabel.translatesAutoresizingMaskIntoConstraints = false
        intervalLabel.pinTop(to: metersTextField.bottomAnchor, Constants.intervalLabelTopPadding)
        intervalLabel.pinLeft(to: contentView.leadingAnchor, Constants.intervalLabelLeftPadding)
    }
    
    // MARK: - Interval Switch Configuration
    private func hasIntervalSwitchConfiguration() {
        // Констрейнты
        hasIntervalSwitch.translatesAutoresizingMaskIntoConstraints = false
        hasIntervalSwitch.pinCenterY(to: intervalLabel.centerYAnchor)
        hasIntervalSwitch.pinLeft(to: intervalLabel.trailingAnchor, Constants.intervalSwitchLeftPadding)
    }
    
    // MARK: - Interval Stack View Configuration
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
    
    // MARK: - Minutes Text Field Configuration
    private func minutesTextFieldConfiguration() {
        configureTextField(minutesTextField, placeholder: Constants.minutesPlaceholder)
        
        // Констрейнты
        minutesTextField.translatesAutoresizingMaskIntoConstraints = false
        minutesTextField.pinTop(to: intervalStackView)
        minutesTextField.pinLeft(to: intervalStackView)
        minutesTextField.pinRight(to: intervalStackView.centerXAnchor, Constants.minutesTextFieldRightPadding)
        minutesTextField.setHeight(Constants.textFieldHeight)
    }
    
    // MARK: - Seconds Text Field Configuration
    private func secondsTextFieldConfiguration() {
        configureTextField(secondsTextField, placeholder: Constants.secondsPlaceholder)
        
        // Констрейнты
        secondsTextField.translatesAutoresizingMaskIntoConstraints = false
        secondsTextField.pinTop(to: intervalStackView)
        secondsTextField.pinLeft(to: intervalStackView.centerXAnchor, Constants.secondsTextFieldLeftPadding)
        secondsTextField.pinRight(to: intervalStackView)
        secondsTextField.setHeight(Constants.textFieldHeight)
    }
    
    // MARK: - Style Segment Control Configuration
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
    
    // MARK: - Description Text View Configuration
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
    
    // MARK: - Delete Button Configuration
    private func deleteButtonConfiguration() {
        deleteButton.setImage(Resources.Images.Workout.deleteButtonImage, for: .normal)
        
        // Констрейнты
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.pinTop(to: descriptionTextView.bottomAnchor, Constants.deleteButtonTopPadding)
        deleteButton.pinRight(to: contentView.trailingAnchor, Constants.deleteButtonRightPadding)
        deleteButton.pinBottom(to: contentView.bottomAnchor, Constants.deleteButtonBottomPadding)
    }
    
    // MARK: - Pickers Configuration
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
    
    // MARK: - Private Methods
    private func createToolbar(for textField: UITextField) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(
            title: Constants.toolBarDoneButton,
            style: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        
        doneButton.tintColor = Resources.Colors.blueColor
        
        // В качестве id вешаем на кнопку хэш самого textField ,Потом в doneButtonTapped мы этот хэш и используем
        doneButton.tag = textField.hash
        
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        return toolbar
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
    
    private func notifyDelegate() {
        let exercise = Exercise(
            type: ExerciseType(rawValue: Int16(typeSegmentControl.selectedSegmentIndex)) ?? .warmup,
            meters: Int16(metersTextField.text?.replacingOccurrences(of: " м", with: "") ?? "0") ?? 0,
            repetitions: Int16(repsTextField.text?.replacingOccurrences(of: " повт", with: "") ?? "0") ?? 0,
            hasInterval: hasIntervalSwitch.isOn,
            intervalMinutes: Int16(minutesTextField.text?.replacingOccurrences(of: " мин", with: "") ?? "0") ?? 0,
            intervalSeconds: Int16(secondsTextField.text?.replacingOccurrences(of: " сек", with: "") ?? "0") ?? 0,
            style: SwimStyle(rawValue: Int16(styleSegmentControl.selectedSegmentIndex)) ?? .freestyle,
            description: descriptionTextView.text == Constants.descriptionPlaceholder ? "" : descriptionTextView.text
        )
        delegate?.exerciseCell(self, didUpdate: exercise)
    }
    
    // MARK: - Actions Configuration
    private func configureActions() {
        typeSegmentControl.addTarget(self, action: #selector(segmentControlChanged), for: .valueChanged)
        hasIntervalSwitch.addTarget(self, action: #selector(intervalSwitchChanged), for: .valueChanged)
        styleSegmentControl.addTarget(self, action: #selector(segmentControlChanged), for: .valueChanged)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func segmentControlChanged() {
        notifyDelegate()
    }
    
    @objc private func intervalSwitchChanged() {
        intervalStackView.isHidden = !hasIntervalSwitch.isOn
        notifyDelegate()
    }
    
    @objc private func deleteButtonTapped() {
        if let indexPath = indexPath {
            delegate?.exerciseCell(self, didRequestDeletionAt: indexPath)
        }
    }
    
    @objc private func doneButtonTapped(_ sender: UIBarButtonItem) {
        // Ищем тот textField, чей hash совпадает с sender.tag
        guard let textField = [metersTextField, repsTextField, minutesTextField, secondsTextField]
            .first(where: { $0.hash == sender.tag })
        else { return }
        
        // Берём pickerView из inputView
        guard let picker = textField.inputView as? UIPickerView else { return }
        
        let selectedRow = picker.selectedRow(inComponent: 0)
        
        // Заполняем текст в зависимости от текущего пикера
        switch picker.tag {
        case 0: // metersPicker
            textField.text = "\(Constants.metersValues[selectedRow]) м"
        case 1: // repsPicker
            textField.text = "\(Constants.repsValues[selectedRow]) повт"
        case 2: // minutesPicker
            textField.text = "\(Constants.minutesValues[selectedRow]) мин"
        case 3: // secondsPicker
            textField.text = "\(Constants.secondsValues[selectedRow]) сек"
        default:
            break
        }
        
        // Скрываем клавиатуру
        textField.resignFirstResponder()
        
        // Уведомляем делегата, что изменились данные
        notifyDelegate()
    }
    
    // MARK: - Public Methods
    func configure(with exercise: Exercise, number: Int, indexPath: IndexPath) {
        self.indexPath = indexPath
        exerciseNumberLabel.text = "\(Constants.exerciseNumberText) \(number)"
        typeSegmentControl.selectedSegmentIndex = Int(exercise.type.rawValue)
        
        metersTextField.text = exercise.meters == 0 ? "" : "\(exercise.meters) м"
        repsTextField.text = exercise.repetitions == 0 ? "" : "\(exercise.repetitions) повт"
        
        hasIntervalSwitch.isOn = exercise.hasInterval
        intervalStackView.isHidden = !exercise.hasInterval
        
        // Сбрасываем значения полей интервала
        if exercise.hasInterval {
            minutesTextField.text = exercise.intervalMinutes == 0 ? "" : "\(exercise.intervalMinutes!) мин"
            secondsTextField.text = exercise.intervalSeconds == 0 ? "" : "\(exercise.intervalSeconds!) сек"
        } else {
            minutesTextField.text = ""
            secondsTextField.text = ""
        }
        
        styleSegmentControl.selectedSegmentIndex = Int(exercise.style.rawValue)
        descriptionTextView.text = exercise.description.isEmpty ? Constants.descriptionPlaceholder : exercise.description
        descriptionTextView.textColor = exercise.description.isEmpty ? .gray : Resources.Colors.titleWhite
    }
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource & UITextViewDelegate
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
        notifyDelegate()
    }
}
