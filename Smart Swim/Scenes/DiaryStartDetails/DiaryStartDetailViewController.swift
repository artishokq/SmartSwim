//
//  DiaryStartDetailViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import UIKit
import CoreData

protocol DiaryStartDetailDisplayLogic: AnyObject {
    func displayStartDetails(viewModel: DiaryStartDetailModels.FetchStartDetails.ViewModel)
    func displayRecommendationLoading(viewModel: DiaryStartDetailModels.RecommendationLoading.ViewModel)
    func displayRecommendationReceived(viewModel: DiaryStartDetailModels.RecommendationReceived.ViewModel)
}

final class DiaryStartDetailViewController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let backgroundColor = UIColor(hexString: "#242531")
        static let contentBackgroundColor = UIColor(hexString: "#323645")
        static let headerBackgroundColor = UIColor(hexString: "#323645")
        static let tableBackgroundColor = UIColor(hexString: "#323645")
        static let recommendationBackgroundColor = UIColor(hexString: "#323645")
        static let textColor = UIColor(hexString: "#FFFFFF")
        static let comparisonColor = UIColor(hexString: "#FF4F4F")
        static let tableHeaderColor = UIColor(hexString: "#505773")
        static let separatorColor = UIColor(hexString: "#4C507B")
        
        static let contentPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 20
        static let tableCellHeight: CGFloat = 50
        static let tableHeaderHeight: CGFloat = 50
        static let robotImageSize: CGFloat = 24
        static let robotImageOffset: CGFloat = 8
        
        static let titleText: String = "Детали старта"
        static let recommendationTitleText: String = "Рекомендация от ИИ"
        
        static let distanceStyleFont: UIFont = UIFont.systemFont(ofSize: 24, weight: .medium)
        static let totalTimeFont: UIFont = UIFont.systemFont(ofSize: 50, weight: .bold)
        static let comparisonFont: UIFont = UIFont.systemFont(ofSize: 18, weight: .regular)
        static let detailsFont: UIFont = UIFont.systemFont(ofSize: 18, weight: .regular)
        static let tableHeaderFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        static let tableCellTitleFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let tableCellDetailFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        static let recommendationTitleFont: UIFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let recommendationTextFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .regular)
    }
    
    // MARK: - Properties
    var interactor: DiaryStartDetailBusinessLogic?
    var router: (NSObjectProtocol & DiaryStartDetailRoutingLogic & DiaryStartDetailDataPassing)?
    var startID: NSManagedObjectID?
    private let recommendationLoadingIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    
    private let scrollView: UIScrollView = UIScrollView()
    private let contentView: UIView = UIView()
    
    private let headerContainerView: UIView = UIView()
    private let distanceStyleLabel: UILabel = UILabel()
    private let totalTimeLabel: UILabel = UILabel()
    private let timeComparisonLabel: UILabel = UILabel()
    private let detailsLabel: UILabel = UILabel()
    private let robotImageView: UIImageView = UIImageView()
    
    private let tableContainerView: UIView = UIView()
    private let tableView: UITableView = UITableView()
    
    private let recommendationContainerView: UIView = UIView()
    private let recommendationTitleLabel: UILabel = UILabel()
    private let recommendationTextLabel: UILabel = UILabel()
    
    private var lapDetails: [DiaryStartDetailModels.FetchStartDetails.ViewModel.LapDetail] = []
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchStartDetails()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Constants.backgroundColor
        title = Constants.titleText
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(headerContainerView)
        contentView.addSubview(tableContainerView)
        contentView.addSubview(recommendationContainerView)
        headerContainerView.addSubview(distanceStyleLabel)
        headerContainerView.addSubview(totalTimeLabel)
        headerContainerView.addSubview(timeComparisonLabel)
        headerContainerView.addSubview(detailsLabel)
        tableContainerView.addSubview(tableView)
        recommendationContainerView.addSubview(recommendationTitleLabel)
        recommendationContainerView.addSubview(robotImageView)
        recommendationContainerView.addSubview(recommendationTextLabel)
        
        configureScrollView()
        configureHeaderView()
        configureTableView()
        configureRecommendationView()
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
    }
    
    private func configureHeaderView() {
        headerContainerView.backgroundColor = Constants.headerBackgroundColor
        headerContainerView.layer.cornerRadius = Constants.cornerRadius
        
        distanceStyleLabel.textColor = Constants.textColor
        distanceStyleLabel.font = Constants.distanceStyleFont
        
        totalTimeLabel.textColor = Constants.textColor
        totalTimeLabel.font = Constants.totalTimeFont
        
        timeComparisonLabel.textColor = Constants.comparisonColor
        timeComparisonLabel.font = Constants.comparisonFont
        
        detailsLabel.textColor = Constants.textColor
        detailsLabel.font = Constants.detailsFont
        detailsLabel.textAlignment = .right
        detailsLabel.numberOfLines = 0
        
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
        distanceStyleLabel.translatesAutoresizingMaskIntoConstraints = false
        totalTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeComparisonLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        headerContainerView.pinTop(to: contentView.topAnchor, Constants.contentPadding)
        headerContainerView.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        headerContainerView.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
        
        distanceStyleLabel.pinTop(to: headerContainerView.topAnchor, Constants.contentPadding)
        distanceStyleLabel.pinLeft(to: headerContainerView.leadingAnchor, Constants.contentPadding)
        
        totalTimeLabel.pinTop(to: distanceStyleLabel.bottomAnchor, Constants.contentPadding / 2)
        totalTimeLabel.pinLeft(to: headerContainerView.leadingAnchor, Constants.contentPadding)
        
        timeComparisonLabel.pinTop(to: totalTimeLabel.bottomAnchor, Constants.contentPadding / 4)
        timeComparisonLabel.pinLeft(to: headerContainerView.leadingAnchor, Constants.contentPadding)
        
        detailsLabel.pinTop(to: totalTimeLabel.bottomAnchor, Constants.contentPadding / 4)
        detailsLabel.pinRight(to: headerContainerView.trailingAnchor, Constants.contentPadding)
        
        headerContainerView.pinBottom(to: detailsLabel.bottomAnchor, -Constants.contentPadding)
    }
    
    private func configureTableView() {
        tableContainerView.backgroundColor = Constants.tableBackgroundColor
        tableContainerView.layer.cornerRadius = Constants.cornerRadius
        
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.contentInset = UIEdgeInsets.zero
        tableView.isScrollEnabled = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StartDetailLapCell.self, forCellReuseIdentifier: StartDetailLapCell.identifier)
        tableView.register(StartDetailTableHeader.self, forHeaderFooterViewReuseIdentifier: StartDetailTableHeader.identifier)
        
        tableContainerView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableContainerView.pinTop(to: headerContainerView.bottomAnchor, Constants.contentPadding)
        tableContainerView.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        tableContainerView.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
        
        tableView.pinTop(to: tableContainerView.topAnchor)
        tableView.pinLeft(to: tableContainerView.leadingAnchor)
        tableView.pinRight(to: tableContainerView.trailingAnchor)
        tableView.pinBottom(to: tableContainerView.bottomAnchor)
        
        tableContainerView.clipsToBounds = true
    }
    
    private func configureRecommendationView() {
        recommendationContainerView.backgroundColor = Constants.recommendationBackgroundColor
        recommendationContainerView.layer.cornerRadius = Constants.cornerRadius
        
        recommendationTitleLabel.text = Constants.recommendationTitleText
        recommendationTitleLabel.textColor = Constants.textColor
        recommendationTitleLabel.font = Constants.recommendationTitleFont
        
        robotImageView.image = UIImage(named: "robot")
        robotImageView.contentMode = .scaleAspectFit
        
        recommendationTextLabel.textColor = Constants.textColor
        recommendationTextLabel.font = Constants.recommendationTextFont
        recommendationTextLabel.numberOfLines = 0
        
        recommendationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        robotImageView.translatesAutoresizingMaskIntoConstraints = false
        recommendationTextLabel.translatesAutoresizingMaskIntoConstraints = false
        recommendationContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        recommendationContainerView.pinTop(to: tableContainerView.bottomAnchor, Constants.contentPadding)
        recommendationContainerView.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        recommendationContainerView.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
        recommendationContainerView.pinBottom(to: contentView.bottomAnchor, Constants.contentPadding)
        
        recommendationTitleLabel.pinTop(to: recommendationContainerView.topAnchor, Constants.contentPadding)
        recommendationTitleLabel.pinLeft(to: recommendationContainerView.leadingAnchor, Constants.contentPadding)
        
        robotImageView.pinCenterY(to: recommendationTitleLabel.centerYAnchor)
        robotImageView.pinLeft(to: recommendationTitleLabel.trailingAnchor, Constants.robotImageOffset)
        robotImageView.setWidth(Constants.robotImageSize)
        robotImageView.setHeight(Constants.robotImageSize)
        
        recommendationTextLabel.pinTop(to: recommendationTitleLabel.bottomAnchor, Constants.contentPadding / 2)
        recommendationTextLabel.pinLeft(to: recommendationContainerView.leadingAnchor, Constants.contentPadding)
        recommendationTextLabel.pinRight(to: recommendationContainerView.trailingAnchor, Constants.contentPadding)
        recommendationTextLabel.pinBottom(to: recommendationContainerView.bottomAnchor, Constants.contentPadding)
    }
    
    // MARK: - Private Methods
    private func fetchStartDetails() {
        if let startID = startID {
            let request = DiaryStartDetailModels.FetchStartDetails.Request(startID: startID)
            interactor?.fetchStartDetails(request: request)
        } else if let interactor = router?.dataStore {
            startID = interactor.startID
            if let startID = startID {
                let request = DiaryStartDetailModels.FetchStartDetails.Request(startID: startID)
                self.interactor?.fetchStartDetails(request: request)
            }
        }
    }
    
    private func updateTableViewHeight() {
        let numberOfRows = lapDetails.count
        let tableHeight = CGFloat(numberOfRows) * Constants.tableCellHeight + Constants.tableHeaderHeight
        
        for constraint in contentView.constraints {
            if let firstItem = constraint.firstItem as? NSObject,
               firstItem == tableContainerView,
               constraint.firstAttribute == .height {
                contentView.removeConstraint(constraint)
            }
        }
        
        let heightConstraint = tableContainerView.heightAnchor.constraint(equalToConstant: tableHeight)
        heightConstraint.isActive = true
        
        tableContainerView.layoutIfNeeded()
        contentView.layoutIfNeeded()
        view.layoutIfNeeded()
    }
}

