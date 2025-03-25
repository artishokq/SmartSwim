//
//  DiaryPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 03.03.2025.
//

import Foundation

protocol DiaryPresentationLogic {
    func presentStarts(response: DiaryModels.FetchStarts.Response)
    func presentDeleteStart(response: DiaryModels.DeleteStart.Response)
    func presentStartDetail(response: DiaryModels.ShowStartDetail.Response)
    func presentCreateStart(response: DiaryModels.CreateStart.Response)
    func presentWorkoutSessions(response: DiaryModels.FetchWorkoutSessions.Response)
    func presentDeleteWorkoutSession(response: DiaryModels.DeleteWorkoutSession.Response)
    func presentWorkoutSessionDetail(response: DiaryModels.ShowWorkoutSessionDetail.Response)
}

final class DiaryPresenter: DiaryPresentationLogic {
    weak var viewController: DiaryDisplayLogic?
    
    // MARK: - Present Starts
    func presentStarts(response: DiaryModels.FetchStarts.Response) {
        let displayedStarts = response.starts.map { startData -> DiaryModels.FetchStarts.ViewModel.DisplayedStart in
            // Форматирование даты
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let dateString = dateFormatter.string(from: startData.date)
            
            // Форматирование метров
            let metersString = "\(startData.totalMeters)м"
            
            // Форматирование стиля
            let styleString = getSwimStyleDescription(startData.swimmingStyle)
            
            // Форматирование времени
            let timeString = formatTime(startData.totalTime)
            
            return DiaryModels.FetchStarts.ViewModel.DisplayedStart(
                id: startData.id,
                dateString: dateString,
                metersString: metersString,
                styleString: styleString,
                timeString: timeString
            )
        }
        
        let viewModel = DiaryModels.FetchStarts.ViewModel(starts: displayedStarts)
        viewController?.displayStarts(viewModel: viewModel)
    }
    
    // MARK: - Present Delete Start
    func presentDeleteStart(response: DiaryModels.DeleteStart.Response) {
        let viewModel = DiaryModels.DeleteStart.ViewModel(index: response.index)
        viewController?.displayDeleteStart(viewModel: viewModel)
    }
    
    // MARK: - Present Start Detail
    func presentStartDetail(response: DiaryModels.ShowStartDetail.Response) {
        let viewModel = DiaryModels.ShowStartDetail.ViewModel(startID: response.startID)
        viewController?.displayStartDetail(viewModel: viewModel)
    }
    
    // MARK: - Present Create Start
    func presentCreateStart(response: DiaryModels.CreateStart.Response) {
        let viewModel = DiaryModels.CreateStart.ViewModel()
        viewController?.displayCreateStart(viewModel: viewModel)
    }
    
    // MARK: - Present Workout Sessions
    func presentWorkoutSessions(response: DiaryModels.FetchWorkoutSessions.Response) {
        let displayedSessions = response.workoutSessions.map { sessionData -> DiaryModels.FetchWorkoutSessions.ViewModel.DisplayedWorkoutSession in
            // Форматирование даты
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd.MM.yyyy"
            let dateString = dateFormatter.string(from: sessionData.date)
            
            // Форматирование метров
            let metersString = "\(sessionData.totalMeters)м"
            
            // Форматирование времени для отображения (не используется в ячейке напрямую)
            let timeString = formatTimeWorkout(sessionData.totalTime)
            
            // Использование отформатированных строк для упражнений
            let exerciseStrings = sessionData.exercises.map { $0.formattedString }
            
            return DiaryModels.FetchWorkoutSessions.ViewModel.DisplayedWorkoutSession(
                id: sessionData.id,
                dateString: dateString,
                totalMeters: metersString,
                totalTimeString: timeString,
                rawTotalSeconds: sessionData.totalTime,
                exercises: exerciseStrings
            )
        }
        
        let viewModel = DiaryModels.FetchWorkoutSessions.ViewModel(workoutSessions: displayedSessions)
        viewController?.displayWorkoutSessions(viewModel: viewModel)
    }
    
    // MARK: - Present Delete Workout Session
    func presentDeleteWorkoutSession(response: DiaryModels.DeleteWorkoutSession.Response) {
        let viewModel = DiaryModels.DeleteWorkoutSession.ViewModel(index: response.index)
        viewController?.displayDeleteWorkoutSession(viewModel: viewModel)
    }
    
    // MARK: - Present Workout Session Detail
    func presentWorkoutSessionDetail(response: DiaryModels.ShowWorkoutSessionDetail.Response) {
        let viewModel = DiaryModels.ShowWorkoutSessionDetail.ViewModel(sessionID: response.sessionID)
        viewController?.displayWorkoutSessionDetail(viewModel: viewModel)
    }
    
    // MARK: - Helper Methods
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
    
    private func formatTime(_ totalSeconds: Double) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        let milliseconds = Int(round((totalSeconds.truncatingRemainder(dividingBy: 1)) * 100))
        return String(format: "%02d:%02d,%02d", minutes, seconds, milliseconds)
    }
    
    private func formatTimeWorkout(_ totalSeconds: Double) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
