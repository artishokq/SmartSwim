//
//  WorkoutSessionDetailPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 25.03.2025.
//

import UIKit

protocol WorkoutSessionDetailPresentationLogic {
    func presentSessionDetails(response: WorkoutSessionDetailModels.FetchSessionDetails.Response)
    func presentRecommendation(response: WorkoutSessionDetailModels.FetchRecommendation.Response)
}

final class WorkoutSessionDetailPresenter: WorkoutSessionDetailPresentationLogic {
    weak var viewController: WorkoutSessionDetailDisplayLogic?
    
    // MARK: - Present Session Details
    func presentSessionDetails(response: WorkoutSessionDetailModels.FetchSessionDetails.Response) {
        // Форматируем данные для карточек
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        let dateString = dateFormatter.string(from: response.headerData.date)
        
        let totalTimeString = formatTime(response.headerData.totalTime)
        
        let summaryData = WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.SummaryData(
            dateString: dateString,
            totalTimeString: totalTimeString,
            totalMetersString: "\(response.headerData.totalMeters)м",
            totalCaloriesString: "\(Int(response.headerData.totalCalories)) ккал",
            averageHeartRateString: "\(Int(response.headerData.averageHeartRate)) уд/м",
            poolSizeString: "Бассейн \(response.headerData.poolSize)м"
        )
        
        // Форматируем данные для упражнений
        var exerciseDetails: [WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail] = []
        
        for exerciseData in response.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            // Данные для анализа пульса
            let heartRates = exerciseData.laps.map { $0.heartRate }
            let avgPulse = heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / Double(heartRates.count)
            let maxPulse = heartRates.max() ?? 0
            let minPulse = heartRates.min() ?? 0
            let pulseZone = determinePulseZone(averagePulse: avgPulse)
            
            let pulseAnalysis = WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail.PulseAnalysis(
                averagePulse: "\(Int(avgPulse)) уд/мин",
                maxPulse: "\(Int(maxPulse)) уд/мин",
                minPulse: "\(Int(minPulse)) уд/мин",
                pulseZone: pulseZone
            )
            
            // Данные для анализа гребков
            var avgStrokes: Double = 0
            var maxStrokes: Int16 = 0
            var minStrokes: Int16 = Int16.max
            var totalStrokes: Int = 0
            
            if !exerciseData.laps.isEmpty {
                for lap in exerciseData.laps {
                    if lap.strokes > maxStrokes {
                        maxStrokes = lap.strokes
                    }
                    if lap.strokes < minStrokes {
                        minStrokes = lap.strokes
                    }
                    totalStrokes += Int(lap.strokes)
                }
                
                // Среднее количество гребков на 50м
                let totalDistance = exerciseData.laps.reduce(0) { $0 + Int($1.distance) }
                if totalDistance > 0 {
                    avgStrokes = Double(totalStrokes) / Double(totalDistance) * 50.0
                }
            } else {
                minStrokes = 0
            }
            
            let strokeAnalysis = WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail.StrokeAnalysis(
                averageStrokes: "\(Int(avgStrokes.rounded()))",
                maxStrokes: "\(maxStrokes)",
                minStrokes: "\(minStrokes)",
                totalStrokes: "\(totalStrokes)"
            )
            
            // Форматирование данных об упражнении
            let styleString = getSwimStyleDescription(exerciseData.style)
            let typeString = getExerciseTypeDescription(exerciseData.type)
            
            let hasInterval = exerciseData.hasInterval
            let intervalString = hasInterval ? "\(exerciseData.intervalMinutes):\(String(format: "%02d", exerciseData.intervalSeconds))" : "нет"
            
            let exerciseDetail = WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail(
                id: exerciseData.id,
                orderIndex: exerciseData.orderIndex,
                description: exerciseData.description ?? "Упражнение",
                styleString: styleString,
                typeString: typeString,
                timeString: formatTime(exerciseData.totalTime),
                hasInterval: hasInterval,
                intervalString: intervalString,
                metersString: "\(exerciseData.meters * exerciseData.repetitions)м",
                repetitionsString: "\(exerciseData.repetitions)x\(exerciseData.meters)м",
                pulseAnalysis: pulseAnalysis,
                strokeAnalysis: strokeAnalysis
            )
            
            exerciseDetails.append(exerciseDetail)
        }
        
        // Создаем и отправляем ViewModel
        let viewModel = WorkoutSessionDetailModels.FetchSessionDetails.ViewModel(
            summaryData: summaryData,
            exercises: exerciseDetails
        )
        
        viewController?.displaySessionDetails(viewModel: viewModel)
    }
    
    // MARK: - Present Recommendation
    func presentRecommendation(response: WorkoutSessionDetailModels.FetchRecommendation.Response) {
        let text = response.recommendationText ?? "Загрузка рекомендации..."
        
        let viewModel = WorkoutSessionDetailModels.FetchRecommendation.ViewModel(
            recommendationText: text,
            isLoading: response.isLoading
        )
        
        viewController?.displayRecommendation(viewModel: viewModel)
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ totalSeconds: Double) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60
        
        if hours > 0 {
            return String(format: "%d час %02d мин", hours, minutes)
        } else {
            return String(format: "%d час %02d мин", minutes, seconds)
        }
    }
    
    private func getSwimStyleDescription(_ styleRawValue: Int16) -> String {
        let style = SwimStyle(rawValue: styleRawValue) ?? .freestyle
        switch style {
        case .freestyle: return "вольный стиль"
        case .breaststroke: return "брасс"
        case .backstroke: return "на спине"
        case .butterfly: return "баттерфляй"
        case .medley: return "комплекс"
        case .any: return "любой стиль"
        }
    }
    
    private func getExerciseTypeDescription(_ typeRawValue: Int16) -> String {
        let type = ExerciseType(rawValue: typeRawValue) ?? .main
        switch type {
        case .warmup: return "разминка"
        case .main: return "основное"
        case .cooldown: return "заминка"
        }
    }
    
    private func determinePulseZone(averagePulse: Double) -> String {
        if averagePulse < 125 {
            return "Разминка (< 125)"
        } else if averagePulse < 152 {
            return "Аэробная (126-151)"
        } else if averagePulse < 172 {
            return "Анаэробная (152-171)"
        } else {
            return "Максимальная (172+)"
        }
    }
}
