//
//  DiaryCreateStartPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 09.03.2025.
//

import UIKit

protocol DiaryCreateStartPresentationLogic {
    func presentStartCreated(response: DiaryCreateStartModels.Create.Response)
    func presentLapCount(response: DiaryCreateStartModels.CalculateLaps.Response)
    func presentCollectedData(response: DiaryCreateStartModels.CollectData.Response)
}

final class DiaryCreateStartPresenter: DiaryCreateStartPresentationLogic {
    weak var viewController: DiaryCreateStartDisplayLogic?
    
    // MARK: - Present Start Created
    func presentStartCreated(response: DiaryCreateStartModels.Create.Response) {
        let message = response.success ? "Старт успешно создан" : response.errorMessage ?? "Ошибка при создании старта"
        let viewModel = DiaryCreateStartModels.Create.ViewModel(
            success: response.success,
            message: message
        )
        viewController?.displayStartCreated(viewModel: viewModel)
    }
    
    // MARK: - Present Lap Count
    func presentLapCount(response: DiaryCreateStartModels.CalculateLaps.Response) {
        let viewModel = DiaryCreateStartModels.CalculateLaps.ViewModel(
            numberOfLaps: response.numberOfLaps
        )
        viewController?.displayLapCount(viewModel: viewModel)
    }
    
    // MARK: - Present Collected Data
    func presentCollectedData(response: DiaryCreateStartModels.CollectData.Response) {
        let viewModel = DiaryCreateStartModels.CollectData.ViewModel(
            success: response.success,
            errorMessage: response.errorMessage,
            createRequest: response.createRequest
        )
        viewController?.displayCollectedData(viewModel: viewModel)
    }
}
