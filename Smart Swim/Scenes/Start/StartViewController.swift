//
//  StartViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

protocol StartDisplayLogic: AnyObject {
    func displayContinue(viewModel: StartModels.Continue.ViewModel)
}

final class StartViewController: UIViewController, StartDisplayLogic {
    // MARK: - Constants
    private enum Constants {
        static let backgroundColor = UIColor(hexString: "#242531")
        static let startBackgroundColor = UIColor(hexString: "#323645")
        static let fieldsBackgroundColor = UIColor(hexString: "#323645")
        static let createCellBackgroundColor = UIColor(hexString: "#505773")
        static let blueColor = UIColor(hexString: "#0A84FF")
        static let titleWhite = UIColor(hexString: "#FFFFFF") ?? .white
        static let fieldsAndPlaceholdersFont = UIFont.systemFont(ofSize: 18, weight: .light)
        static let startTitle = "Старт"
        static let title: String = "Контрольный старт"
        
        static let backgroundViewCornerRadius: CGFloat = 20
        static let backgroundViewLeftPadding: CGFloat = 16
        static let backgroundViewRightPadding: CGFloat = 16
        
        static let poolSizeItems: [String] = ["25м", "50м"]
        static let poolSizeSegmentControlCornerRadius: CGFloat = 9
        static let poolSizeSegmentControlTopPadding: CGFloat = 12
        static let poolSizeSegmentControlLeftPadding: CGFloat = 12
        static let poolSizeSegmentControlRightPadding: CGFloat = 12
        static let poolSizeSegmentControlHeight: CGFloat = 42
        
        static let styleItems: [String] = ["Кроль", "Брасс", "Спина", "Батт", "К/П"]
        static let styleSegmentControlCornerRadius: CGFloat = 9
        static let styleSegmentControlTopPadding: CGFloat = 16
        static let styleSegmentControlLeftPadding: CGFloat = 12
        static let styleSegmentControlRightPadding: CGFloat = 12
        static let styleSegmentControlHeight: CGFloat = 42
        
        static let metersPlaceholder: String = "Метры"
        static let metersTextFieldTopPadding: CGFloat = 16
        static let metersTextFieldLeftPadding: CGFloat = 12
        static let metersTextFieldRightPadding: CGFloat = 12
        static let metersTextFieldHeight: CGFloat = 42
        static let metersTextFieldCornerRadius: CGFloat = 9
        
        static let toolBarDoneButton: String = "Готово"
        
        static let continueButtonTitle: String = "Продолжить"
        static let continueButtonTitleFont: UIFont = .systemFont(ofSize: 17, weight: .medium)
        static let continueButtonTitleColor: UIColor = .white
        static let continueButtonCornerRadius: CGFloat = 9
        static let continueButtonHeight: CGFloat = 42
        static let continueButtonWidth: CGFloat = 180
        static let continueButtonTopPadding: CGFloat = 16
        static let continueButtonBottomPadding: CGFloat = 12
    }
    
    // MARK: - Fields
    var interactor: StartBusinessLogic?
    var router: (NSObjectProtocol & StartRoutingLogic & StartDataPassing)?
    
    private let backgroundView: UIView = UIView()
    private let poolSizeSegmentControl: UISegmentedControl = UISegmentedControl()
    private let styleSegmentControl: UISegmentedControl = UISegmentedControl()
    private let metersTextField: UITextField = UITextField()
    private let metersPicker: UIPickerView = UIPickerView()
    private let continueButton: UIButton = UIButton(type: .system)
    
    private var currentMeterValues: [Int] {
        let styleIndex = styleSegmentControl.selectedSegmentIndex
        let poolSizeIndex = poolSizeSegmentControl.selectedSegmentIndex
        switch styleIndex {
        case 0: // Кроль
            return [50, 100, 200, 400, 800, 1500]
        case 1, 2, 3: // Брасс, Спина, Батт
            return [50, 100, 200]
        case 4: // К/П
            if poolSizeIndex == 0 { // 25м
                return [100, 200, 400]
            } else { // 50м
                return [200, 400]
            }
        default:
            return []
        }
    }
    
