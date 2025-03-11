//
//  StartDetailTableHeader.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.03.2025.
//

import Foundation
import UIKit

final class StartDetailTableHeader: UITableViewHeaderFooterView {
    // MARK: - Constants
    private enum Constants {
        static let backgroundColor = UIColor(hexString: "#505773")
        static let textColor = UIColor(hexString: "#FFFFFF")
        static let font: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        static let contentPadding: CGFloat = 16
        static let headerCornerRadius: CGFloat = 12
        
        static let pulseLabelText: String = "Пульс"
        static let strokesLabelText: String = "Гребки"
        static let timeLabelText: String = "Время"
        
        static let titleWidthPercentage: CGFloat = 0.25
        static let pulseWidthPercentage: CGFloat = 0.20
        static let strokesWidthPercentage: CGFloat = 0.20
        static let timeWidthPercentage: CGFloat = 0.35
    }
    
    // MARK: - Properties
    static let identifier = "StartDetailTableHeader"
    
    private let titleLabel: UILabel = UILabel()
    private let pulseLabel: UILabel = UILabel()
    private let strokesLabel: UILabel = UILabel()
    private let timeLabel: UILabel = UILabel()
    
    // MARK: - Initialization
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        contentView.backgroundColor = Constants.backgroundColor
        contentView.layer.cornerRadius = Constants.headerCornerRadius
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentView.clipsToBounds = true
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(pulseLabel)
        contentView.addSubview(strokesLabel)
        contentView.addSubview(timeLabel)
        
        titleLabel.text = ""
        titleLabel.textColor = Constants.textColor
        titleLabel.font = Constants.font
        
        pulseLabel.text = Constants.pulseLabelText
        pulseLabel.textColor = Constants.textColor
        pulseLabel.font = Constants.font
        pulseLabel.textAlignment = .center
        
        strokesLabel.text = Constants.strokesLabelText
        strokesLabel.textColor = Constants.textColor
        strokesLabel.font = Constants.font
        strokesLabel.textAlignment = .center
        
        timeLabel.text = Constants.timeLabelText
        timeLabel.textColor = Constants.textColor
        timeLabel.font = Constants.font
        timeLabel.textAlignment = .center
        
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pulseLabel.translatesAutoresizingMaskIntoConstraints = false
        strokesLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
    }
}
