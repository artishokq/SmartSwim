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
        
        var exerciseDetails: [WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail] = []
        for exerciseData in response.exercises.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let heartRates = exerciseData.heartRateReadings.map { $0.value }.filter { $0 > 0 }
            
            var avgPulse: Double = 0
            var maxPulse: Double = 0
            var minPulse: Double = 0
            
            if !heartRates.isEmpty {
                avgPulse = heartRates.reduce(0, +) / Double(heartRates.count)
                maxPulse = heartRates.max() ?? 0
                minPulse = heartRates.filter { $0 > 0 }.min() ?? 0
            }
            
            let pulseZone = determinePulseZone(averagePulse: avgPulse)
            
            let pulseAnalysis = WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail.PulseAnalysis(
                averagePulse: "\(Int(avgPulse)) уд/мин",
                maxPulse: maxPulse > 0 ? "\(Int(maxPulse)) уд/мин" : "-",
                minPulse: minPulse > 0 ? "\(Int(minPulse)) уд/мин" : "-",
                pulseZone: pulseZone
            )
            
            let poolSize = Int(response.headerData.poolSize)
            let distanceDivisor = poolSize > 0 ? poolSize : 50
            
            var avgStrokesPerPoolLength: Double = 0
            var maxStrokesPerPoolLength: Int16 = 0
            var minStrokesPerPoolLength: Int16 = Int16.max
            var hasValidStrokeData = false
            
            if !exerciseData.laps.isEmpty {
                let normalizedLaps = exerciseData.laps.map { lap ->
                    (strokes: Int16, distance: Int16) in
                    let normalizedStrokes = normalizeStrokeData(lap.strokes, forDistance: lap.distance)
                    return (normalizedStrokes, lap.distance)
                }.filter { $0.strokes > 0 && $0.distance > 0 }
                
                hasValidStrokeData = !normalizedLaps.isEmpty
                
                if hasValidStrokeData {
                    let totalNormalizedStrokes = normalizedLaps.reduce(0) { $0 + Int($1.strokes) }
                    let totalDistance = normalizedLaps.reduce(0) { $0 + Int($1.distance) }
                    
                    avgStrokesPerPoolLength = Double(totalNormalizedStrokes) / Double(totalDistance) * Double(distanceDivisor)
                    
                    for lap in normalizedLaps {
                        let strokesPerPoolLength = Double(lap.strokes) / Double(lap.distance) * Double(distanceDivisor)
                        let roundedStrokes = Int16(strokesPerPoolLength.rounded())
                        
                        if roundedStrokes > maxStrokesPerPoolLength {
                            maxStrokesPerPoolLength = roundedStrokes
                        }
                        if roundedStrokes < minStrokesPerPoolLength {
                            minStrokesPerPoolLength = roundedStrokes
                        }
                    }
                } else {
                    minStrokesPerPoolLength = 0
                }
            } else {
                minStrokesPerPoolLength = 0
            }
            
            let strokeAnalysis = WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail.StrokeAnalysis(
                averageStrokes: "\(Int(avgStrokesPerPoolLength.rounded()))",
                maxStrokes: hasValidStrokeData ? "\(maxStrokesPerPoolLength)" : "-",
                minStrokes: hasValidStrokeData && minStrokesPerPoolLength < Int16.max ? "\(minStrokesPerPoolLength)" : "-",
                totalStrokes: ""
            )
            
            let styleString = getSwimStyleDescription(exerciseData.style)
            let typeString = getExerciseTypeDescription(exerciseData.type)
            
            let hasInterval = exerciseData.hasInterval
            let intervalString = hasInterval ? "\(exerciseData.intervalMinutes):\(String(format: "%02d", exerciseData.intervalSeconds))" : "нет"
            
            let heartRateData = exerciseData.heartRateReadings.map {
                (timestamp: $0.timestamp, value: $0.value)
            }.sorted { $0.timestamp < $1.timestamp }
            
            let exerciseDetail = WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail(
                id: exerciseData.id,
                orderIndex: exerciseData.orderIndex,
                description: exerciseData.description,
                styleString: styleString,
                typeString: typeString,
                timeString: formatTime(exerciseData.totalTime),
                hasInterval: hasInterval,
                intervalString: intervalString,
                metersString: "\(exerciseData.meters * exerciseData.repetitions)м",
                repetitionsString: "\(exerciseData.repetitions)x\(exerciseData.meters)м",
                poolSize: response.headerData.poolSize,
                pulseAnalysis: pulseAnalysis,
                strokeAnalysis: strokeAnalysis,
                heartRateData: heartRateData
            )
            
            exerciseDetails.append(exerciseDetail)
        }
        
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
        
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
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
    
    private func normalizeStrokeData(_ strokes: Int16, forDistance distance: Int16) -> Int16 {
        if distance <= 0 {
            return 0
        }
        
        if strokes <= 0 {
            return 0
        }
        
        return strokes
    }
}
