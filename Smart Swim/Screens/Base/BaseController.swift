//
//  BaseController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 13.01.2025.
//

import UIKit

class BaseController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
}

@objc extension BaseController {
    
    func addView() {}
    
    func layoutView() {}
    
    func configure() {
        view.backgroundColor = Resources.Colors.background
    }
}
