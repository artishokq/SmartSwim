//
//  StartDetailLapCell.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.03.2025.
//

import Foundation
import UIKit

final class StartDetailLapCell: UITableViewCell {
    // MARK: - Constants
    private enum Constants {
        static let titleFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .regular)
        static let detailFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        static let textColor = UIColor(hexString: "#FFFFFF")
        static let separatorColor = UIColor(hexString: "#4C507B")
        static let separatorHeight: CGFloat = 1
        static let contentPadding: CGFloat = 16
        
        static let titleWidthPercentage: CGFloat = 0.25
        static let pulseWidthPercentage: CGFloat = 0.20
        static let strokesWidthPercentage: CGFloat = 0.20
        static let timeWidthPercentage: CGFloat = 0.35
    }
    
    // MARK: - Properties
    static let identifier = "StartDetailLapCell"
    
    private let titleLabel: UILabel = UILabel()
    private let pulseLabel: UILabel = UILabel()
    private let strokesLabel: UILabel = UILabel()
    private let timeLabel: UILabel = UILabel()
    private let separator: UIView = UIView()
    
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
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(pulseLabel)
        contentView.addSubview(strokesLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(separator)
        
        titleLabel.textColor = Constants.textColor
        titleLabel.font = Constants.titleFont
        
        pulseLabel.textColor = Constants.textColor
        pulseLabel.font = Constants.detailFont
        pulseLabel.textAlignment = .center
        
        strokesLabel.textColor = Constants.textColor
        strokesLabel.font = Constants.detailFont
        strokesLabel.textAlignment = .center
        
        timeLabel.textColor = Constants.textColor
        timeLabel.font = Constants.detailFont
        timeLabel.textAlignment = .center
        
        separator.backgroundColor = Constants.separatorColor
        
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pulseLabel.translatesAutoresizingMaskIntoConstraints = false
        strokesLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        // Подсчитываем доступную ширину и ширину колон
        let availableWidth = UIScreen.main.bounds.width - (2 * Constants.contentPadding)
        let titleWidth = availableWidth * Constants.titleWidthPercentage
        let pulseWidth = availableWidth * Constants.pulseWidthPercentage
        let strokesWidth = availableWidth * Constants.strokesWidthPercentage
        
        
        titleLabel.pinLeft(to: contentView.leadingAnchor, Constants.contentPadding)
        titleLabel.pinCenterY(to: contentView.centerYAnchor)
        titleLabel.setWidth(titleWidth)
        
        pulseLabel.pinLeft(to: titleLabel.trailingAnchor)
        pulseLabel.pinCenterY(to: contentView.centerYAnchor)
        pulseLabel.setWidth(pulseWidth)
        
        strokesLabel.pinLeft(to: pulseLabel.trailingAnchor)
        strokesLabel.pinCenterY(to: contentView.centerYAnchor)
        strokesLabel.setWidth(strokesWidth)
        
        timeLabel.pinLeft(to: strokesLabel.trailingAnchor)
        timeLabel.pinCenterY(to: contentView.centerYAnchor)
        timeLabel.pinRight(to: contentView.trailingAnchor, Constants.contentPadding)
        
        separator.pinBottom(to: contentView.bottomAnchor)
        separator.pinLeft(to: contentView.leadingAnchor)
        separator.pinRight(to: contentView.trailingAnchor)
        separator.setHeight(Constants.separatorHeight)
    }
    
    // MARK: - Configuration
    func configure(with lapDetail: DiaryStartDetailModels.FetchStartDetails.ViewModel.LapDetail) {
        titleLabel.text = lapDetail.title
        pulseLabel.text = lapDetail.pulse
        strokesLabel.text = lapDetail.strokes
        timeLabel.text = lapDetail.time
    }
    
    // MARK: - Public Methods
    func hideSeparator() {
        separator.isHidden = true
    }
}
