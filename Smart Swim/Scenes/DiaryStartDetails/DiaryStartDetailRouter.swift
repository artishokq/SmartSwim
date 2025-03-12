//
//  DiaryStartDetailRouter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.03.2025.
//

import Foundation

protocol DiaryStartDetailRoutingLogic {

}

protocol DiaryStartDetailDataPassing {
    var dataStore: DiaryStartDetailDataStore? { get }
}

final class DiaryStartDetailRouter: NSObject, DiaryStartDetailRoutingLogic, DiaryStartDetailDataPassing {
    weak var viewController: DiaryStartDetailViewController?
    var dataStore: DiaryStartDetailDataStore?
}
