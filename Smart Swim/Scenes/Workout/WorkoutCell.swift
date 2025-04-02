//
//  WorkoutCell.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 01.02.2025.
//

import UIKit

protocol WorkoutCellDelegate: AnyObject {
    func workoutCellDidRequestEdit(_ cell: WorkoutCell)
    func workoutCellDidRequestDeletion(_ cell: WorkoutCell)
}

final class WorkoutCell: UITableViewCell {
    // MARK: - Constants
    private enum Constants {
        static let cellCornerRadius: CGFloat = 20
        static let workoutCellBackgroundColor = UIColor(hexString: "#323645")
        static let workoutCellNameHeaderColor = UIColor(hexString: "#505773")
        static let titleWhite = UIColor(hexString: "#FFFFFF") ?? .white
        static let workoutNameFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let workoutExerciseFont = UIFont.systemFont(ofSize: 20, weight: .light)
        
        static let nameHeaderViewCornerRadius: CGFloat = 20
        static let nameHeaderHeight: CGFloat = 50
        static let nameLabelLeftPadding: CGFloat = 12
        
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
        static let volumeLabelRightPadding: CGFloat = 12
        
        static let editButtonTopPadding: CGFloat = 12
        static let editButtonBottomPadding: CGFloat = 12
        static let editButtonRightPadding: CGFloat = 12
        static let editButtonImage = UIImage(named: "editButton")
        
        static let deleteButtonTopPadding: CGFloat = 12
        static let deleteButtonBottomPadding: CGFloat = 12
        static let deleteButtonRightPadding: CGFloat = 8
        static let deleteButtonImage = UIImage(named: "deleteButton")
    }
    
    // MARK: - Fields
    static let identifier = "WorkoutCell"
    weak var delegate: WorkoutCellDelegate?
    
    private let nameHeaderView: UIView = UIView()
    private let nameLabel: UILabel = UILabel()
    private let exercisesStackView: UIStackView = UIStackView()
    private let finalSeparator: UIView = UIView()
    private let volumeLabel: UILabel = UILabel()
    private let deleteButton: UIButton = UIButton()
    private let editButton: UIButton = UIButton()
    
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
        backgroundColor = Constants.workoutCellBackgroundColor
        selectionStyle = .none
        layer.cornerRadius = Constants.cellCornerRadius
        
        contentView.addSubview(nameHeaderView)
        nameHeaderView.addSubview(nameLabel)
        nameHeaderView.addSubview(deleteButton)
        nameHeaderView.addSubview(editButton)
        contentView.addSubview(exercisesStackView)
        contentView.addSubview(finalSeparator)
        contentView.addSubview(volumeLabel)
        
        configureNameHeaderView()
        configureNameLabel()
        configureEditButton()
        configureDeleteButton()
        configureExercisesStackView()
        configureFinalSeparator()
        configureVolumeLabel()
    }
    
    private func configureNameHeaderView() {
        nameHeaderView.backgroundColor = Constants.workoutCellNameHeaderColor
        // Скругление только верхних углов
        nameHeaderView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        nameHeaderView.layer.cornerRadius = Constants.nameHeaderViewCornerRadius
        
        // Констрейнты
        nameHeaderView.translatesAutoresizingMaskIntoConstraints = false
        nameHeaderView.pinTop(to: contentView.topAnchor)
        nameHeaderView.pinLeft(to: contentView.leadingAnchor)
        nameHeaderView.pinRight(to: contentView.trailingAnchor)
    }
    
    private func configureNameLabel() {
        nameLabel.font = Constants.workoutNameFont
        nameLabel.textColor = Constants.titleWhite
        
        // Констрейнты
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.pinCenterY(to: nameHeaderView.centerYAnchor)
        nameLabel.pinLeft(to: nameHeaderView.leadingAnchor, Constants.nameLabelLeftPadding)
    }
    
    private func configureEditButton() {
        editButton.setImage(Constants.editButtonImage, for: .normal)
        
        // Констрейнты
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.pinTop(to: nameHeaderView.topAnchor, Constants.editButtonTopPadding)
        editButton.pinRight(to: nameHeaderView.trailingAnchor, Constants.editButtonRightPadding)
        editButton.pinBottom(to: nameHeaderView.bottomAnchor, Constants.editButtonBottomPadding)
    }
    
    private func configureDeleteButton() {
        deleteButton.setImage(Constants.deleteButtonImage, for: .normal)
        
        // Констрейнты
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.pinTop(to: nameHeaderView.topAnchor, Constants.deleteButtonTopPadding)
        deleteButton.pinRight(to: editButton.leadingAnchor, Constants.deleteButtonRightPadding)
        deleteButton.pinBottom(to: nameHeaderView.bottomAnchor, Constants.deleteButtonBottomPadding)
    }
    
    private func configureExercisesStackView() {
        exercisesStackView.axis = .vertical
        exercisesStackView.spacing = Constants.exerciseStackSpacing
        exercisesStackView.distribution = .fill
        exercisesStackView.alignment = .fill
        
        // Констрейнты
        exercisesStackView.translatesAutoresizingMaskIntoConstraints = false
        exercisesStackView.pinTop(to: nameHeaderView.bottomAnchor, Constants.exerciseStackViewTopPadding)
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
    
    private func configureVolumeLabel() {
        volumeLabel.font = Constants.workoutExerciseFont
        volumeLabel.textColor = Constants.titleWhite
        
        // Констрейнты
        volumeLabel.translatesAutoresizingMaskIntoConstraints = false
        volumeLabel.pinBottom(to: contentView.bottomAnchor, Constants.volumeLabelBottomPadding)
        volumeLabel.pinRight(to: contentView.trailingAnchor, Constants.volumeLabelRightPadding)
        volumeLabel.pinTop(to: finalSeparator.bottomAnchor, Constants.volumeLabelTopPadding)
    }
    
    // MARK: - Helper Methods
    private func createExerciseView(with exerciseText: String, isFirst: Bool, isLast: Bool) -> UIView {
        let exerciseView = UIView()
        
        let exerciseLabel = UILabel()
        exerciseLabel.font = Constants.workoutExerciseFont
        exerciseLabel.textColor = Constants.titleWhite
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
    
    // MARK: - Public Methods
    func configure(with displayedWorkout: WorkoutModels.FetchWorkouts.ViewModel.DisplayedWorkout) {
        nameLabel.text = displayedWorkout.name
        exercisesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, exerciseText) in displayedWorkout.exercises.enumerated() {
            let isFirst = index == 0
            let isLast = index == displayedWorkout.exercises.count - 1
            let exerciseView = createExerciseView(with: exerciseText, isFirst: isFirst, isLast: isLast)
            exercisesStackView.addArrangedSubview(exerciseView)
        }
        
        volumeLabel.text = "Всего: \(displayedWorkout.totalVolume)м"
    }
    
    // MARK: - Actions Configuration
    private func configureActions() {
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
    }
    
    @objc private func deleteButtonTapped() {
        delegate?.workoutCellDidRequestDeletion(self)
    }
    
    @objc private func editButtonTapped() {
        delegate?.workoutCellDidRequestEdit(self)
    }
}
