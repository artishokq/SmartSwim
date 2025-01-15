//
//  HeaderCell.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 15.01.2025.
//

import UIKit

protocol HeaderCellDelegate: AnyObject {
    func headerCell(_ cell: HeaderCell, didUpdateName name: String)
    func headerCell(_ cell: HeaderCell, didSelectPoolSize poolSize: PoolSize)
}

final class HeaderCell: UITableViewCell {
    // MARK: - Constants
    private enum Constants {
        static let cellCornerRadius: CGFloat = 12
        static let fieldCrnerRadius: CGFloat = 6
        
        static let nameTextFieldTopPadding: CGFloat = 12
        static let nameTextFieldRightPadding: CGFloat = 12
        static let nameTextFieldLeftPadding: CGFloat = 12
        static let nameTextFieldHeight: CGFloat = 38
        static let textPaddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        static let textPlaceholderTransparency: CGFloat = 0.5
        
        static let poolSizeSegmentControlTopPadding: CGFloat = 6
        static let poolSizeSegmentControlBottomPadding: CGFloat = 12
        static let poolSizeSegmentControlRightPadding: CGFloat = 12
        static let poolSizeSegmentControlLeftPadding: CGFloat = 12
        static let poolSizeSegmentControlHeight: CGFloat = 38
    }
    
    // MARK: - Fields
    static let identifier: String = "HeaderCell"
    weak var delegate: HeaderCellDelegate?
    
    private let nameTextField: UITextField = UITextField()
    private let poolSizeSegmentControl: UISegmentedControl = UISegmentedControl()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        ConfigureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Configurations
    private func ConfigureUI() {
        backgroundColor = Resources.Colors.createCellBackgroundColor
        selectionStyle = .none
        layer.cornerRadius = Constants.cellCornerRadius
        
        contentView.addSubview(nameTextField)
        contentView.addSubview(poolSizeSegmentControl)
        
        nameTextFieldConfiguration()
        poolSizeSegmentControlConfiguration()
    }
    
    private func nameTextFieldConfiguration() {
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Resources.Colors.titleWhite.withAlphaComponent(Constants.textPlaceholderTransparency),
            .font: Resources.Fonts.workoutNamePlaceholder
        ]
        
        nameTextField.attributedPlaceholder = NSAttributedString(
            string: Resources.Strings.Workout.workoutNamePlaceholder,
            attributes: placeholderAttributes
        )
        
        nameTextField.font = Resources.Fonts.workoutNamePlaceholder
        nameTextField.textColor = Resources.Colors.titleWhite
        nameTextField.tintColor = Resources.Colors.titleWhite
        nameTextField.layer.cornerRadius = Constants.fieldCrnerRadius
        nameTextField.backgroundColor = Resources.Colors.fieldsBackgroundColor
        
        // Чтобы текст не с самого бока печатался
        let paddingView = Constants.textPaddingView
        nameTextField.leftView = paddingView
        nameTextField.leftViewMode = .always
        
        nameTextField.translatesAutoresizingMaskIntoConstraints = false
        nameTextField.pinTop(to: contentView.topAnchor, Constants.nameTextFieldTopPadding)
        nameTextField.pinRight(to: contentView.trailingAnchor, Constants.nameTextFieldRightPadding)
        nameTextField.pinLeft(to: contentView.leadingAnchor, Constants.nameTextFieldLeftPadding)
        nameTextField.setHeight(Constants.nameTextFieldHeight)
        
        nameTextField.addTarget(self, action: #selector(nameDidChange), for: .editingChanged)
    }
    
    private func poolSizeSegmentControlConfiguration() {
        let items = ["25 м", "50 м"]
        poolSizeSegmentControl.removeAllSegments()
        
        for (index, title) in items.enumerated() {
            poolSizeSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        
        poolSizeSegmentControl.selectedSegmentIndex = 0
        poolSizeSegmentControl.layer.cornerRadius = Constants.fieldCrnerRadius
        
        poolSizeSegmentControl.backgroundColor = Resources.Colors.fieldsBackgroundColor
        poolSizeSegmentControl.selectedSegmentTintColor = Resources.Colors.blueColor // TODO: ЦВЕТ?
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Resources.Colors.titleWhite,
            .font: Resources.Fonts.workoutNamePlaceholder
        ]
        
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Resources.Colors.titleWhite,
            .font: Resources.Fonts.workoutNamePlaceholder
        ]
        
        poolSizeSegmentControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        poolSizeSegmentControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        poolSizeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        poolSizeSegmentControl.pinTop(to: nameTextField.bottomAnchor, Constants.poolSizeSegmentControlTopPadding)
        poolSizeSegmentControl.setHeight(Constants.poolSizeSegmentControlHeight)
        poolSizeSegmentControl.pinRight(to: contentView.trailingAnchor, Constants.poolSizeSegmentControlRightPadding)
        poolSizeSegmentControl.pinLeft(to: contentView.leadingAnchor, Constants.poolSizeSegmentControlLeftPadding)
        poolSizeSegmentControl.pinBottom(to: contentView.bottomAnchor, Constants.poolSizeSegmentControlBottomPadding)
        
        poolSizeSegmentControl.addTarget(self, action: #selector(poolSizeDidChange), for: .valueChanged)
    }
    
    // MARK: - Actions
    @objc private func nameDidChange() {
        delegate?.headerCell(self, didUpdateName: nameTextField.text ?? "")
    }
    
    @objc private func poolSizeDidChange() {
        let poolSize: PoolSize = poolSizeSegmentControl.selectedSegmentIndex == 0 ? .poolSize25 : .poolSize50
        delegate?.headerCell(self, didSelectPoolSize: poolSize)
    }
}
