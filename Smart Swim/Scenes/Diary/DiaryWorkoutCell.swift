//
//  DiaryWorkoutCell.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.03.2025.
//

import UIKit

protocol DiaryWorkoutCellDelegate: AnyObject {
    func workoutCellDidRequestDeletion(_ cell: DiaryWorkoutCell)
}

final class DiaryWorkoutCell: UITableViewCell {
    // MARK: - Constants
    private enum Constants {
        static let cellCornerRadius: CGFloat = 20
        static let cellBackgroundColor = UIColor(hexString: "#323645")
        static let headerColor = UIColor(hexString: "#505773")
        static let textColor = UIColor(hexString: "#FFFFFF") ?? .white
        static let nameFont = UIFont.systemFont(ofSize: 18, weight: .semibold)
        static let detailFont = UIFont.systemFont(ofSize: 20, weight: .light)
        
        static let headerViewCornerRadius: CGFloat = 20
        static let headerHeight: CGFloat = 50
        static let labelLeftPadding: CGFloat = 12
        
        static let exercisePadding: CGFloat = 12
        static let firstExercisePadding: CGFloat = 6
        static let exerciseStackViewTopPadding: CGFloat = 12
        static let exerciseStackViewLeftPadding: CGFloat = 12
        static let exerciseStackViewRightPadding: CGFloat = 12
        static let exerciseStackSpacing: CGFloat = 0
        
        static let separatorColor = UIColor(hexString: "#4C507B")
        static let separatorHeight: CGFloat = 1
        
        static let volumeLabelTopPadding: CGFloat = 12
        static let volumeLabelBottomPadding: CGFloat = 12
        static let volumeLabelLeftPadding: CGFloat = 12
        static let timeLabelRightPadding: CGFloat = 12
        
        static let deleteButtonTopPadding: CGFloat = 12
        static let deleteButtonBottomPadding: CGFloat = 12
        static let deleteButtonRightPadding: CGFloat = 8
        static let deleteButtonImage = UIImage(named: "deleteButton")
    }
    
    // MARK: - Fields
    static let identifier = "DiaryWorkoutCell"
    weak var delegate: DiaryWorkoutCellDelegate?
    
    private let headerView: UIView = UIView()
    private let titleLabel: UILabel = UILabel()
    private let exercisesStackView: UIStackView = UIStackView()
    private let finalSeparator: UIView = UIView()
    private let metersLabel: UILabel = UILabel()
    private let timeLabel: UILabel = UILabel()
    private let deleteButton: UIButton = UIButton()
    
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
        backgroundColor = Constants.cellBackgroundColor
        selectionStyle = .none
        layer.cornerRadius = Constants.cellCornerRadius
        
        contentView.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(deleteButton)
        contentView.addSubview(exercisesStackView)
        contentView.addSubview(finalSeparator)
        contentView.addSubview(metersLabel)
        contentView.addSubview(timeLabel)
        
