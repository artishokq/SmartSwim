//
//  WorkoutCompletionView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 24.03.2025.
//

import Foundation
import SwiftUI

struct WorkoutCompletionView: View {
    private enum Constants {
        static let congratsText: String = "Отлично!"
        static let completionText: String = "Тренировка закончена!"
        static let buttonText: String = "Завершить"
        static let autoCloseText: String = "Автозакрытие:"
        
        static let congratsFontSize: CGFloat = 28
        static let completionFontSize: CGFloat = 16
        static let buttonFontSize: CGFloat = 16
        static let autoCloseFontSize: CGFloat = 12
        
        static let stackSpacing: CGFloat = 12
        static let buttonCornerRadius: CGFloat = 8
        static let buttonMaxWidth: CGFloat = 120
        static let buttonMinHeight: CGFloat = 36
        
        static let congratsColor: Color = Color.yellow
        static let buttonBackgroundColor: Color = Color.green
        static let buttonTextColor: Color = Color.black
        static let backgroundColor: Color = Color.black
        static let autoCloseColor: Color = Color.gray
    }
    
    let onComplete: () -> Void
    @State private var isButtonDisabled: Bool = false
    @State private var autoCloseCounter: Int = 11
    
    var body: some View {
        VStack(spacing: Constants.stackSpacing) {
            Text(Constants.congratsText)
                .font(.system(size: Constants.congratsFontSize, weight: .bold))
                .foregroundColor(Constants.congratsColor)
            
            Text(Constants.completionText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineLimit(nil)
                .font(.system(size: Constants.completionFontSize, weight: .medium))
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: {
                if !isButtonDisabled {
                    isButtonDisabled = true
                    onComplete()
                }
            }) {
                Text(Constants.buttonText)
                    .font(.system(size: Constants.buttonFontSize, weight: .medium))
                    .frame(maxWidth: Constants.buttonMaxWidth, minHeight: Constants.buttonMinHeight)
                    .background(Constants.buttonBackgroundColor)
                    .foregroundColor(Constants.buttonTextColor)
                    .cornerRadius(Constants.buttonCornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isButtonDisabled)
            
            Text("\(Constants.autoCloseText) \(autoCloseCounter)")
                .font(.system(size: Constants.autoCloseFontSize))
                .foregroundColor(Constants.autoCloseColor)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(Constants.backgroundColor)
        .onAppear {
            startAutoCloseTimer()
        }
    }
    
    private func startAutoCloseTimer() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if autoCloseCounter > 0 {
                autoCloseCounter -= 1
            } else {
                timer.invalidate()
                if !isButtonDisabled {
                    isButtonDisabled = true
                    onComplete()
                }
            }
        }
    }
}
