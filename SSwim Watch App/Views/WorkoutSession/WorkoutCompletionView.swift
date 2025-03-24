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
        
        static let congratsFontSize: CGFloat = 36
        static let completionFontSize: CGFloat = 20
        static let buttonFontSize: CGFloat = 18
        
        static let stackSpacing: CGFloat = 24
        static let buttonCornerRadius: CGFloat = 8
        static let buttonMaxWidth: CGFloat = 140
        static let buttonMinHeight: CGFloat = 44
        
        static let congratsColor: Color = Color.yellow
        static let buttonBackgroundColor: Color = Color.green
        static let buttonTextColor: Color = Color.black
        static let backgroundColor: Color = Color.black
    }
    
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: Constants.stackSpacing) {
            Text(Constants.congratsText)
                .font(.system(size: Constants.congratsFontSize, weight: .bold))
                .foregroundColor(Constants.congratsColor)
            
            Text(Constants.completionText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .lineLimit(nil)
                .font(.system(size: Constants.completionFontSize, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: onComplete) {
                Text(Constants.buttonText)
                    .font(.system(size: Constants.buttonFontSize, weight: .medium))
                    .frame(maxWidth: Constants.buttonMaxWidth, minHeight: Constants.buttonMinHeight)
                    .background(Constants.buttonBackgroundColor)
                    .foregroundColor(Constants.buttonTextColor)
                    .cornerRadius(Constants.buttonCornerRadius)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Constants.backgroundColor)
    }
}
