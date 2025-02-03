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
        
        static let nameHeaderViewCornerRadius: CGFloat = 20
        static let nameHeaderHeight: CGFloat = 50
        static let nameLabelLeftPadding: CGFloat = 12
        
        static let exercisesLabelTopPadding: CGFloat = 12
        static let exercisesLabelRightPadding: CGFloat = 12
        static let exercisesLabelLeftPadding: CGFloat = 12
        
        static let volumeLabelTopPadding: CGFloat = 12
        static let volumeLabelBottomPadding: CGFloat = 12
        static let volumeLabelRightPadding: CGFloat = 12
        
        static let editButtonTopPadding: CGFloat = 12
        static let editButtonBottomPadding: CGFloat = 12
        static let editButtonRightPadding: CGFloat = 12
        
        static let deleteButtonTopPadding: CGFloat = 12
        static let deleteButtonBottomPadding: CGFloat = 12
        static let deleteButtonRightPadding: CGFloat = 8
    }
    
    // MARK: - Fields
    static let identifier = "WorkoutCell"
    weak var delegate: WorkoutCellDelegate?
    
    private let nameHeaderView: UIView = UIView()
    private let nameLabel: UILabel = UILabel()
    private let exercisesLabel: UILabel = UILabel()
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
        backgroundColor = Resources.Colors.workoutCellBackgroundColor
        selectionStyle = .none
        layer.cornerRadius = Constants.cellCornerRadius
        
        contentView.addSubview(nameHeaderView)
        nameHeaderView.addSubview(nameLabel)
        nameHeaderView.addSubview(deleteButton)
        nameHeaderView.addSubview(editButton)
        contentView.addSubview(exercisesLabel)
        contentView.addSubview(volumeLabel)
        
        nameHeaderViewConfiguration()
        nameLabelConfiguration()
        editButtonConfiguration()
        deleteButtonConfiguration()
        exercisesLabelConfiguration()
        volumeLabelConfiguration()
    }
    
    private func nameHeaderViewConfiguration() {
        nameHeaderView.backgroundColor = Resources.Colors.workoutCellNameHeaderColor
        // Скругление только верхних углов
        nameHeaderView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        nameHeaderView.layer.cornerRadius = Constants.nameHeaderViewCornerRadius
        
        // Констрейнты
        nameHeaderView.translatesAutoresizingMaskIntoConstraints = false
        nameHeaderView.pinTop(to: contentView.topAnchor)
        nameHeaderView.pinLeft(to: contentView.leadingAnchor)
        nameHeaderView.pinRight(to: contentView.trailingAnchor)
    }
    
    private func nameLabelConfiguration() {
        nameLabel.font = Resources.Fonts.workoutNameFont
        nameLabel.textColor = Resources.Colors.titleWhite
        
        // Констрейнты
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.pinCenterY(to: nameHeaderView.centerYAnchor)
        nameLabel.pinLeft(to: nameHeaderView.leadingAnchor, Constants.nameLabelLeftPadding)
    }
    
    
    private func editButtonConfiguration() {
        editButton.setImage(Resources.Images.Workout.editButtonImage, for: .normal)
        
        // Констрейнты
        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.pinTop(to: nameHeaderView.topAnchor, Constants.editButtonTopPadding)
        editButton.pinRight(to: nameHeaderView.trailingAnchor, Constants.editButtonRightPadding)
        editButton.pinBottom(to: nameHeaderView.bottomAnchor, Constants.editButtonBottomPadding)
    }
    
    private func deleteButtonConfiguration() {
        deleteButton.setImage(Resources.Images.Workout.deleteButtonImage, for: .normal)
        
        // Констрейнты
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.pinTop(to: nameHeaderView.topAnchor, Constants.deleteButtonTopPadding)
        deleteButton.pinRight(to: editButton.leadingAnchor, Constants.deleteButtonRightPadding)
        deleteButton.pinBottom(to: nameHeaderView.bottomAnchor, Constants.deleteButtonBottomPadding)
    }
    
    private func exercisesLabelConfiguration() {
        exercisesLabel.font = Resources.Fonts.workoutExerciseFont
        exercisesLabel.textColor = Resources.Colors.titleWhite
        exercisesLabel.numberOfLines = 0
        
        // Констрейнты
        exercisesLabel.translatesAutoresizingMaskIntoConstraints = false
        exercisesLabel.pinTop(to: nameHeaderView.bottomAnchor, Constants.exercisesLabelTopPadding)
        exercisesLabel.pinLeft(to: contentView.leadingAnchor, Constants.exercisesLabelLeftPadding)
        exercisesLabel.pinRight(to: contentView.trailingAnchor, Constants.exercisesLabelRightPadding)
    }
    
    private func volumeLabelConfiguration() {
        volumeLabel.font = Resources.Fonts.workoutExerciseFont
        volumeLabel.textColor = Resources.Colors.titleWhite
        
        // Констрейнты
        volumeLabel.translatesAutoresizingMaskIntoConstraints = false
        volumeLabel.pinBottom(to: contentView.bottomAnchor, Constants.volumeLabelBottomPadding)
        volumeLabel.pinRight(to: contentView.trailingAnchor, Constants.volumeLabelRightPadding)
        volumeLabel.pinTop(to: exercisesLabel.bottomAnchor, Constants.volumeLabelTopPadding)
    }
    
    // MARK: - Public Methods
    func configure(with displayedWorkout: WorkoutModels.FetchWorkouts.ViewModel.DisplayedWorkout) {
        nameLabel.text = displayedWorkout.name
        exercisesLabel.text = displayedWorkout.exercises.joined(separator: "\n\n")
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