        configureHeaderView()
        configureTitleLabel()
        configureDeleteButton()
        configureExercisesStackView()
        configureFinalSeparator()
        configureBottomLabels()
    }
    
    private func configureHeaderView() {
        headerView.backgroundColor = Constants.headerColor
        // Скругление только верхних углов
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        headerView.layer.cornerRadius = Constants.headerViewCornerRadius
        
        // Констрейнты
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.pinTop(to: contentView.topAnchor)
        headerView.pinLeft(to: contentView.leadingAnchor)
        headerView.pinRight(to: contentView.trailingAnchor)
    }
    
    private func configureTitleLabel() {
        titleLabel.font = Constants.nameFont
        titleLabel.textColor = Constants.textColor
        
        // Констрейнты
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.pinCenterY(to: headerView.centerYAnchor)
        titleLabel.pinLeft(to: headerView.leadingAnchor, Constants.labelLeftPadding)
    }
    
    private func configureDeleteButton() {
        deleteButton.setImage(Constants.deleteButtonImage, for: .normal)
        
        // Констрейнты
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.pinTop(to: headerView.topAnchor, Constants.deleteButtonTopPadding)
        deleteButton.pinRight(to: headerView.trailingAnchor, Constants.deleteButtonRightPadding)
        deleteButton.pinBottom(to: headerView.bottomAnchor, Constants.deleteButtonBottomPadding)
    }
    
    private func configureExercisesStackView() {
        exercisesStackView.axis = .vertical
        exercisesStackView.spacing = Constants.exerciseStackSpacing
        exercisesStackView.distribution = .fill
        exercisesStackView.alignment = .fill
        
        // Констрейнты
        exercisesStackView.translatesAutoresizingMaskIntoConstraints = false
        exercisesStackView.pinTop(to: headerView.bottomAnchor, Constants.exerciseStackViewTopPadding)
        exercisesStackView.pinLeft(to: contentView.leadingAnchor)
        exercisesStackView.pinRight(to: contentView.trailingAnchor)
    }
    
    private func configureFinalSeparator() {
        finalSeparator.backgroundColor = Constants.separatorColor
        
        // Констрейнты
        finalSeparator.translatesAutoresizingMaskIntoConstraints = false
        finalSeparator.pinLeft(to: contentView.leadingAnchor)
        finalSeparator.pinRight(to: contentView.trailingAnchor)
        finalSeparator.setHeight(Constants.separatorHeight)
        finalSeparator.pinTop(to: exercisesStackView.bottomAnchor)
    }
    
    private func configureBottomLabels() {
        metersLabel.font = Constants.detailFont
        metersLabel.textColor = Constants.textColor
        metersLabel.textAlignment = .left
        
        timeLabel.font = Constants.detailFont
        timeLabel.textColor = Constants.textColor
        timeLabel.textAlignment = .right
        
        metersLabel.translatesAutoresizingMaskIntoConstraints = false
        metersLabel.pinBottom(to: contentView.bottomAnchor, Constants.volumeLabelBottomPadding)
        metersLabel.pinLeft(to: contentView.leadingAnchor, Constants.volumeLabelLeftPadding)
        metersLabel.pinTop(to: finalSeparator.bottomAnchor, Constants.volumeLabelTopPadding)
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.pinBottom(to: contentView.bottomAnchor, Constants.volumeLabelBottomPadding)
        timeLabel.pinRight(to: contentView.trailingAnchor, Constants.timeLabelRightPadding)
        timeLabel.pinTop(to: finalSeparator.bottomAnchor, Constants.volumeLabelTopPadding)
        
        NSLayoutConstraint.activate([
            metersLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -10)
        ])
    }
    
    // MARK: - Helper Methods
    private func createExerciseView(with exerciseText: String, isFirst: Bool, isLast: Bool) -> UIView {
        let exerciseView = UIView()
        
        let exerciseLabel = UILabel()
        exerciseLabel.font = Constants.detailFont
        exerciseLabel.textColor = Constants.textColor
        exerciseLabel.numberOfLines = 0
        exerciseLabel.text = exerciseText
        
        let separator = UIView()
        separator.backgroundColor = Constants.separatorColor
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.setHeight(Constants.separatorHeight)
        separator.isHidden = isLast
        
        exerciseView.addSubview(exerciseLabel)
        exerciseView.addSubview(separator)
        
        exerciseLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let topPadding = isFirst ? Constants.firstExercisePadding : Constants.exercisePadding
        
        exerciseLabel.pinTop(to: exerciseView.topAnchor, topPadding)
        exerciseLabel.pinLeft(to: exerciseView.leadingAnchor, Constants.exerciseStackViewLeftPadding)
        exerciseLabel.pinRight(to: exerciseView.trailingAnchor, Constants.exerciseStackViewRightPadding)
        
        separator.pinTop(to: exerciseLabel.bottomAnchor, Constants.exercisePadding)
        separator.pinLeft(to: exerciseView.leadingAnchor)
        separator.pinRight(to: exerciseView.trailingAnchor)
        separator.pinBottom(to: exerciseView.bottomAnchor)
        
        return exerciseView
    }
    
    // MARK: - Time Formatting
    private func formatTime(_ seconds: Double) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
    
    // MARK: - Public Methods
    func configure(with sessionData: DiaryModels.FetchWorkoutSessions.ViewModel.DisplayedWorkoutSession) {
        titleLabel.text = "Тренировка от " + sessionData.dateString
        
        exercisesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, exerciseText) in sessionData.exercises.enumerated() {
            let isFirst = index == 0
            let isLast = index == sessionData.exercises.count - 1
            let exerciseView = createExerciseView(with: exerciseText, isFirst: isFirst, isLast: isLast)
            exercisesStackView.addArrangedSubview(exerciseView)
        }
        
        metersLabel.text = "Всего: \(sessionData.totalMeters)"
        timeLabel.text = formatTime(sessionData.rawTotalSeconds)
    }
    
    // MARK: - Actions Configuration
    private func configureActions() {
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    @objc private func deleteButtonTapped() {
        delegate?.workoutCellDidRequestDeletion(self)
    }
}
