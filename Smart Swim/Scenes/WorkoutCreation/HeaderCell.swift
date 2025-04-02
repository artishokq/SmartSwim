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
        static let createCellBackgroundColor = UIColor(hexString: "#505773")
        static let fieldsBackgroundColor = UIColor(hexString: "#323645")
        static let blueColor = UIColor(hexString: "#0A84FF")
        static let titleWhite = UIColor(hexString: "#FFFFFF") ?? .white
        static let fieldsAndPlaceholdersFont = UIFont.systemFont(ofSize: 18, weight: .light)
        static let cellCornerRadius: CGFloat = 20
        static let fieldCrnerRadius: CGFloat = 9
        
        static let nameTextFieldTopPadding: CGFloat = 12
        static let nameTextFieldRightPadding: CGFloat = 9
        static let nameTextFieldLeftPadding: CGFloat = 9
        static let nameTextFieldHeight: CGFloat = 38
        static let textPaddingView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        static let textPlaceholderTransparency: CGFloat = 0.5
        static let workoutNamePlaceholder = "Название тренировки"
        
        static let poolSizeSegmentControlTopPadding: CGFloat = 9
        static let poolSizeSegmentControlBottomPadding: CGFloat = 12
        static let poolSizeSegmentControlRightPadding: CGFloat = 9
        static let poolSizeSegmentControlLeftPadding: CGFloat = 9
        static let poolSizeSegmentControlHeight: CGFloat = 38
        static let poolSizeSegmentControlItems: [String] = ["25 м", "50 м"]
        
        static let nameTextFieldTag: Int = 101
        static let poolSizeSegmentControlTag: Int = 102
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
        backgroundColor = Constants.createCellBackgroundColor
        selectionStyle = .none
        layer.cornerRadius = Constants.cellCornerRadius
        
        contentView.addSubview(nameTextField)
        contentView.addSubview(poolSizeSegmentControl)
        
        configureNameTextField()
        configurePoolSizeSegmentControl()
    }
    
    private func configureNameTextField() {
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: Constants.titleWhite.withAlphaComponent(Constants.textPlaceholderTransparency),
            .font: Constants.fieldsAndPlaceholdersFont
        ]
        
        nameTextField.attributedPlaceholder = NSAttributedString(
            string: Constants.workoutNamePlaceholder,
            attributes: placeholderAttributes
        )
        
        nameTextField.font = Constants.fieldsAndPlaceholdersFont
        nameTextField.textColor = Constants.titleWhite
        nameTextField.tintColor = Constants.titleWhite
        nameTextField.layer.cornerRadius = Constants.fieldCrnerRadius
        nameTextField.backgroundColor = Constants.fieldsBackgroundColor
        
        // Устанавливаем тег для доступа извне
        nameTextField.tag = Constants.nameTextFieldTag
        
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
    
    private func configurePoolSizeSegmentControl() {
        poolSizeSegmentControl.removeAllSegments()
        
        for (index, title) in Constants.poolSizeSegmentControlItems.enumerated() {
            poolSizeSegmentControl.insertSegment(withTitle: title, at: index, animated: false)
        }
        
        poolSizeSegmentControl.selectedSegmentIndex = 0
        poolSizeSegmentControl.layer.cornerRadius = Constants.fieldCrnerRadius
        
        // Устанавливаем тег для доступа извне
        poolSizeSegmentControl.tag = Constants.poolSizeSegmentControlTag
        
        poolSizeSegmentControl.backgroundColor = Constants.fieldsBackgroundColor
        poolSizeSegmentControl.selectedSegmentTintColor = Constants.blueColor
        
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
        
        poolSizeSegmentControl.translatesAutoresizingMaskIntoConstraints = false
        poolSizeSegmentControl.pinTop(to: nameTextField.bottomAnchor, Constants.poolSizeSegmentControlTopPadding)
        poolSizeSegmentControl.setHeight(Constants.poolSizeSegmentControlHeight)
        poolSizeSegmentControl.pinRight(to: contentView.trailingAnchor, Constants.poolSizeSegmentControlRightPadding)
        poolSizeSegmentControl.pinLeft(to: contentView.leadingAnchor, Constants.poolSizeSegmentControlLeftPadding)
        poolSizeSegmentControl.pinBottom(to: contentView.bottomAnchor, Constants.poolSizeSegmentControlBottomPadding)
        
        poolSizeSegmentControl.addTarget(self, action: #selector(poolSizeDidChange), for: .valueChanged)
    }
    
    // MARK: - Public Methods
    func configure(withName name: String, poolSize: PoolSize) {
        nameTextField.text = name
        poolSizeSegmentControl.selectedSegmentIndex = poolSize == .poolSize25 ? 0 : 1
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
