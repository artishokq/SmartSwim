//
//  WorkoutSessionDetailViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 25.03.2025.
//

import UIKit

protocol WorkoutSessionDetailDisplayLogic: AnyObject {
    func displaySessionDetails(viewModel: WorkoutSessionDetailModels.FetchSessionDetails.ViewModel)
    func displayRecommendation(viewModel: WorkoutSessionDetailModels.FetchRecommendation.ViewModel)
}

final class WorkoutSessionDetailViewController: UIViewController, WorkoutSessionDetailDisplayLogic {
    // MARK: - Constants
    private enum Constants {
        static let backgroundColor = UIColor(hexString: "#242531")
        static let cardColor = UIColor(hexString: "#323645")
        static let textColor = UIColor(hexString: "#FFFFFF")
        static let pulseBackgroundColor: UIColor = UIColor(hexString: "#FF9393") ?? .red
        static let caloriesBackgroundColor: UIColor = UIColor(hexString: "#FFD580") ?? .orange
        static let distanceBackgroundColor: UIColor = UIColor(hexString: "#90CAF9") ?? .blue
        static let timeBackgroundColor: UIColor = UIColor(hexString: "#A5D6A7") ?? .green
        
        static let cornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 8
        static let cardSpacing: CGFloat = 8
        static let contentPadding: CGFloat = 12
        static let cardHeight: CGFloat = 120
        static let iconSize: CGFloat = 24
        static let iconSpacing: CGFloat = 8
        static let valuesStackViewSpacing: CGFloat = 4
        
        static let titleText: String = "Детали тренировки"
        static let recommendationTitleText: String = "Рекомендация от ИИ"
        static let pulseAnalysisTitle: String = "Анализ пульса"
        static let strokeAnalysisTitle: String = "Анализ гребков"
        static let averagePulseLabel: String = "Средний пульс: "
        static let maxPulseLabel: String = "Максимальный пульс: "
        static let minPulseLabel: String = "Минимальный пульс: "
        static let pulseZoneLabel: String = "Пульсовая зона: "
        static let averageStrokesLabel: String = "Среднее кол-во гребков на 50м: "
        static let maxStrokesLabel: String = "Макс. кол-во гребков на 50м: "
        static let minStrokesLabel: String = "Мин. кол-во гребков на 50м: "
        static let totalStrokesLabel: String = "Всего гребков: "
        static let timeLabel: String = "Время: "
        static let intervalLabel: String = "Режим: "
        static let heartRateLabelText: String = "Ваш средний пульс за тренировку:"
        static let caloriesLabelText: String = "Калорий сожжено за тренировку:"
        static let distanceLabelText: String = "Метров проплыто за тренировку:"
        static let timeLabelText: String = "Общее время тренировки:"
        
        static let pulseIcon: String = "puls"
        static let strokeIcon: String = "stroke"
        static let caloriesIcon: String = "ccal"
        static let distanceIcon: String = "distance"
        static let timeIcon: String = "clock"
        static let robotIcon: String = "robot"
        
        static let headerFont = UIFont.systemFont(ofSize: 20, weight: .bold)
        static let valueFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        static let labelFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let exerciseTitleFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let exerciseDetailFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let analysisHeaderFont = UIFont.systemFont(ofSize: 14, weight: .semibold)
        static let analysisValueFont = UIFont.systemFont(ofSize: 14, weight: .regular)
    }
    
    // MARK: - Properties
    var interactor: WorkoutSessionDetailBusinessLogic?
    var router: (NSObjectProtocol & WorkoutSessionDetailRoutingLogic & WorkoutSessionDetailDataPassing)?
    var sessionID: UUID?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let summaryContainerView = UIView()
    private let heartRateCard = UIView()
    private let heartRateLabel = UILabel()
    private let heartRateValueLabel = UILabel()
    private let heartRateIcon = UIImageView()
    
    private let caloriesCard = UIView()
    private let caloriesLabel = UILabel()
    private let caloriesValueLabel = UILabel()
    private let caloriesIcon = UIImageView()
    
    private let distanceCard = UIView()
    private let distanceLabel = UILabel()
    private let distanceValueLabel = UILabel()
    private let distanceIcon = UIImageView()
    
    private let timeCard = UIView()
    private let timeLabel = UILabel()
    private let timeValueLabel = UILabel()
    private let timeIcon = UIImageView()
    