    // MARK: - Object lifecycle
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - Configurations
    private func configure() {
        let viewController = self
        let interactor = StartInteractor()
        let presenter = StartPresenter()
        let router = StartRouter()
        
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    private func configureUI() {
        view.backgroundColor = Constants.backgroundColor
        title = Constants.title
        navigationController?.tabBarItem.title = Constants.startTitle
        
        view.addSubview(backgroundView)
        backgroundView.addSubview(poolSizeSegmentControl)
        backgroundView.addSubview(styleSegmentControl)
        backgroundView.addSubview(metersTextField)
        backgroundView.addSubview(continueButton)
        
        backgroundViewConfiguration()
        poolSizeSegmentControlConfiguration()
        styleSegmentControlConfiguration()
        metersTextFieldConfiguration()
        continueButtonConfiguration()
        configureActions()
    }
    
    private func backgroundViewConfiguration() {
        backgroundView.backgroundColor = Constants.startBackgroundColor
        backgroundView.layer.cornerRadius = Constants.backgroundViewCornerRadius
        
        // Констрейнты
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.pinRight(to: view.trailingAnchor, Constants.backgroundViewRightPadding)
        backgroundView.pinLeft(to: view.leadingAnchor, Constants.backgroundViewLeftPadding)
        backgroundView.pinCenterY(to: view.centerYAnchor)
    }
    
    private func poolSizeSegmentControlConfiguration() {
        poolSizeSegmentControl.removeAllSegments()
        for (index, title) in Constants.poolSizeItems.enumerated() {
            poolSizeSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        poolSizeSegmentControl.selectedSegmentIndex = 0
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.titleWhite,
            .font: Constants.fieldsAndPlaceholdersFont
        ]
        
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.titleWhite,
            .font: Constants.fieldsAndPlaceholdersFont
        ]
        
        poolSizeSegmentControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        poolSizeSegmentControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        poolSizeSegmentControl.layer.cornerRadius = Constants.poolSizeSegmentControlCornerRadius
        poolSizeSegmentControl.backgroundColor = Constants.fieldsBackgroundColor
        poolSizeSegmentControl.selectedSegmentTintColor = Constants.blueColor
        
        poolSizeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        poolSizeSegmentControl.pinTop(to: backgroundView.topAnchor, Constants.poolSizeSegmentControlTopPadding)
        poolSizeSegmentControl.pinLeft(to: backgroundView.leadingAnchor, Constants.poolSizeSegmentControlLeftPadding)
        poolSizeSegmentControl.pinRight(to: backgroundView.trailingAnchor, Constants.poolSizeSegmentControlRightPadding)
        poolSizeSegmentControl.setHeight(Constants.poolSizeSegmentControlHeight)
    }
    
    private func styleSegmentControlConfiguration() {
        styleSegmentControl.removeAllSegments()
        for (index, title) in Constants.styleItems.enumerated() {
            styleSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        styleSegmentControl.selectedSegmentIndex = 0
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.titleWhite,
            .font: Constants.fieldsAndPlaceholdersFont
        ]
        
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.titleWhite,
            .font: Constants.fieldsAndPlaceholdersFont
        ]
        
        styleSegmentControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        styleSegmentControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        styleSegmentControl.layer.cornerRadius = Constants.styleSegmentControlCornerRadius
        styleSegmentControl.backgroundColor = Constants.fieldsBackgroundColor
        styleSegmentControl.selectedSegmentTintColor = Constants.blueColor
        
        styleSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        styleSegmentControl.pinTop(to: poolSizeSegmentControl.bottomAnchor, Constants.styleSegmentControlTopPadding)
        styleSegmentControl.pinLeft(to: backgroundView.leadingAnchor, Constants.styleSegmentControlLeftPadding)
        styleSegmentControl.pinRight(to: backgroundView.trailingAnchor, Constants.styleSegmentControlRightPadding)
        styleSegmentControl.setHeight(Constants.styleSegmentControlHeight)
    }
    
    private func metersTextFieldConfiguration() {
        metersTextField.backgroundColor = Constants.createCellBackgroundColor
        metersTextField.layer.cornerRadius = Constants.metersTextFieldCornerRadius
        metersTextField.textColor = Constants.titleWhite
        metersTextField.font = Constants.fieldsAndPlaceholdersFont
        metersTextField.placeholder = Constants.metersPlaceholder
        metersTextField.textAlignment = .center
        
        // Назначаем делегат и dataSource для UIPickerView
        metersPicker.delegate = self
        metersPicker.dataSource = self
        metersTextField.inputView = metersPicker
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let doneButton = UIBarButtonItem(
            title: Constants.toolBarDoneButton,
            style: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
        
        doneButton.tintColor = Constants.blueColor
        
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        toolbar.setItems([flexibleSpace, doneButton], animated: false)
        metersTextField.inputAccessoryView = toolbar
        
        metersTextField.translatesAutoresizingMaskIntoConstraints = false
        metersTextField.pinTop(to: styleSegmentControl.bottomAnchor, Constants.metersTextFieldTopPadding)
        metersTextField.pinLeft(to: backgroundView.leadingAnchor, Constants.metersTextFieldLeftPadding)
        metersTextField.pinRight(to: backgroundView.trailingAnchor, Constants.metersTextFieldRightPadding)
        metersTextField.setHeight(Constants.metersTextFieldHeight)
    }
    
    private func continueButtonConfiguration() {
        continueButton.backgroundColor = Constants.blueColor
        continueButton.setTitle(Constants.continueButtonTitle, for: .normal)
        continueButton.titleLabel?.font = Constants.continueButtonTitleFont
        continueButton.setTitleColor(Constants.continueButtonTitleColor, for: .normal)
        continueButton.layer.cornerRadius = Constants.continueButtonCornerRadius
        
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.pinBottom(to: backgroundView.bottomAnchor, Constants.continueButtonBottomPadding)
        continueButton.pinTop(to: metersTextField.bottomAnchor, Constants.continueButtonTopPadding)
        continueButton.pinCenterX(to: backgroundView.centerXAnchor)
        continueButton.setWidth(Constants.continueButtonWidth)
        continueButton.setHeight(Constants.continueButtonHeight)
    }
    
    // MARK: - Actions
    private func configureActions() {
        // При изменении выбора в любом из UISegmentedControl обновляем набор метражей
        poolSizeSegmentControl.addTarget(self, action: #selector(segmentControlChanged), for: .valueChanged)
        styleSegmentControl.addTarget(self, action: #selector(segmentControlChanged), for: .valueChanged)
        continueButton.addTarget(self, action: #selector(continueButtonTapped), for: .touchUpInside)
    }
    
    @objc private func segmentControlChanged() {
        metersPicker.reloadAllComponents()
        // Устанавливаем значение по умолчанию (первый доступный метраж)
        if let firstValue = currentMeterValues.first {
            metersTextField.text = "\(firstValue) м"
            metersPicker.selectRow(0, inComponent: 0, animated: true)
        } else {
            metersTextField.text = ""
        }
    }
    
    @objc private func doneButtonTapped() {
        let selectedRow = metersPicker.selectedRow(inComponent: 0)
        if selectedRow < currentMeterValues.count {
            metersTextField.text = "\(currentMeterValues[selectedRow]) м"
        }
        metersTextField.resignFirstResponder()
    }
    
    @objc private func continueButtonTapped() {
        guard let metersText = metersTextField.text,
              let totalMeters = Int(metersText.components(separatedBy: " ").first ?? "") else { return }
        
        let poolSize = poolSizeSegmentControl.selectedSegmentIndex == 0 ? 25 : 50
        let selectedIndex = styleSegmentControl.selectedSegmentIndex
        let swimmingStyle = Constants.styleItems[selectedIndex]
        
        let request = StartModels.Continue.Request(totalMeters: totalMeters,
                                                   poolSize: poolSize,
                                                   swimmingStyle: swimmingStyle)
        interactor?.continueAction(request: request)
    }
    
    // MARK: - StartDisplayLogic
    func displayContinue(viewModel: StartModels.Continue.ViewModel) {
        router?.routeToStopwatch()
    }
}

// MARK: - UIPickerViewDelegate & UIPickerViewDataSource
extension StartViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return currentMeterValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let title = "\(currentMeterValues[row]) м"
        return NSAttributedString(
            string: title,
            attributes: [
                .foregroundColor: Constants.titleWhite,
                .font: Constants.fieldsAndPlaceholdersFont
            ]
        )
    }
}
