//
//  DiaryStartDetailPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.03.2025.
//

import Foundation
import UIKit

protocol DiaryStartDetailPresentationLogic {
    func presentStartDetails(response: DiaryStartDetailModels.FetchStartDetails.Response)
    func presentRecommendationLoading(response: DiaryStartDetailModels.RecommendationLoading.Response)
    func presentRecommendationReceived(response: DiaryStartDetailModels.RecommendationReceived.Response)
}

final class DiaryStartDetailPresenter: DiaryStartDetailPresentationLogic {
    weak var viewController: DiaryStartDetailDisplayLogic?
    
    // MARK: - Present Start Details
    func presentStartDetails(response: DiaryStartDetailModels.FetchStartDetails.Response) {
        // Формируем информацию для хедера
        let distanceWithStyle = "\(response.totalMeters)м \(getSwimStyleDescription(response.swimmingStyle))"
        let totalTimeString = formatTime(response.totalTime)
        
        // Сравнение времени
        let timeComparisonString: String
        let comparisonColor: UIColor
        
        if response.isCurrentBest {
            timeComparisonString = "лучший результат"
            comparisonColor = UIColor(hexString: "#4CD964") ?? .green
        } else {
            // Подсчитываем разницу времени
            let timeDifference = response.totalTime - response.bestTime
            timeComparisonString = "+" + formatTime(timeDifference)
            comparisonColor = UIColor(hexString: "#FF4F4F") ?? .red
        }
        
        // Дата и размер бассейна
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let dateString = dateFormatter.string(from: response.date)
        let poolSizeString = "Бассейн: \(response.poolSize)м"
        
        // Создаём хедер инфо
        let headerInfo = DiaryStartDetailModels.FetchStartDetails.ViewModel.HeaderInfo(
            distanceWithStyle: distanceWithStyle,
            totalTime: totalTimeString,
            timeComparisonString: timeComparisonString,
            dateString: dateString,
            poolSizeString: poolSizeString,
            comparisonColor: comparisonColor
        )
        
        // Формируем информацию для отрезков
        var lapDetails: [DiaryStartDetailModels.FetchStartDetails.ViewModel.LapDetail] = []
        
        for lap in response.laps {
            lapDetails.append(DiaryStartDetailModels.FetchStartDetails.ViewModel.LapDetail(
                title: "Отрезок \(lap.lapNumber)",
                pulse: "\(lap.pulse) уд/мин",
                strokes: "\(lap.strokes)",
                time: formatTime(lap.lapTime)
            ))
        }
        
        // Рекомендация от ИИ
        let recommendationText: String
        if response.hasRecommendation, let text = response.recommendationText {
            // Если рекомендация уже есть из API, используем ее
            recommendationText = text
        } else if response.isLoadingRecommendation {
            // Если рекомендация загружается, показываем соответствующий текст
            recommendationText = "Загрузка рекомендации..."
        } else {
            // По умолчанию показываем "Подождите..."
            recommendationText = "Подождите, ИИ анализирует ваш заплыв..."
        }
        
        let viewModel = DiaryStartDetailModels.FetchStartDetails.ViewModel(
            headerInfo: headerInfo,
            lapDetails: lapDetails,
            recommendationText: recommendationText,
            isLoadingRecommendation: response.isLoadingRecommendation
        )
        
        viewController?.displayStartDetails(viewModel: viewModel)
    }
    
    // MARK: - Present Recommendation Loading
    func presentRecommendationLoading(response: DiaryStartDetailModels.RecommendationLoading.Response) {
        let viewModel = DiaryStartDetailModels.RecommendationLoading.ViewModel(isLoading: response.isLoading)
        viewController?.displayRecommendationLoading(viewModel: viewModel)
    }
    
    // MARK: - Present Recommendation Received
    func presentRecommendationReceived(response: DiaryStartDetailModels.RecommendationReceived.Response) {
        let viewModel = DiaryStartDetailModels.RecommendationReceived.ViewModel(
            recommendationText: response.recommendationText
        )
        viewController?.displayRecommendationReceived(viewModel: viewModel)
    }
    
    // MARK: - Helper Methods
    private func getSwimStyleDescription(_ styleRawValue: Int16) -> String {
        let style = SwimStyle(rawValue: styleRawValue) ?? .freestyle
        switch style {
        case .freestyle: return "Вольный стиль"
        case .breaststroke: return "Брасс"
        case .backstroke: return "На спине"
        case .butterfly: return "Баттерфляй"
        case .medley: return "Комплекс"
        case .any: return "Вольный стиль"
        }
    }
    
    private func formatTime(_ totalSeconds: Double) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        let milliseconds = Int(round((totalSeconds.truncatingRemainder(dividingBy: 1)) * 100))
        
        return String(format: "%02d:%02d,%02d", minutes, seconds, milliseconds)
    }
}