    private let recommendationCard = UIView()
    private let recommendationTitleLabel = UILabel()
    private let recommendationTextLabel = UILabel()
    private let robotIcon = UIImageView()
    private let recommendationLoadingIndicator = UIActivityIndicatorView(style: .medium)
    
    private let exercisesStackView = UIStackView()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchSessionDetails()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Constants.backgroundColor
        title = Constants.titleText
        
        configureScrollView()
        configureSummaryCards()
        configureRecommendationCard()
        configureExercisesStackView()
    }
    
    private func configureScrollView() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
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
        contentView.pinWidth(to: scrollView)
    }
    
    private func configureSummaryCards() {
        contentView.addSubview(summaryContainerView)
        summaryContainerView.translatesAutoresizingMaskIntoConstraints = false
        
        summaryContainerView.pinTop(to: contentView.topAnchor, Constants.cardPadding)
        summaryContainerView.pinLeft(to: contentView.leadingAnchor, Constants.cardPadding)
        summaryContainerView.pinRight(to: contentView.trailingAnchor, Constants.cardPadding)
        
        configureHeartRateCard()
        configureCaloriesCard()
        configureDistanceCard()
        configureTimeCard()
        
        let containerWidth = UIScreen.main.bounds.width - (2 * Constants.cardPadding)
        let cardWidth = (containerWidth - Constants.cardSpacing) / 2
        
        heartRateCard.setHeight(Constants.cardHeight)
        caloriesCard.setHeight(Constants.cardHeight)
        distanceCard.setHeight(Constants.cardHeight)
        timeCard.setHeight(Constants.cardHeight)
        
        heartRateCard.setWidth(cardWidth)
        caloriesCard.setWidth(cardWidth)
        distanceCard.setWidth(cardWidth)
        timeCard.setWidth(cardWidth)
        
        heartRateCard.pinTop(to: summaryContainerView.topAnchor)
        heartRateCard.pinLeft(to: summaryContainerView.leadingAnchor)
        
        caloriesCard.pinTop(to: summaryContainerView.topAnchor)
        caloriesCard.pinRight(to: summaryContainerView.trailingAnchor)
        
        distanceCard.pinTop(to: heartRateCard.bottomAnchor, Constants.cardSpacing)
        distanceCard.pinLeft(to: summaryContainerView.leadingAnchor)
        
        timeCard.pinTop(to: caloriesCard.bottomAnchor, Constants.cardSpacing)
        timeCard.pinRight(to: summaryContainerView.trailingAnchor)
        
        summaryContainerView.pinBottom(to: distanceCard.bottomAnchor)
    }
    
    private func configureHeartRateCard() {
        heartRateCard.backgroundColor = Constants.pulseBackgroundColor
        heartRateCard.layer.cornerRadius = Constants.cornerRadius
        
        summaryContainerView.addSubview(heartRateCard)
        heartRateCard.translatesAutoresizingMaskIntoConstraints = false
        
        heartRateCard.addSubview(heartRateLabel)
        heartRateCard.addSubview(heartRateValueLabel)
        heartRateCard.addSubview(heartRateIcon)
        
        heartRateLabel.text = Constants.heartRateLabelText
        heartRateLabel.textColor = Constants.textColor
        heartRateLabel.font = Constants.labelFont
        heartRateLabel.numberOfLines = 0
        
        heartRateValueLabel.textColor = Constants.textColor
        heartRateValueLabel.font = Constants.valueFont
        
        heartRateIcon.image = UIImage(named: Constants.pulseIcon)
        heartRateIcon.contentMode = .scaleAspectFit
        
        heartRateLabel.translatesAutoresizingMaskIntoConstraints = false
        heartRateValueLabel.translatesAutoresizingMaskIntoConstraints = false
        heartRateIcon.translatesAutoresizingMaskIntoConstraints = false
        
        heartRateLabel.pinTop(to: heartRateCard.topAnchor, Constants.contentPadding)
        heartRateLabel.pinLeft(to: heartRateCard.leadingAnchor, Constants.contentPadding)
        heartRateLabel.pinRight(to: heartRateCard.trailingAnchor, Constants.contentPadding)
        
        heartRateIcon.pinBottom(to: heartRateCard.bottomAnchor, Constants.contentPadding)
        heartRateIcon.pinLeft(to: heartRateCard.leadingAnchor, Constants.contentPadding)
        heartRateIcon.setWidth(Constants.iconSize)
        heartRateIcon.setHeight(Constants.iconSize)
        
        heartRateValueLabel.pinCenterY(to: heartRateIcon.centerYAnchor)
        heartRateValueLabel.pinLeft(to: heartRateIcon.trailingAnchor, Constants.iconSpacing)
    }
    
    private func configureCaloriesCard() {
        caloriesCard.backgroundColor = Constants.caloriesBackgroundColor
        caloriesCard.layer.cornerRadius = Constants.cornerRadius
        
        summaryContainerView.addSubview(caloriesCard)
        caloriesCard.translatesAutoresizingMaskIntoConstraints = false
        
        caloriesCard.addSubview(caloriesLabel)
        caloriesCard.addSubview(caloriesValueLabel)
        caloriesCard.addSubview(caloriesIcon)
        
        caloriesLabel.text = Constants.caloriesLabelText
        caloriesLabel.textColor = Constants.textColor
        caloriesLabel.font = Constants.labelFont
        caloriesLabel.numberOfLines = 0
        
        caloriesValueLabel.textColor = Constants.textColor
        caloriesValueLabel.font = Constants.valueFont
        
        caloriesIcon.image = UIImage(named: Constants.caloriesIcon)
        caloriesIcon.contentMode = .scaleAspectFit
        
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesValueLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesIcon.translatesAutoresizingMaskIntoConstraints = false
        
        caloriesLabel.pinTop(to: caloriesCard.topAnchor, Constants.contentPadding)
        caloriesLabel.pinLeft(to: caloriesCard.leadingAnchor, Constants.contentPadding)
        caloriesLabel.pinRight(to: caloriesCard.trailingAnchor, Constants.contentPadding)
        
        caloriesIcon.pinBottom(to: caloriesCard.bottomAnchor, Constants.contentPadding)
        caloriesIcon.pinLeft(to: caloriesCard.leadingAnchor, Constants.contentPadding)
        caloriesIcon.setWidth(Constants.iconSize)
        caloriesIcon.setHeight(Constants.iconSize)
        
        caloriesValueLabel.pinCenterY(to: caloriesIcon.centerYAnchor)
        caloriesValueLabel.pinLeft(to: caloriesIcon.trailingAnchor, Constants.iconSpacing)
    }
    
    private func configureDistanceCard() {
        distanceCard.backgroundColor = Constants.distanceBackgroundColor
        distanceCard.layer.cornerRadius = Constants.cornerRadius
        
        summaryContainerView.addSubview(distanceCard)
        distanceCard.translatesAutoresizingMaskIntoConstraints = false
        
        distanceCard.addSubview(distanceLabel)
        distanceCard.addSubview(distanceValueLabel)
        distanceCard.addSubview(distanceIcon)
        
        distanceLabel.text = Constants.distanceLabelText
        distanceLabel.textColor = Constants.textColor
        distanceLabel.font = Constants.labelFont
        distanceLabel.numberOfLines = 0
        
        distanceValueLabel.textColor = Constants.textColor
        distanceValueLabel.font = Constants.valueFont
        
        distanceIcon.image = UIImage(named: Constants.distanceIcon)
        distanceIcon.contentMode = .scaleAspectFit
        
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceValueLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceIcon.translatesAutoresizingMaskIntoConstraints = false
        
        distanceLabel.pinTop(to: distanceCard.topAnchor, Constants.contentPadding)
        distanceLabel.pinLeft(to: distanceCard.leadingAnchor, Constants.contentPadding)
        distanceLabel.pinRight(to: distanceCard.trailingAnchor, Constants.contentPadding)
        
        distanceIcon.pinBottom(to: distanceCard.bottomAnchor, Constants.contentPadding)
        distanceIcon.pinLeft(to: distanceCard.leadingAnchor, Constants.contentPadding)
        distanceIcon.setWidth(Constants.iconSize)
        distanceIcon.setHeight(Constants.iconSize)
        
        distanceValueLabel.pinCenterY(to: distanceIcon.centerYAnchor)
        distanceValueLabel.pinLeft(to: distanceIcon.trailingAnchor, Constants.iconSpacing)
    }
    
    private func configureTimeCard() {
        timeCard.backgroundColor = Constants.timeBackgroundColor
        timeCard.layer.cornerRadius = Constants.cornerRadius
        
        summaryContainerView.addSubview(timeCard)
        timeCard.translatesAutoresizingMaskIntoConstraints = false
        
        timeCard.addSubview(timeLabel)
        timeCard.addSubview(timeValueLabel)
        timeCard.addSubview(timeIcon)
        
        timeLabel.text = Constants.timeLabelText
        timeLabel.textColor = Constants.textColor
        timeLabel.font = Constants.labelFont
        timeLabel.numberOfLines = 0
        
        timeValueLabel.textColor = Constants.textColor
        timeValueLabel.font = Constants.valueFont
        
        timeIcon.image = UIImage(named: Constants.timeIcon)
        timeIcon.contentMode = .scaleAspectFit
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        timeIcon.translatesAutoresizingMaskIntoConstraints = false
        
        timeLabel.pinTop(to: timeCard.topAnchor, Constants.contentPadding)
        timeLabel.pinLeft(to: timeCard.leadingAnchor, Constants.contentPadding)
        timeLabel.pinRight(to: timeCard.trailingAnchor, Constants.contentPadding)
        
        timeIcon.pinBottom(to: timeCard.bottomAnchor, Constants.contentPadding)
        timeIcon.pinLeft(to: timeCard.leadingAnchor, Constants.contentPadding)
        timeIcon.setWidth(Constants.iconSize)
        timeIcon.setHeight(Constants.iconSize)
        
        timeValueLabel.pinCenterY(to: timeIcon.centerYAnchor)
        timeValueLabel.pinLeft(to: timeIcon.trailingAnchor, Constants.iconSpacing)
    }
    
    private func configureRecommendationCard() {
        recommendationCard.backgroundColor = Constants.cardColor
        recommendationCard.layer.cornerRadius = Constants.cornerRadius
        
        contentView.addSubview(recommendationCard)
        recommendationCard.translatesAutoresizingMaskIntoConstraints = false
        
        recommendationCard.addSubview(recommendationTitleLabel)
        recommendationCard.addSubview(robotIcon)
        recommendationCard.addSubview(recommendationTextLabel)
        recommendationCard.addSubview(recommendationLoadingIndicator)
        
        recommendationTitleLabel.text = Constants.recommendationTitleText
        recommendationTitleLabel.textColor = Constants.textColor
        recommendationTitleLabel.font = Constants.headerFont
        
        robotIcon.image = UIImage(named: Constants.robotIcon)
        robotIcon.contentMode = .scaleAspectFit
        
        recommendationTextLabel.textColor = Constants.textColor
        recommendationTextLabel.font = Constants.labelFont
        recommendationTextLabel.numberOfLines = 0
        
        recommendationLoadingIndicator.color = Constants.textColor
        recommendationLoadingIndicator.hidesWhenStopped = true
        
        recommendationTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        robotIcon.translatesAutoresizingMaskIntoConstraints = false
        recommendationTextLabel.translatesAutoresizingMaskIntoConstraints = false
        recommendationLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        recommendationCard.pinTop(to: summaryContainerView.bottomAnchor, Constants.cardSpacing)
        recommendationCard.pinLeft(to: contentView.leadingAnchor, Constants.cardPadding)
        recommendationCard.pinRight(to: contentView.trailingAnchor, Constants.cardPadding)
        
        recommendationTitleLabel.pinTop(to: recommendationCard.topAnchor, Constants.contentPadding)
        recommendationTitleLabel.pinLeft(to: recommendationCard.leadingAnchor, Constants.contentPadding)
        
        robotIcon.pinCenterY(to: recommendationTitleLabel.centerYAnchor)
        robotIcon.pinLeft(to: recommendationTitleLabel.trailingAnchor, Constants.iconSpacing)
        robotIcon.setWidth(Constants.iconSize)
        robotIcon.setHeight(Constants.iconSize)
        
        recommendationTextLabel.pinTop(to: recommendationTitleLabel.bottomAnchor, Constants.contentPadding)
        recommendationTextLabel.pinLeft(to: recommendationCard.leadingAnchor, Constants.contentPadding)
        recommendationTextLabel.pinRight(to: recommendationCard.trailingAnchor, Constants.contentPadding)
        recommendationTextLabel.pinBottom(to: recommendationCard.bottomAnchor, Constants.contentPadding)
        
        recommendationLoadingIndicator.pinCenterX(to: recommendationCard.centerXAnchor)
        recommendationLoadingIndicator.pinCenterY(to: recommendationTextLabel.centerYAnchor)
    }
    
    private func configureExercisesStackView() {
        exercisesStackView.axis = .vertical
        exercisesStackView.spacing = Constants.cardSpacing
        exercisesStackView.distribution = .fillProportionally
        
        contentView.addSubview(exercisesStackView)
        exercisesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        exercisesStackView.pinTop(to: recommendationCard.bottomAnchor, Constants.cardSpacing)
        exercisesStackView.pinLeft(to: contentView.leadingAnchor, Constants.cardPadding)
        exercisesStackView.pinRight(to: contentView.trailingAnchor, Constants.cardPadding)
        exercisesStackView.pinBottom(to: contentView.bottomAnchor, Constants.cardPadding)
    }
    
    // MARK: - Helper Methods
    private func createExerciseView(for exercise: WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail) -> UIView {
        let exerciseView = UIView()
        exerciseView.backgroundColor = Constants.cardColor
        exerciseView.layer.cornerRadius = Constants.cornerRadius
        
        let titleLabel = UILabel()
        titleLabel.text = "Задание \(exercise.orderIndex + 1):"
        titleLabel.textColor = Constants.textColor
        titleLabel.font = Constants.exerciseTitleFont
        titleLabel.numberOfLines = 0
        
        var detailsText = ""
        
        if exercise.typeString.lowercased() == "разминка" {
            detailsText = "Разминка "
        } else if exercise.typeString.lowercased() == "заминка" {
            detailsText = "Заминка "
        }
        
        if exercise.repetitionsString.contains("1x") {
            let withoutPrefix = exercise.repetitionsString.replacingOccurrences(of: "1x", with: "")
            detailsText += "\(withoutPrefix) \(exercise.styleString)"
        } else {
            detailsText += "\(exercise.repetitionsString) \(exercise.styleString)"
        }
        
        if exercise.hasInterval {
            detailsText += "\n" + Constants.intervalLabel + exercise.intervalString
        }
        
        detailsText += "\n" + Constants.timeLabel + formatTime(exercise.timeString)
        
        let detailsLabel = UILabel()
        detailsLabel.text = detailsText
        detailsLabel.textColor = Constants.textColor
        detailsLabel.font = Constants.exerciseDetailFont
        detailsLabel.numberOfLines = 0
        
        let pulseAnalysisView = createAnalysisView(
            title: Constants.pulseAnalysisTitle,
            icon: Constants.pulseIcon,
            values: [
                Constants.averagePulseLabel + exercise.pulseAnalysis.averagePulse,
                Constants.maxPulseLabel + exercise.pulseAnalysis.maxPulse,
                Constants.minPulseLabel + exercise.pulseAnalysis.minPulse,
                Constants.pulseZoneLabel + exercise.pulseAnalysis.pulseZone
            ],
            backgroundColor: Constants.pulseBackgroundColor
        )
        
        let strokeAnalysisView = createAnalysisView(
            title: Constants.strokeAnalysisTitle,
            icon: Constants.strokeIcon,
            values: [
                Constants.averageStrokesLabel + exercise.strokeAnalysis.averageStrokes,
                Constants.maxStrokesLabel + exercise.strokeAnalysis.maxStrokes,
                Constants.minStrokesLabel + exercise.strokeAnalysis.minStrokes,
                Constants.totalStrokesLabel + exercise.strokeAnalysis.totalStrokes
            ],
            backgroundColor: Constants.distanceBackgroundColor
        )
        
        exerciseView.addSubview(titleLabel)
        exerciseView.addSubview(detailsLabel)
        exerciseView.addSubview(pulseAnalysisView)
        exerciseView.addSubview(strokeAnalysisView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        detailsLabel.translatesAutoresizingMaskIntoConstraints = false
        pulseAnalysisView.translatesAutoresizingMaskIntoConstraints = false
        strokeAnalysisView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.pinTop(to: exerciseView.topAnchor, Constants.contentPadding)
        titleLabel.pinLeft(to: exerciseView.leadingAnchor, Constants.contentPadding)
        titleLabel.pinRight(to: exerciseView.trailingAnchor, Constants.contentPadding)
        
        detailsLabel.pinTop(to: titleLabel.bottomAnchor, Constants.contentPadding)
        detailsLabel.pinLeft(to: exerciseView.leadingAnchor, Constants.contentPadding)
        detailsLabel.pinRight(to: exerciseView.trailingAnchor, Constants.contentPadding)
        
        pulseAnalysisView.pinTop(to: detailsLabel.bottomAnchor, Constants.contentPadding)
        pulseAnalysisView.pinLeft(to: exerciseView.leadingAnchor, Constants.contentPadding)
        pulseAnalysisView.pinRight(to: exerciseView.trailingAnchor, Constants.contentPadding)
        
        strokeAnalysisView.pinTop(to: pulseAnalysisView.bottomAnchor, Constants.contentPadding)
        strokeAnalysisView.pinLeft(to: exerciseView.leadingAnchor, Constants.contentPadding)
        strokeAnalysisView.pinRight(to: exerciseView.trailingAnchor, Constants.contentPadding)
        strokeAnalysisView.pinBottom(to: exerciseView.bottomAnchor, Constants.contentPadding)
        
        return exerciseView
    }
    
    private func createAnalysisView(title: String, icon: String, values: [String], backgroundColor: UIColor) -> UIView {
        let analysisView = UIView()
        analysisView.backgroundColor = backgroundColor
        analysisView.layer.cornerRadius = Constants.cornerRadius
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textColor = Constants.textColor
        titleLabel.font = Constants.analysisHeaderFont
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(named: icon)
        iconImageView.contentMode = .scaleAspectFit
        
        let valuesStackView = UIStackView()
        valuesStackView.axis = .vertical
        valuesStackView.spacing = Constants.valuesStackViewSpacing
        valuesStackView.distribution = .fillEqually
        
        for value in values {
            let valueLabel = UILabel()
            valueLabel.text = value
            valueLabel.textColor = Constants.textColor
            valueLabel.font = Constants.analysisValueFont
            valuesStackView.addArrangedSubview(valueLabel)
        }
        
        analysisView.addSubview(titleLabel)
        analysisView.addSubview(iconImageView)
        analysisView.addSubview(valuesStackView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        valuesStackView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.pinTop(to: analysisView.topAnchor, Constants.contentPadding)
        titleLabel.pinLeft(to: analysisView.leadingAnchor, Constants.contentPadding)
        
        iconImageView.pinCenterY(to: titleLabel.centerYAnchor)
        iconImageView.pinLeft(to: titleLabel.trailingAnchor, Constants.iconSpacing)
        iconImageView.setWidth(Constants.iconSize)
        iconImageView.setHeight(Constants.iconSize)
        
        valuesStackView.pinTop(to: titleLabel.bottomAnchor, Constants.contentPadding/2)
        valuesStackView.pinLeft(to: analysisView.leadingAnchor, Constants.contentPadding)
        valuesStackView.pinRight(to: analysisView.trailingAnchor, Constants.contentPadding)
        valuesStackView.pinBottom(to: analysisView.bottomAnchor, Constants.contentPadding)
        
        return analysisView
    }
    
    // MARK: - Time Formatting Helper
    private func formatTime(_ timeString: String) -> String {
        if timeString.contains(":") && timeString.components(separatedBy: ":").count == 3 {
            return timeString
        }
        
        if let timeSeconds = Double(timeString.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
            let hours = Int(timeSeconds) / 3600
            let minutes = (Int(timeSeconds) % 3600) / 60
            let seconds = Int(timeSeconds) % 60
            
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        
        return timeString
    }
    
    // MARK: - Data Loading Methods
    private func fetchSessionDetails() {
        guard let sessionID = sessionID else { return }
        let request = WorkoutSessionDetailModels.FetchSessionDetails.Request(sessionID: sessionID)
        interactor?.fetchSessionDetails(request: request)
    }
    
    // MARK: - Display Logic
    func displaySessionDetails(viewModel: WorkoutSessionDetailModels.FetchSessionDetails.ViewModel) {
        heartRateValueLabel.text = viewModel.summaryData.averageHeartRateString
        caloriesValueLabel.text = viewModel.summaryData.totalCaloriesString
        distanceValueLabel.text = viewModel.summaryData.totalMetersString
        
        let formattedTime = formatTime(viewModel.summaryData.totalTimeString)
        timeValueLabel.text = formattedTime
        
        exercisesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for exercise in viewModel.exercises {
            let exerciseView = createExerciseView(for: exercise)
            exercisesStackView.addArrangedSubview(exerciseView)
        }
    }
    
    func displayRecommendation(viewModel: WorkoutSessionDetailModels.FetchRecommendation.ViewModel) {
        if viewModel.isLoading {
            recommendationLoadingIndicator.startAnimating()
            recommendationTextLabel.isHidden = true
        } else {
            recommendationLoadingIndicator.stopAnimating()
            recommendationTextLabel.isHidden = false
            
            UIView.transition(with: recommendationTextLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.recommendationTextLabel.text = viewModel.recommendationText
            })
        }
    }
}
