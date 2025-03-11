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
}

final class DiaryStartDetailPresenter: DiaryStartDetailPresentationLogic {
    weak var viewController: DiaryStartDetailDisplayLogic?
    
    // MARK: - Present Start Details
    func presentStartDetails(response: DiaryStartDetailModels.FetchStartDetails.Response) {
        // Format header information
        let distanceWithStyle = "\(response.totalMeters)м \(getSwimStyleDescription(response.swimmingStyle))"
        let totalTimeString = formatTime(response.totalTime)
        
        // Time comparison
        let timeComparisonString: String
        let comparisonColor: UIColor
        
        if response.isCurrentBest {
            timeComparisonString = "лучший результат"
            comparisonColor = UIColor(hexString: "#4CD964") ?? .green // Success green
        } else {
            // Calculate the time difference
            let timeDifference = response.totalTime - response.bestTime
            timeComparisonString = "+" + formatTime(timeDifference)
            comparisonColor = UIColor(hexString: "#FF4F4F") ?? .red // Warning red
        }
        
        // Format date and pool size
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        let dateString = dateFormatter.string(from: response.date)
        let poolSizeString = "Бассейн: \(response.poolSize)м"
        
        // Create header info
        let headerInfo = DiaryStartDetailModels.FetchStartDetails.ViewModel.HeaderInfo(
            distanceWithStyle: distanceWithStyle,
            totalTime: totalTimeString,
            timeComparisonString: timeComparisonString,
            dateString: dateString,
            poolSizeString: poolSizeString,
            comparisonColor: comparisonColor
        )
        
        // Format lap details
        var lapDetails: [DiaryStartDetailModels.FetchStartDetails.ViewModel.LapDetail] = []
        
        // Add individual lap rows
        for lap in response.laps {
            lapDetails.append(DiaryStartDetailModels.FetchStartDetails.ViewModel.LapDetail(
                title: "Отрезок \(lap.lapNumber)",
                pulse: "\(lap.pulse) уд/мин",
                strokes: "\(lap.strokes)",
                time: formatTime(lap.lapTime)
            ))
        }
        
        // Generate recommendation text based on lap performance
        let recommendationText = generateRecommendation(for: response)
        
        // Create view model
        let viewModel = DiaryStartDetailModels.FetchStartDetails.ViewModel(
            headerInfo: headerInfo,
            lapDetails: lapDetails,
            recommendationText: recommendationText
        )
        
        viewController?.displayStartDetails(viewModel: viewModel)
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
        let milliseconds = Int((totalSeconds.truncatingRemainder(dividingBy: 1)) * 100)
        
        return String(format: "%02d:%02d,%02d", minutes, seconds, milliseconds)
    }
    
    private func generateRecommendation(for response: DiaryStartDetailModels.FetchStartDetails.Response) -> String {
        // Example implementation - in a real app, this would be more sophisticated
        let sortedLaps = response.laps.sorted { $0.lapNumber < $1.lapNumber }
        
        if sortedLaps.count < 2 {
            return "Недостаточно данных для анализа."
        }
        
        // Check if pace is consistent
        let times = sortedLaps.map { $0.lapTime }
        let fastest = times.min() ?? 0
        let slowest = times.max() ?? 0
        let variance = slowest - fastest
        
        // Check pulse trend
        let pulses = sortedLaps.map { $0.pulse }
        let firstHalfAvgPulse = Array(pulses.prefix(pulses.count / 2)).reduce(0, +) / Int16(pulses.count / 2)
        let secondHalfAvgPulse = Array(pulses.suffix(pulses.count / 2)).reduce(0, +) / Int16(pulses.count / 2)
        let pulseIncrease = secondHalfAvgPulse - firstHalfAvgPulse
        
        // Get stroke efficiency (higher = better)
        let strokesPerLap = sortedLaps.map { $0.strokes }
        let avgStrokes = strokesPerLap.reduce(0, +) / Int16(strokesPerLap.count)
        
        // Generate recommendation
        var recommendation = "Ваш контрольный старт на \(response.totalMeters) м \(getSwimStyleDescription(response.swimmingStyle).lowercased()) показывает "
        
        if variance > 5 {
            recommendation += "хороший потенциал, но требует работы над равномерностью раскладки. "
        } else {
            recommendation += "хорошую равномерность темпа. "
        }
        
        if pulseIncrease > 15 {
            recommendation += "Первая половина дистанции выполнена экономично, с низким пульсом и количеством гребков, однако темп снижается во втором \(response.poolSize)-метровом отрезке, что указывает на неравномерное распределение усилий. "
        } else {
            recommendation += "Вы хорошо поддерживаете стабильный пульс на протяжении всей дистанции. "
        }
        
        if avgStrokes > 30 {
            recommendation += "Завершающий спурт с резким увеличением гребков (до \(strokesPerLap.max() ?? 0)) и пульса (\(pulses.max() ?? 0) уд/мин) демонстрирует высокий резерв скорости, но его лучше растянуть на более продолжительный участок."
        } else {
            recommendation += "Хорошая техника гребка с экономичным количеством движений."
        }
        
        recommendation += "\n\nРекомендация: потренируйте равномерный темп с акцентом на второй 50 метров (например, серии 4×200 м с контролем раскладки). Добавьте отрезки 8×50 м с акцентом на сильный финиш, чтобы развить скоростную выносливость."
        
        return recommendation
    }
}
