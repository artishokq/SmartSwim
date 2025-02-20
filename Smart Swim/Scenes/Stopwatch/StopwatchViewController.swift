//
//  StopwatchViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.02.2025.
//

import UIKit
import HealthKit

protocol StopwatchDisplayLogic: AnyObject {
    func displayTimerTick(viewModel: StopwatchModels.TimerTick.ViewModel)
    func displayMainButtonAction(viewModel: StopwatchModels.MainButtonAction.ViewModel)
    func displayLapRecording(viewModel: StopwatchModels.LapRecording.ViewModel)
    func displayFinish(viewModel: StopwatchModels.Finish.ViewModel)
}

final class StopwatchViewController: UIViewController, StopwatchDisplayLogic {
    // MARK: - Constants
    private enum Constants {
        static let title: String = "Секундомер"
        static let backgroundColor: UIColor = UIColor(hexString: "#242531") ?? .systemBlue
        
        static let timerLabelText: String = "00:00,00"
        static let timerLabelFont: UIFont = UIFont.monospacedDigitSystemFont(ofSize: 80, weight: .light)
        static let timerLabelTopPadding: CGFloat = 70
        
        static let mainButtonTitle: String = "Старт"
        static let mainButtonBackgroundColor: UIColor = UIColor(hexString: "#34C92C") ?? .systemGreen
        static let mainButtonTitleColor: UIColor = .white
        static let mainButtonCornerRadius: CGFloat = 10
        static let mainButtonTitleFont: UIFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let mainButtonTopPadding: CGFloat = 50
        static let mainButtonWidth: CGFloat = 200
        static let mainButtonHeight: CGFloat = 50
        
        static let lapsTableViewTopPadding: CGFloat = 50
    }
    
    // MARK: - Fields
    var interactor: StopwatchBusinessLogic?
    var router: (NSObjectProtocol & StopwatchRoutingLogic & StopwatchDataPassing)?
    
    private let timerLabel: UILabel = UILabel()
    private let mainButton: UIButton = UIButton()
    private let lapsTableView: UITableView = UITableView()
    
    // Локальное хранилище для отрезков; последний элемент соответствует активному отрезку
    private var laps: [StopwatchModels.LapRecording.ViewModel] = []
    private var healthStore = HKHealthStore()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        ConfigureUI()
        requestHealthKitAuthorization()
    }
    
    // MARK: - Configurations
    private func ConfigureUI() {
        view.backgroundColor = Constants.backgroundColor
        title = Constants.title
        
        view.addSubview(timerLabel)
        view.addSubview(mainButton)
        view.addSubview(lapsTableView)
        
        configureTimerLabel()
        configureMainButton()
        configureLapsTableView()
    }
    
    private func configureTimerLabel() {
        timerLabel.text = Constants.timerLabelText
        timerLabel.font = Constants.timerLabelFont
        timerLabel.textAlignment = .center
        
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.pinTop(to: view.safeAreaLayoutGuide.topAnchor, Constants.timerLabelTopPadding)
        timerLabel.pinCenterX(to: view.centerXAnchor)
    }
    
    private func configureMainButton() {
        mainButton.setTitle(Constants.mainButtonTitle, for: .normal)
        mainButton.backgroundColor = Constants.mainButtonBackgroundColor
        mainButton.setTitleColor(Constants.mainButtonTitleColor, for: .normal)
        mainButton.titleLabel?.font = Constants.mainButtonTitleFont
        mainButton.layer.cornerRadius = Constants.mainButtonCornerRadius
        
        mainButton.addTarget(self, action: #selector(mainButtonTapped), for: .touchUpInside)
        mainButton.translatesAutoresizingMaskIntoConstraints = false
        mainButton.pinTop(to: timerLabel.bottomAnchor, Constants.mainButtonTopPadding)
        mainButton.pinCenterX(to: view.centerXAnchor)
        mainButton.setWidth(Constants.mainButtonWidth)
        mainButton.setHeight(Constants.mainButtonHeight)
    }
    
    private func configureLapsTableView() {
        lapsTableView.register(UITableViewCell.self, forCellReuseIdentifier: "LapCell")
        lapsTableView.dataSource = self
        lapsTableView.backgroundColor = Constants.backgroundColor
        lapsTableView.translatesAutoresizingMaskIntoConstraints = false
        lapsTableView.pinTop(to: mainButton.bottomAnchor, Constants.lapsTableViewTopPadding)
        lapsTableView.pinBottom(to: view.safeAreaLayoutGuide.bottomAnchor)
        lapsTableView.pinLeft(to: view.leadingAnchor)
        lapsTableView.pinRight(to: view.trailingAnchor)
    }
    
    // MARK: - Actions
    @objc private func mainButtonTapped() {
        let request = StopwatchModels.MainButtonAction.Request()
        interactor?.handleMainButtonAction(request: request)
    }
    
    // MARK: - Display Logic
    func displayTimerTick(viewModel: StopwatchModels.TimerTick.ViewModel) {
        // Обновляем общий таймер (верхняя метка)
        timerLabel.text = viewModel.formattedGlobalTime
        
        // Если в списке отрезков есть активный (последний), обновляем его время
        if !laps.isEmpty {
            var activeLap = laps[laps.count - 1]
            activeLap.lapTimeString = viewModel.formattedActiveLapTime
            laps[laps.count - 1] = activeLap
            
            let indexPath = IndexPath(row: laps.count - 1, section: 0)
            lapsTableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    func displayMainButtonAction(viewModel: StopwatchModels.MainButtonAction.ViewModel) {
        mainButton.setTitle(viewModel.buttonTitle, for: .normal)
        mainButton.backgroundColor = viewModel.buttonColor
    }
    
    func displayLapRecording(viewModel: StopwatchModels.LapRecording.ViewModel) {
        if let index = laps.firstIndex(where: { $0.lapNumber == viewModel.lapNumber }) {
            laps[index] = viewModel
            let indexPath = IndexPath(row: index, section: 0)
            lapsTableView.reloadRows(at: [indexPath], with: .none)
        } else {
            laps.append(viewModel)
            let indexPath = IndexPath(row: laps.count - 1, section: 0)
            lapsTableView.insertRows(at: [indexPath], with: .automatic)
        }
    }
    
    func displayFinish(viewModel: StopwatchModels.Finish.ViewModel) {
        mainButton.setTitle(viewModel.buttonTitle, for: .normal)
        mainButton.backgroundColor = viewModel.buttonColor
        mainButton.isEnabled = false
    }
    
    // MARK: - Public Methods
    // Запрашиваем разрешение на доступ к HealthKit
    func requestHealthKitAuthorization() {
        let swimmingStrokes = HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!
        let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        healthStore.requestAuthorization(toShare: [], read: [swimmingStrokes, heartRate]) { (success, error) in
            if success {
                print("HealthKit Authorization successful.")
            } else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension StopwatchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return laps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LapCell", for: indexPath)
        let lap = laps[indexPath.row]
        cell.backgroundColor = Constants.backgroundColor
        cell.textLabel?.text = "Отрезок \(lap.lapNumber):  \(lap.lapTimeString)"
        return cell
    }
}