// MARK: - DiaryStartDetailDisplayLogic
extension DiaryStartDetailViewController: DiaryStartDetailDisplayLogic {
    func displayStartDetails(viewModel: DiaryStartDetailModels.FetchStartDetails.ViewModel) {
        // Обновляем хедер
        distanceStyleLabel.text = viewModel.headerInfo.distanceWithStyle
        totalTimeLabel.text = viewModel.headerInfo.totalTime
        timeComparisonLabel.text = viewModel.headerInfo.timeComparisonString
        timeComparisonLabel.textColor = viewModel.headerInfo.comparisonColor
        detailsLabel.text = "\(viewModel.headerInfo.poolSizeString)\n\(viewModel.headerInfo.dateString)"
        
        // Обновляем table
        lapDetails = viewModel.lapDetails
        tableView.reloadData()
        updateTableViewHeight()
        
        // Обновляем рекомендацию
        recommendationTextLabel.text = viewModel.recommendationText
        
        // Показываем или скрываем индикатор загрузки
        if viewModel.isLoadingRecommendation {
            recommendationLoadingIndicator.startAnimating()
            recommendationLoadingIndicator.isHidden = false
        } else {
            recommendationLoadingIndicator.stopAnimating()
            recommendationLoadingIndicator.isHidden = true
        }
    }
    
