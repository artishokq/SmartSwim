//
//  StopwatchPresenter.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.02.2025.
//

import UIKit

protocol StopwatchPresentationLogic {
    func presentTimerTick(response: StopwatchModels.TimerTick.Response)
    func presentMainButtonAction(response: StopwatchModels.MainButtonAction.Response)
    func presentLapRecording(response: StopwatchModels.LapRecording.Response)
    func presentFinish(response: StopwatchModels.Finish.Response)
}

final class StopwatchPresenter: StopwatchPresentationLogic {
    // MARK: - Fields
    weak var viewController: StopwatchDisplayLogic?
    
    // MARK: - Present TimerTick
    func presentTimerTick(response: StopwatchModels.TimerTick.Response) {
        let formattedGlobalTime = formatTime(response.globalTime)
        let formattedLapTime = formatTime(response.lapTime)
        let viewModel = StopwatchModels.TimerTick.ViewModel(formattedGlobalTime: formattedGlobalTime,
                                                            formattedActiveLapTime: formattedLapTime)
        viewController?.displayTimerTick(viewModel: viewModel)
    }
    
    // MARK: - Present MainButton Action
    func presentMainButtonAction(response: StopwatchModels.MainButtonAction.Response) {
        let viewModel = StopwatchModels.MainButtonAction.ViewModel(buttonTitle: response.nextButtonTitle,
                                                                   buttonColor: response.nextButtonColor)
        viewController?.displayMainButtonAction(viewModel: viewModel)
    }
    
    // MARK: - Present LapRecording
    func presentLapRecording(response: StopwatchModels.LapRecording.Response) {
        let formattedLapTime = formatTime(response.lapTime)
        let viewModel = StopwatchModels.LapRecording.ViewModel(lapNumber: response.lapNumber,
                                                               lapTimeString: formattedLapTime)
        viewController?.displayLapRecording(viewModel: viewModel)
    }
    
    // MARK: - Present Finish
    func presentFinish(response: StopwatchModels.Finish.Response) {
        let viewModel = StopwatchModels.Finish.ViewModel(buttonTitle: response.finalButtonTitle,
                                                         buttonColor: response.finalButtonColor)
        viewController?.displayFinish(viewModel: viewModel)
    }
    
    // MARK: - Private Methods
    // Форматирует время в строку "MM:SS,CC"
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time - floor(time)) * 100)
        return String(format: "%02d:%02d,%02d", minutes, seconds, centiseconds)
    }
}
