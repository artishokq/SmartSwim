//
//  DiaryViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit
import CoreData

protocol DiaryDisplayLogic: AnyObject {
    func displayStarts(viewModel: DiaryModels.FetchStarts.ViewModel)
    func displayDeleteStart(viewModel: DiaryModels.DeleteStart.ViewModel)
    func displayStartDetail(viewModel: DiaryModels.ShowStartDetail.ViewModel)
    func displayCreateStart(viewModel: DiaryModels.CreateStart.ViewModel)
}

final class DiaryViewController: UIViewController, DiaryDisplayLogic {
    // MARK: - Constants
    private enum Constants {
        static let backgroundColor = UIColor(hexString: "#242531")
        static let diaryTabBarTitle: String = "Дневник"
        static let diaryTitle: String = "Дневник"
        
        static let tableViewLeftPadding: CGFloat = 16
        static let tableViewRightPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 14
        static let sectionHeaderTopPadding: CGFloat = 0
        
        static let deleteAlertTitle: String = "Удалить старт?"
        static let deleteAlertMessage: String = "Данное действие нельзя отменить."
        static let deleteAlertConfirm: String = "Удалить"
        static let deleteAlertCancel: String = "Отмена"
    }
    
    // MARK: - Enum for display mode
    enum DisplayMode {
        case workouts
        case starts
    }
    
    // MARK: - Properties
    var interactor: DiaryBusinessLogic?
    var router: (NSObjectProtocol & DiaryRoutingLogic & DiaryDataPassing)?
    
    private var displayedStarts: [DiaryModels.FetchStarts.ViewModel.DisplayedStart] = []
    private var displayMode: DisplayMode = .starts {
        didSet {
            updateUIForDisplayMode()
        }
    }
    
    private let tableView = UITableView()
    private let workoutButton = UIButton(type: .custom)
    private let startButton = UIButton(type: .custom)
    private let createButton = UIButton(type: .custom)
    
    // MARK: - Initialization
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleStartCreation),
            name: .didCreateStart,
            object: nil
        )
        configureUI()
        displayMode = .starts
        fetchStarts()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if displayMode == .starts {
            fetchStarts()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Configurations
    private func configure() {
        let viewController = self
        let interactor = DiaryInteractor()
        let presenter = DiaryPresenter()
        let router = DiaryRouter()
        
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
        router.dataStore = interactor
    }
    
    private func configureUI() {
        view.backgroundColor = Constants.backgroundColor
        title = Constants.diaryTitle
        navigationController?.tabBarItem.title = Constants.diaryTabBarTitle
        view.addSubview(tableView)
        
        configureWorkoutButton()
        configureStartButton()
        configureCreateButton()
        configureTableView()
        
        let workoutBarButton = UIBarButtonItem(customView: workoutButton)
        let startBarButton = UIBarButtonItem(customView: startButton)
        let createBarButton = UIBarButtonItem(customView: createButton)
        
        navigationItem.rightBarButtonItems = [startBarButton, workoutBarButton]
        navigationItem.leftBarButtonItem = createBarButton
    }
    
    private func configureWorkoutButton() {
        workoutButton.setImage(UIImage(named: "workoutOff"), for: .normal)
        workoutButton.addTarget(self, action: #selector(workoutButtonTapped), for: .touchUpInside)
    }
    
    private func configureStartButton() {
        startButton.setImage(UIImage(named: "startOn"), for: .normal)
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
    }
    
    private func configureCreateButton() {
        createButton.setImage(UIImage(named: "createButton"), for: .normal)
        createButton.addTarget(self, action: #selector(createButtonTapped), for: .touchUpInside)
    }
    
    private func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DiaryStartCell.self, forCellReuseIdentifier: DiaryStartCell.identifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = Constants.sectionHeaderTopPadding
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.pinTop(to: view.safeAreaLayoutGuide.topAnchor)
        tableView.pinLeft(to: view.leadingAnchor, Constants.tableViewLeftPadding)
        tableView.pinRight(to: view.trailingAnchor, Constants.tableViewRightPadding)
        tableView.pinBottom(to: view.bottomAnchor)
    }
    
    private func updateUIForDisplayMode() {
        switch displayMode {
        case .workouts:
            workoutButton.setImage(UIImage(named: "workoutOn"), for: .normal)
            startButton.setImage(UIImage(named: "startOff"), for: .normal)
            tableView.isHidden = true
            
        case .starts:
            workoutButton.setImage(UIImage(named: "workoutOff"), for: .normal)
            startButton.setImage(UIImage(named: "startOn"), for: .normal)
            tableView.isHidden = false
            fetchStarts()
        }
        createButton.isHidden = displayMode != .starts
    }
    
    // MARK: - Actions
    @objc private func workoutButtonTapped() {
        displayMode = .workouts
    }
    
    @objc private func startButtonTapped() {
        displayMode = .starts
    }
    
    @objc private func createButtonTapped() {
        let request = DiaryModels.CreateStart.Request()
        interactor?.createStart(request: request)
    }
    
    @objc private func handleStartCreation() {
        if displayMode == .starts {
            fetchStarts()
        }
    }
    
    // MARK: - Business Logic
    private func fetchStarts() {
        let request = DiaryModels.FetchStarts.Request()
        interactor?.fetchStarts(request: request)
    }
    
    // MARK: - Display Logic
    func displayStarts(viewModel: DiaryModels.FetchStarts.ViewModel) {
        displayedStarts = viewModel.starts
        tableView.reloadData()
    }
    
    func displayDeleteStart(viewModel: DiaryModels.DeleteStart.ViewModel) {
        displayedStarts.remove(at: viewModel.index)
        tableView.deleteSections(IndexSet(integer: viewModel.index), with: .automatic)
    }
    
    func displayStartDetail(viewModel: DiaryModels.ShowStartDetail.ViewModel) {
        router?.routeToStartDetail(startID: viewModel.startID)
    }
    
    func displayCreateStart(viewModel: DiaryModels.CreateStart.ViewModel) {
        router?.routeToCreateStart()
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension DiaryViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return displayedStarts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.sectionSpacing
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DiaryStartCell.identifier,
            for: indexPath
        ) as? DiaryStartCell else {
            return UITableViewCell()
        }
        
        let start = displayedStarts[indexPath.section]
        cell.configure(with: start)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let start = displayedStarts[indexPath.section]
        let request = DiaryModels.ShowStartDetail.Request(startID: start.id)
        interactor?.showStartDetail(request: request)
    }
}

// MARK: - DiaryStartCellDelegate
extension DiaryViewController: DiaryStartCellDelegate {
    func startCellDidRequestDeletion(_ cell: DiaryStartCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        let alert = UIAlertController(
            title: Constants.deleteAlertTitle,
            message: Constants.deleteAlertMessage,
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: Constants.deleteAlertConfirm, style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            let startID = self.displayedStarts[indexPath.section].id
            let request = DiaryModels.DeleteStart.Request(id: startID, index: indexPath.section)
            self.interactor?.deleteStart(request: request)
        }
        
        let cancelAction = UIAlertAction(title: Constants.deleteAlertCancel, style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
}
