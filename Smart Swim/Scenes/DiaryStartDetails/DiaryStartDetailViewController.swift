//
//  DiaryStartDetailViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import UIKit
import CoreData

class DiaryStartDetailViewController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let backgroundColor = UIColor(hexString: "#242531")
        static let titleText = "Детали старта"
    }
    
    // MARK: - Properties
    var startID: NSManagedObjectID?
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        view.backgroundColor = Constants.backgroundColor
        title = Constants.titleText
    }
}
