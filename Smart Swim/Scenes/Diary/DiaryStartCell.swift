//
//  DiaryStartCell.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import UIKit

protocol DiaryStartCellDelegate: AnyObject {
    func startCellDidRequestDeletion(_ cell: DiaryStartCell)
}

final class DiaryStartCell: UITableViewCell {
    // MARK: - Constants
    private enum Constants {
        static let cellBackgroundColor = UIColor(hexString: "#323645")
        static let dateColor = UIColor(hexString: "#FFFFFF")
        static let metersColor = UIColor(hexString: "#FFFFFF")
        static let styleColor = UIColor(hexString: "#FFFFFF")
        static let timeColor = UIColor(hexString: "#FFFFFF")
        static let separatorColor = UIColor(hexString: "#4C507B")
        
        static let cellCornerRadius: CGFloat = 20
        
        static let headerViewCornerRadius: CGFloat = 20
        static let headerViewBackgroundColor = UIColor(hexString: "#505773")
        
        static let contentPadding: CGFloat = 14
        static let contentSpacing: CGFloat = 8
        static let separatorHeight: CGFloat = 2
        
        static let dateLabelFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let metersLabelFont = UIFont.systemFont(ofSize: 24, weight: .regular)
        static let styleLabelFont = UIFont.systemFont(ofSize: 24, weight: .regular)
        static let timeLabelFont = UIFont.systemFont(ofSize: 28, weight: .regular)
        
        static let deleteButtonRightPadding: CGFloat = 8
        static let deleteButtonTopPadding: CGFloat = 12
        static let deleteButtonBottomPadding: CGFloat = 12
        static let deleteButtonImage = UIImage(named: "deleteButton")
    }
    
    // MARK: - Properties
    static let identifier = "DiaryStartCell"
    weak var delegate: DiaryStartCellDelegate?
    
    private let containerView = UIView()
    private let headerView = UIView()
    private let dateLabel = UILabel()
    private let deleteButton = UIButton(type: .custom)
    private let metersLabel = UILabel()
    private let styleLabel = UILabel()
    private let separator = UIView()
    private let timeLabel = UILabel()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(headerView)
        headerView.addSubview(dateLabel)
        headerView.addSubview(deleteButton)
        containerView.addSubview(metersLabel)
        containerView.addSubview(styleLabel)
        containerView.addSubview(timeLabel)
        containerView.addSubview(separator)
        
        configureContainerView()
        configureHeaderView()
        configureDateLabel()
        configureDeleteButton()
        configureMetersLabel()
        configureStyleLabel()
        configureSeparator()
        configureTimeLabel()
    }
    
    private func configureContainerView() {
        containerView.backgroundColor = Constants.cellBackgroundColor
        containerView.layer.cornerRadius = Constants.cellCornerRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.pinTop(to: contentView.topAnchor)
        containerView.pinLeft(to: contentView.leadingAnchor)
        containerView.pinRight(to: contentView.trailingAnchor)
        containerView.pinBottom(to: contentView.bottomAnchor)
    }
    
    private func configureHeaderView() {
        headerView.backgroundColor = Constants.headerViewBackgroundColor
        headerView.layer.cornerRadius = Constants.headerViewCornerRadius
        headerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.pinTop(to: containerView.topAnchor)
        headerView.pinLeft(to: containerView.leadingAnchor)
        headerView.pinRight(to: containerView.trailingAnchor)
    }
    
    private func configureDateLabel() {
        dateLabel.textColor = Constants.dateColor
        dateLabel.font = Constants.dateLabelFont
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.pinLeft(to: headerView.leadingAnchor, Constants.contentPadding)
        dateLabel.pinCenterY(to: headerView.centerYAnchor)
    }
    
    private func configureDeleteButton() {
        deleteButton.setImage(Constants.deleteButtonImage, for: .normal)
        
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.pinTop(to: headerView.topAnchor, Constants.deleteButtonTopPadding)
        deleteButton.pinRight(to: headerView.trailingAnchor, Constants.deleteButtonRightPadding)
        deleteButton.pinBottom(to: headerView.bottomAnchor, Constants.deleteButtonBottomPadding)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    private func configureMetersLabel() {
        metersLabel.textColor = Constants.metersColor
        metersLabel.font = Constants.metersLabelFont
        
        metersLabel.translatesAutoresizingMaskIntoConstraints = false
        metersLabel.pinTop(to: headerView.bottomAnchor, Constants.contentPadding)
        metersLabel.pinLeft(to: headerView.leadingAnchor, Constants.contentPadding)
    }
    
    private func configureStyleLabel() {
        styleLabel.textColor = Constants.styleColor
        styleLabel.font = Constants.styleLabelFont
        
        styleLabel.translatesAutoresizingMaskIntoConstraints = false
        styleLabel.pinTop(to: headerView.bottomAnchor, Constants.contentPadding)
        styleLabel.pinLeft(to: metersLabel.trailingAnchor, Constants.contentSpacing)
    }
    
    private func configureSeparator() {
        separator.backgroundColor = Constants.separatorColor
        
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.pinLeft(to: containerView.leadingAnchor)
        separator.pinRight(to: containerView.trailingAnchor)
        separator.setHeight(Constants.separatorHeight)
        separator.pinTop(to: styleLabel.bottomAnchor, Constants.contentPadding)
    }
    
    private func configureTimeLabel() {
        timeLabel.textColor = Constants.timeColor
        timeLabel.font = Constants.timeLabelFont
        timeLabel.textAlignment = .right
        
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.pinRight(to: containerView.trailingAnchor, Constants.contentPadding)
        timeLabel.pinBottom(to: containerView.bottomAnchor, Constants.contentPadding)
        timeLabel.pinTop(to: separator.bottomAnchor, Constants.contentPadding)
    }
    
    // MARK: - Actions
    @objc private func deleteButtonTapped() {
        delegate?.startCellDidRequestDeletion(self)
    }
    
    // MARK: - Public Methods
    func configure(with displayedStart: DiaryModels.FetchStarts.ViewModel.DisplayedStart) {
        dateLabel.text = "Старт от " + displayedStart.dateString
        metersLabel.text = displayedStart.metersString
        styleLabel.text = displayedStart.styleString
        timeLabel.text = displayedStart.timeString
    }
}