    func displayRecommendationLoading(viewModel: DiaryStartDetailModels.RecommendationLoading.ViewModel) {
        if viewModel.isLoading {
            recommendationLoadingIndicator.startAnimating()
            recommendationLoadingIndicator.isHidden = false
        } else {
            recommendationLoadingIndicator.stopAnimating()
            recommendationLoadingIndicator.isHidden = true
        }
    }
    
    func displayRecommendationReceived(viewModel: DiaryStartDetailModels.RecommendationReceived.ViewModel) {
        // Анимируем появление текста рекомендации
        UIView.transition(with: recommendationTextLabel,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: { [weak self] in
            self?.recommendationTextLabel.text = viewModel.recommendationText
        })
        
        // Скрываем индикатор загрузки
        recommendationLoadingIndicator.stopAnimating()
        recommendationLoadingIndicator.isHidden = true
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension DiaryStartDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lapDetails.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: StartDetailLapCell.identifier,
            for: indexPath
        ) as? StartDetailLapCell else {
            return UITableViewCell()
        }
        
        let lapDetail = lapDetails[indexPath.row]
        cell.configure(with: lapDetail)
        
        // Убрать разделитель для последнего отрезка
        if indexPath.row == lapDetails.count - 1 {
            cell.hideSeparator()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.tableCellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: StartDetailTableHeader.identifier
        ) as? StartDetailTableHeader else {
            return nil
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.tableHeaderHeight
    }
}
