//
//  DiaryCreateStartViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import UIKit

protocol DiaryCreateStartDisplayLogic: AnyObject {
    func displayStartCreated(viewModel: DiaryCreateStartModels.Create.ViewModel)
    func displayLapCount(viewModel: DiaryCreateStartModels.CalculateLaps.ViewModel)
    func displayCollectedData(viewModel: DiaryCreateStartModels.CollectData.ViewModel)
}

final class DiaryCreateStartViewController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let backgroundColor = UIColor(hexString: "#242531")
        static let contentBackgroundColor = UIColor(hexString: "#323645")
        static let fieldBackgroundColor = UIColor(hexString: "#505773")
        static let titleColor: UIColor = UIColor(hexString: "#FFFFFF") ?? .white
        static let blueColor = UIColor(hexString: "#0A84FF")
        
        static let poolSizeSectionText: String = "Размер бассейна:"
        static let styleSectionText: String = "Стиль плавания:"
        static let metersSectionText: String = "Метраж:"
        static let dateSectionText: String = "Дата:"
        static let timeSectionText: String = "Общее время:"
        
        static let titleText: String = "Создание старта"
        static let saveButtonTitle: String = "Сохранить"
        
        static let poolSizeItems: [String] = ["25м", "50м"]
        static let styleItems: [String] = ["Кроль", "Брасс", "Спина", "Батт", "К/П"]
        
        static let contentPadding: CGFloat = 16
        static let fieldHeight: CGFloat = 42
        static let fieldCornerRadius: CGFloat = 9
        static let fieldSpacing: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        
        static let lapTimeLabelText: String = "Введите время для отрезка"
        static let doneButtonTitle: String = "Готово"
        static let metersPlaceholder: String = "Метры"
        static let datePlaceholder: String = "Дата"
        static let timePlaceholder: String = "Общее время (мм:сс,мс)"
        
        static let alertTitle: String = "Ошибка"
        static let alertButtonTitle: String = "ОК"
        
        static let minutesLabel: String = "Мин"
        static let secondsLabel: String = "Сек"
        static let millisecondsLabel: String = "Мс"
        
        static let poolSizeSectionFont: UIFont = UIFont.systemFont(ofSize: 18, weight: .light)
        static let styleSectionFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .light)
    }
    
    // MARK: - Properties
    var interactor: DiaryCreateStartBusinessLogic?
    var router: (NSObjectProtocol & DiaryCreateStartRoutingLogic & DiaryCreateStartDataPassing)?
    
    private let scrollView: UIScrollView = UIScrollView()
    private let contentView: UIView = UIView()
    
    private let poolSizeLabel: UILabel = UILabel()
    private let poolSizeSegmentControl: UISegmentedControl = UISegmentedControl()
    private let styleLabel: UILabel = UILabel()
    private let styleSegmentControl: UISegmentedControl = UISegmentedControl()
    private let metersLabel: UILabel = UILabel()
    private let metersTextField: UITextField = UITextField()
    private let metersPicker: UIPickerView = UIPickerView()
    private let dateLabel: UILabel = UILabel()
    private let dateTextField: UITextField = UITextField()
    private let timeLabel: UILabel = UILabel()
    private let timeTextField: UITextField = UITextField()
    private let timePicker: UIPickerView = UIPickerView()
    private let lapsStackView: UIStackView = UIStackView()
    
    private var lapTextFields: [UITextField] = []
    private var lapTimePickers: [UIPickerView] = []
    private var numberOfLaps: Int = 0
    private let datePicker: UIDatePicker = UIDatePicker()
    
    // Значения времени для time pickers
    private let minutesRange = Array(0...59)
    private let secondsRange = Array(0...59)
    private let millisecondsRange = Array(0...99)
    
    private var activeTimePicker: UIPickerView?
    private var activeTimeTextField: UITextField?
    
    private var currentMetersOptions: [Int] {
        let styleIndex = styleSegmentControl.selectedSegmentIndex
        let poolSizeIndex = poolSizeSegmentControl.selectedSegmentIndex
        
        switch styleIndex {
        case 0: // Вольный стиль
            return [50, 100, 200, 400, 800, 1500]
        case 1, 2, 3: // Брасс, Спина, Батт
            return [50, 100, 200]
        case 4: // К/П
            if poolSizeIndex == 0 { // 25м бассейн
                return [100, 200, 400]
            } else { // 50м бассейн
                return [200, 400]
            }
        default:
            return [50, 100, 200]
        }
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureKeyboardNotifications()
        
        poolSizeSegmentControl.addTarget(self, action: #selector(poolSizeOrMetersChanged), for: .valueChanged)
        styleSegmentControl.addTarget(self, action: #selector(updateMetersOptions), for: .valueChanged)
        timeTextField.addTarget(self, action: #selector(timeTextFieldFocused), for: .editingDidBegin)
        calculateLaps()
    }
    
    @objc private func timeTextFieldFocused() {
        setupTimePickerForTextField(timeTextField, picker: timePicker)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Configurations
    private func configureUI() {
        view.backgroundColor = Constants.backgroundColor
        title = Constants.titleText
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Отмена",
            style: .plain,
            target: self,
            action: #selector(closeButtonTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: Constants.saveButtonTitle,
            style: .done,
            target: self,
            action: #selector(saveButtonTapped)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(poolSizeLabel)
        contentView.addSubview(poolSizeSegmentControl)
        contentView.addSubview(styleLabel)
        contentView.addSubview(styleSegmentControl)
        contentView.addSubview(metersLabel)
        contentView.addSubview(metersTextField)
        contentView.addSubview(dateLabel)
        contentView.addSubview(dateTextField)
        contentView.addSubview(timeLabel)
        contentView.addSubview(timeTextField)
        contentView.addSubview(lapsStackView)
        
        configureScrollView()
        configurePoolSizeSection()
        configureStyleSection()
        configureMetersSection()
        configureDateSection()
        configureTimeSection()
        configureLapsStackView()
    }
    
    private func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.pinTop(to: view.safeAreaLayoutGuide.topAnchor)
        scrollView.pinLeft(to: view.leadingAnchor)
        scrollView.pinRight(to: view.trailingAnchor)
        scrollView.pinBottom(to: view.bottomAnchor)
        
        contentView.pinTop(to: scrollView.topAnchor)
        contentView.pinLeft(to: scrollView.leadingAnchor)
        contentView.pinRight(to: scrollView.trailingAnchor)
        contentView.pinBottom(to: scrollView.bottomAnchor)
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        NSLayoutConstraint.activate([
            lapsStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Constants.contentPadding * 2)
        ])
    }
    
    private func configurePoolSizeSection() {
        poolSizeLabel.text = Constants.poolSizeSectionText
        poolSizeLabel.textColor = Constants.titleColor
        
        poolSizeSegmentControl.removeAllSegments()
        for (index, title) in Constants.poolSizeItems.enumerated() {
            poolSizeSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        poolSizeSegmentControl.selectedSegmentIndex = 0
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.titleColor,
            .font: Constants.poolSizeSectionFont
        ]
        
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.titleColor,
            .font: Constants.poolSizeSectionFont
        ]
        
        poolSizeSegmentControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        poolSizeSegmentControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        poolSizeSegmentControl.layer.cornerRadius = Constants.fieldCornerRadius
        poolSizeSegmentControl.backgroundColor = Constants.contentBackgroundColor
        poolSizeSegmentControl.selectedSegmentTintColor = Constants.blueColor
        
        poolSizeLabel.translatesAutoresizingMaskIntoConstraints = false
        poolSizeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        poolSizeLabel.pinTop(to: contentView.topAnchor, Constants.contentPadding)
        poolSizeLabel.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        poolSizeSegmentControl.pinTop(to: poolSizeLabel.bottomAnchor, Constants.fieldSpacing / 2)
        poolSizeSegmentControl.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        poolSizeSegmentControl.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
        poolSizeSegmentControl.setHeight(Constants.fieldHeight)
    }
    
    private func configureStyleSection() {
        styleLabel.text = Constants.styleSectionText
        styleLabel.textColor = Constants.titleColor
        
        styleSegmentControl.removeAllSegments()
        for (index, title) in Constants.styleItems.enumerated() {
            styleSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        styleSegmentControl.selectedSegmentIndex = 0
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.titleColor,
            .font: Constants.styleSectionFont
        ]
        
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.titleColor,
            .font: Constants.styleSectionFont
        ]
        
        styleSegmentControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        styleSegmentControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        styleSegmentControl.layer.cornerRadius = Constants.fieldCornerRadius
        styleSegmentControl.backgroundColor = Constants.contentBackgroundColor
        styleSegmentControl.selectedSegmentTintColor = Constants.blueColor
        
        styleLabel.translatesAutoresizingMaskIntoConstraints = false
        styleSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        styleLabel.pinTop(to: poolSizeSegmentControl.bottomAnchor, Constants.fieldSpacing)
        styleLabel.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        styleSegmentControl.pinTop(to: styleLabel.bottomAnchor, Constants.fieldSpacing / 2)
        styleSegmentControl.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        styleSegmentControl.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
        styleSegmentControl.setHeight(Constants.fieldHeight)
    }
    
    private func configureMetersSection() {
        metersLabel.text = Constants.metersSectionText
        metersLabel.textColor = Constants.titleColor
        metersTextField.backgroundColor = Constants.fieldBackgroundColor
        metersTextField.layer.cornerRadius = Constants.fieldCornerRadius
        metersTextField.textColor = Constants.titleColor
        metersTextField.textAlignment = .center
        metersTextField.placeholder = Constants.metersPlaceholder
        
        
        metersPicker.delegate = self
        metersPicker.dataSource = self
        metersTextField.inputView = metersPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(
            title: Constants.doneButtonTitle,
            style: .done,
            target: self,
            action: #selector(metersPickerDone)
        )
        
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        metersTextField.inputAccessoryView = toolbar
        
        if let firstOption = currentMetersOptions.first {
            metersTextField.text = "\(firstOption)"
        }
        
        metersLabel.translatesAutoresizingMaskIntoConstraints = false
        metersTextField.translatesAutoresizingMaskIntoConstraints = false
        metersLabel.pinTop(to: styleSegmentControl.bottomAnchor, Constants.fieldSpacing)
        metersLabel.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        metersTextField.pinTop(to: metersLabel.bottomAnchor, Constants.fieldSpacing / 2)
        metersTextField.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        metersTextField.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
        metersTextField.setHeight(Constants.fieldHeight)
    }
    
    private func configureDateSection() {
        dateLabel.text = Constants.dateSectionText
        dateLabel.textColor = Constants.titleColor
        
        dateTextField.backgroundColor = Constants.fieldBackgroundColor
        dateTextField.layer.cornerRadius = Constants.fieldCornerRadius
        dateTextField.textColor = Constants.titleColor
        dateTextField.textAlignment = .center
        dateTextField.placeholder = Constants.datePlaceholder
        
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .wheels
        dateTextField.inputView = datePicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(
            title: Constants.doneButtonTitle,
            style: .done,
            target: self,
            action: #selector(datePickerDone)
        )
        
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        dateTextField.inputAccessoryView = toolbar
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateTextField.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.pinTop(to: metersTextField.bottomAnchor, Constants.fieldSpacing)
        dateLabel.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        dateTextField.pinTop(to: dateLabel.bottomAnchor, Constants.fieldSpacing / 2)
        dateTextField.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        dateTextField.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
        dateTextField.setHeight(Constants.fieldHeight)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateTextField.text = dateFormatter.string(from: Date())
    }
    
    private func configureTimeSection() {
        timeLabel.text = Constants.timeSectionText
        timeLabel.textColor = Constants.titleColor
        timeTextField.backgroundColor = Constants.fieldBackgroundColor
        timeTextField.layer.cornerRadius = Constants.fieldCornerRadius
        timeTextField.textColor = Constants.titleColor
        timeTextField.textAlignment = .center
        timeTextField.placeholder = Constants.timePlaceholder
        
        timePicker.delegate = self
        timePicker.dataSource = self
        timeTextField.inputView = timePicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(
            title: Constants.doneButtonTitle,
            style: .done,
            target: self,
            action: #selector(timePickerDone)
        )
        
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        timeTextField.inputAccessoryView = toolbar
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeTextField.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.pinTop(to: dateTextField.bottomAnchor, Constants.fieldSpacing)
        timeLabel.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        timeTextField.pinTop(to: timeLabel.bottomAnchor, Constants.fieldSpacing / 2)
        timeTextField.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        timeTextField.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
        timeTextField.setHeight(Constants.fieldHeight)
    }
    
    private func configureLapsStackView() {
        lapsStackView.axis = .vertical
        lapsStackView.spacing = Constants.fieldSpacing
        lapsStackView.distribution = .fillEqually
        
        lapsStackView.translatesAutoresizingMaskIntoConstraints = false
        lapsStackView.pinTop(to: timeTextField.bottomAnchor, Constants.sectionSpacing)
        lapsStackView.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        lapsStackView.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
    }
    
    // MARK: - Keyboard Management
    private func configureKeyboardNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
            
            // Если активное текстовое поле скрыто клавиатурой, прокручиваем для его отображения
            if let activeField = findFirstResponder() {
                var aRect = view.frame
                aRect.size.height -= keyboardSize.height
                
                // Преобразуем координаты текстового поля в систему координат scroll view
                if let fieldRect = activeField.superview?.convert(activeField.frame, to: scrollView) {
                    if !aRect.contains(fieldRect.origin) {
                        // Прокручиваем, чтобы сделать поле видимым
                        scrollView.scrollRectToVisible(fieldRect, animated: true)
                    }
                }
            }
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
    }
    
    private func findFirstResponder() -> UIView? {
        // Проверяем каждое текстовое поле, чтобы найти первый responder
        if metersTextField.isFirstResponder {
            return metersTextField
        } else if dateTextField.isFirstResponder {
            return dateTextField
        } else if timeTextField.isFirstResponder {
            return timeTextField
        }
        
        // Проверяем текстовые поля отрезков
        for textField in lapTextFields where textField.isFirstResponder {
            return textField
        }
        
        return nil
    }
    
    private func setupTimePickerForTextField(_ textField: UITextField, picker: UIPickerView) {
        // Сохраняем активное текстовое поле и пикер
        activeTimeTextField = textField
        activeTimePicker = picker
        
        // Увеличиваем высоту пикера для лучшей видимости
        if let superView = picker.superview {
            // Проверяем, является ли это пикером для отрезков, чтобы сделать его еще больше
            let newHeight: CGFloat = lapTimePickers.contains(picker) ? 300 : 250
            var frame = superView.frame
            frame.size.height = newHeight
            superView.frame = frame
        }
        
        // Устанавливаем начальные значения, если время уже существует
        if let timeText = textField.text, timeText.count > 0 {
            if let time = parseTime(timeText) {
                let minutes = Int(time) / 60
                let seconds = Int(time) % 60
                let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
                
                // Устанавливаем пикер на текущие значения
                if minutes < minutesRange.count {
                    picker.selectRow(minutes, inComponent: 0, animated: false)
                }
                if seconds < secondsRange.count {
                    picker.selectRow(seconds, inComponent: 1, animated: false)
                }
                if milliseconds < millisecondsRange.count {
                    picker.selectRow(milliseconds, inComponent: 2, animated: false)
                }
            }
        } else {
            // По умолчанию ставим нули
            picker.selectRow(0, inComponent: 0, animated: false)
            picker.selectRow(0, inComponent: 1, animated: false)
            picker.selectRow(0, inComponent: 2, animated: false)
        }
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func doneButtonTapped() {
        view.endEditing(true)
    }
    
    @objc private func datePickerDone() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        dateTextField.text = dateFormatter.string(from: datePicker.date)
        view.endEditing(true)
    }
    
    @objc private func metersPickerDone() {
        let selectedRow = metersPicker.selectedRow(inComponent: 0)
        if currentMetersOptions.indices.contains(selectedRow) {
            metersTextField.text = "\(currentMetersOptions[selectedRow])"
            
            // Автоматически пересчитываем отрезки при изменении метража
            calculateLaps()
        }
        view.endEditing(true)
    }
    
    @objc private func timePickerDone() {
        // Убедимся, что мы обновляем только то поле, по которому было нажатие
        if let activeField = activeTimeTextField, let activePicker = activeTimePicker {
            let minutes = minutesRange[activePicker.selectedRow(inComponent: 0)]
            let seconds = secondsRange[activePicker.selectedRow(inComponent: 1)]
            let milliseconds = millisecondsRange[activePicker.selectedRow(inComponent: 2)]
            
            activeField.text = String(format: "%02d:%02d,%02d", minutes, seconds, milliseconds)
        }
        
        view.endEditing(true)
        activeTimePicker = nil
        activeTimeTextField = nil
    }
    
    @objc private func updateMetersOptions() {
        // Обновляем пикер с новыми опциями
        metersPicker.reloadAllComponents()
        
        // Обновляем текстовое поле первым значением из нового списка
        if let firstOption = currentMetersOptions.first {
            metersTextField.text = "\(firstOption)"
        }
        
        // Автоматически пересчитываем отрезки при изменении стиля (что может влиять на метраж)
        calculateLaps()
    }
    
    @objc private func poolSizeOrMetersChanged() {
        // Автоматически пересчитываем отрезки при изменении размера бассейна
        calculateLaps()
    }
    
    private func calculateLaps() {
        guard let metersText = metersTextField.text, !metersText.isEmpty,
              let totalMeters = Int16(metersText) else {
            return
        }
        
        let poolSize: Int16 = poolSizeSegmentControl.selectedSegmentIndex == 0 ? 25 : 50
        
        let request = DiaryCreateStartModels.CalculateLaps.Request(
            poolSize: poolSize,
            totalMeters: totalMeters
        )
        
        interactor?.calculateLaps(request: request)
    }
    
    @objc private func saveButtonTapped() {
        // Собираем все данные формы
        let poolSize: Int16 = poolSizeSegmentControl.selectedSegmentIndex == 0 ? 25 : 50
        let swimmingStyle: Int16 = Int16(styleSegmentControl.selectedSegmentIndex)
        
        // Собираем тексты времени отрезков
        var lapTimeTexts: [String] = []
        for textField in lapTextFields {
            if let text = textField.text {
                lapTimeTexts.append(text)
            } else {
                lapTimeTexts.append("")
            }
        }
        
        // Отправляем данные в интерактор для валидации
        let request = DiaryCreateStartModels.CollectData.Request(
            poolSize: poolSize,
            swimmingStyle: swimmingStyle,
            totalMetersText: metersTextField.text ?? "",
            dateText: dateTextField.text ?? "",
            totalTimeText: timeTextField.text ?? "",
            lapTimeTexts: lapTimeTexts
        )
        
        interactor?.collectAndValidateData(request: request)
    }
    
    // MARK: - Helper Methods
    private func parseTime(_ timeString: String) -> Double? {
        let components = timeString.components(separatedBy: CharacterSet(charactersIn: ":,"))
        guard components.count == 3,
              let minutes = Double(components[0]),
              let seconds = Double(components[1]),
              let milliseconds = Double(components[2]) else {
            return nil
        }
        
        return minutes * 60 + seconds + milliseconds / 100
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(
            title: Constants.alertTitle,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(
            title: Constants.alertButtonTitle,
            style: .default
        ))
        
        present(alert, animated: true)
    }
    
    private func setupLapInputFields() {
        // Очищаем существующие поля
        for view in lapsStackView.arrangedSubviews {
            lapsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        lapTextFields.removeAll()
        lapTimePickers.removeAll()
        
        // Добавляем поля для каждого отрезка
        for i in 1...numberOfLaps {
            let label = UILabel()
            label.text = "Отрезок \(i):"
            label.textColor = Constants.titleColor
            
            let textField = UITextField()
            textField.backgroundColor = Constants.fieldBackgroundColor
            textField.layer.cornerRadius = Constants.fieldCornerRadius
            textField.textColor = Constants.titleColor
            textField.textAlignment = .center
            textField.placeholder = "00:00,00"
            textField.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            
            // Устанавливаем ограничение высоты для текстового поля (делаем его выше)
            textField.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            // Создаем пользовательский пикер времени для этого отрезка
            let lapTimePicker = UIPickerView()
            lapTimePicker.delegate = self
            lapTimePicker.dataSource = self
            textField.inputView = lapTimePicker
            
            // Добавляем этот пикер в наш массив
            lapTimePickers.append(lapTimePicker)
            
            // Настраиваем обработчики фокуса/размытия
            textField.addTarget(self, action: #selector(lapTimeFieldFocused(_:)), for: .editingDidBegin)
            
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            
            let doneButton = UIBarButtonItem(
                title: Constants.doneButtonTitle,
                style: .done,
                target: self,
                action: #selector(timePickerDone)
            )
            
            let flexibleSpace = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil
            )
            
            toolbar.setItems([flexibleSpace, doneButton], animated: false)
            textField.inputAccessoryView = toolbar
            
            let stackView = UIStackView(arrangedSubviews: [label, textField])
            stackView.axis = .horizontal
            stackView.spacing = Constants.fieldSpacing
            stackView.distribution = .fillEqually
            
            // Устанавливаем отступы для всей строки
            stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
            stackView.isLayoutMarginsRelativeArrangement = true
            
            lapsStackView.addArrangedSubview(stackView)
            lapTextFields.append(textField)
        }
    }
    
    @objc private func lapTimeFieldFocused(_ textField: UITextField) {
        // Находим, какой пикер соответствует этому текстовому полю
        if let index = lapTextFields.firstIndex(of: textField), index < lapTimePickers.count {
            setupTimePickerForTextField(textField, picker: lapTimePickers[index])
        }
    }
}

