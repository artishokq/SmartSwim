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
            
            // Данные для анализа гребков с учетом длины бассейна
            // Получаем размер бассейна как делитель (50м бассейн должен делиться на 50, 25м на 25)
            let poolSize = Int(response.headerData.poolSize)
            let distanceDivisor = poolSize > 0 ? poolSize : 50 // По умолчанию 50, если размер бассейна недействителен
            
            // Рассчитываем гребки на длину бассейна
            var avgStrokesPerPoolLength: Double = 0
            var maxStrokesPerPoolLength: Int16 = 0
            var minStrokesPerPoolLength: Int16 = Int16.max
            
            if !exerciseData.laps.isEmpty {
                // Подготовим массив валидированных гребков
                let validatedLaps = exerciseData.laps.map { lap ->
                    (strokes: Int16, distance: Int16) in
                    let validatedStrokes = validateStrokeData(lap.strokes, forDistance: lap.distance)
                    return (validatedStrokes, lap.distance)
                }
                
                // Считаем общие гребки и дистанцию для среднего значения
                let totalValidatedStrokes = validatedLaps.reduce(0) { $0 + Int($1.strokes) }
                let totalDistance = validatedLaps.reduce(0) { $0 + Int($1.distance) }
                
                if totalDistance > 0 {
                    avgStrokesPerPoolLength = Double(totalValidatedStrokes) / Double(totalDistance) * Double(distanceDivisor)
                }
                
                // Для max/min рассчитываем на длину бассейна для каждого отрезка
                if validatedLaps.count == 1 {
                    // Если только один отрезок, max и min одинаковые
                    let lap = validatedLaps[0]
                    if lap.distance > 0 {
                        let strokesPerPoolLength = Double(lap.strokes) / Double(lap.distance) * Double(distanceDivisor)
                        maxStrokesPerPoolLength = Int16(strokesPerPoolLength.rounded())
                        minStrokesPerPoolLength = maxStrokesPerPoolLength
                    }
                } else {
                    // Несколько отрезков - считаем для каждого
                    for lap in validatedLaps {
                        if lap.distance > 0 {
                            let strokesPerPoolLength = Double(lap.strokes) / Double(lap.distance) * Double(distanceDivisor)
                            let roundedStrokes = Int16(strokesPerPoolLength.rounded())
                            
                            if roundedStrokes > maxStrokesPerPoolLength {
                                maxStrokesPerPoolLength = roundedStrokes
                            }
                            if roundedStrokes < minStrokesPerPoolLength {
                                minStrokesPerPoolLength = roundedStrokes
                            }
                        }
                    }
                }
            } else {
                minStrokesPerPoolLength = 0
            }
            
            let strokeAnalysis = WorkoutSessionDetailModels.FetchSessionDetails.ViewModel.ExerciseDetail.StrokeAnalysis(
                averageStrokes: "\(Int(avgStrokesPerPoolLength.rounded()))",
                maxStrokes: "\(maxStrokesPerPoolLength)",
                minStrokes: "\(minStrokesPerPoolLength)",
                totalStrokes: "" // Оставляем пустым, так как не используем
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
                poolSize: response.headerData.poolSize, // Добавляем размер бассейна
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
    
    private func validateStrokeData(_ strokes: Int16, forDistance distance: Int16) -> Int16 {
        let strokesInt = Int(strokes)
        let distanceInt = Int(distance)
        
        if distanceInt <= 0 {
            return 0
        }
        
        let maxStrokesFor25m = 35
        let expectedMaxStrokes = maxStrokesFor25m * (distanceInt / 25)
        
        if strokesInt > expectedMaxStrokes * 3 / 2 {
            return Int16(expectedMaxStrokes)
        }
        
        if strokesInt == 0 && distanceInt > 0 {
            return Int16(max(distanceInt / 25 * 8, 1))
        }
        
        return strokes
    }
}