// MARK: - DiaryCreateStartDisplayLogic
extension DiaryCreateStartViewController: DiaryCreateStartDisplayLogic {
    func displayStartCreated(viewModel: DiaryCreateStartModels.Create.ViewModel) {
        if viewModel.success {
            router?.routeToDiary()
        } else {
            showAlert(message: viewModel.message)
        }
    }
    
    func displayLapCount(viewModel: DiaryCreateStartModels.CalculateLaps.ViewModel) {
        numberOfLaps = viewModel.numberOfLaps
        setupLapInputFields()
    }
    
    func displayCollectedData(viewModel: DiaryCreateStartModels.CollectData.ViewModel) {
        if viewModel.success {
            // Если валидация успешна, создаем старт
            if let request = viewModel.createRequest {
                interactor?.createStart(request: request)
            }
        } else if let errorMessage = viewModel.errorMessage {
            // Показываем сообщение об ошибке
            showAlert(message: errorMessage)
        }
    }
}

// MARK: - UIPickerViewDelegate, UIPickerViewDataSource
extension DiaryCreateStartViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == metersPicker {
            return 1
        } else {
            // Пикер времени (минуты, секунды, миллисекунды)
            return 3
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == metersPicker {
            return currentMetersOptions.count
        } else {
            // Пикер времени
            switch component {
            case 0: return minutesRange.count // Минуты
            case 1: return secondsRange.count // Секунды
            case 2: return millisecondsRange.count // Миллисекунды
            default: return 0
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == metersPicker {
            if currentMetersOptions.indices.contains(row) {
                return "\(currentMetersOptions[row]) м"
            }
            return nil
        } else {
            // Пикер времени
            switch component {
            case 0:
                if minutesRange.indices.contains(row) {
                    return String(format: "%02d", minutesRange[row])
                }
            case 1:
                if secondsRange.indices.contains(row) {
                    return String(format: "%02d", secondsRange[row])
                }
            case 2:
                if millisecondsRange.indices.contains(row) {
                    return String(format: "%02d", millisecondsRange[row])
                }
            default: break
            }
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == metersPicker {
            if currentMetersOptions.indices.contains(row) {
                metersTextField.text = "\(currentMetersOptions[row])"
            }
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if pickerView == metersPicker {
            // Пикер метража - просто используем стандартный вид
            let label = UILabel()
            if currentMetersOptions.indices.contains(row) {
                label.text = "\(currentMetersOptions[row]) м"
            }
            label.textAlignment = .center
            label.textColor = Constants.titleColor
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            return label
        } else {
            // Пикер времени - пользовательские обозначенные представления для каждого компонента
            let label = UILabel()
            label.textAlignment = .center
            label.textColor = Constants.titleColor
            
            // Используем более крупный шрифт для пикеров времени отрезков
            if lapTimePickers.contains(pickerView) {
                label.font = UIFont.systemFont(ofSize: 24, weight: .medium)
            } else {
                label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            }
            
            switch component {
            case 0:
                if minutesRange.indices.contains(row) {
                    label.text = String(format: "%02d", minutesRange[row])
                }
            case 1:
                if secondsRange.indices.contains(row) {
                    label.text = String(format: "%02d", secondsRange[row])
                }
            case 2:
                if millisecondsRange.indices.contains(row) {
                    label.text = String(format: "%02d", millisecondsRange[row])
                }
            default:
                label.text = ""
            }
            
            return label
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        if pickerView == metersPicker {
            return pickerView.frame.width
        } else {
            // Пикер времени - одинаковая ширина для всех компонентов
            return pickerView.frame.width / 3
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        if lapTimePickers.contains(pickerView) {
            return 50 // Еще большая высота строки для пикеров времени отрезков
        } else {
            return 40 // Стандартная увеличенная высота строки для других пикеров
        }
    }
}
