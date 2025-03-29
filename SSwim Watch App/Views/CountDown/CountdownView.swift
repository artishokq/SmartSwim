//
//  CountdownView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 29.03.2025.
//

import SwiftUI

struct CountdownView: View {
    private enum Constants {
        static let countdownDuration: Double = 3.0
        static let circleSize: CGFloat = 130
        static let lineWidth: CGFloat = 6
        static let numberFontSize: CGFloat = 72
        static let progressColor: Color = Color.green
        static let numberColor: Color = Color.white
        static let backgroundColor: Color = Color.black
    }
    
    let onComplete: () -> Void
    
    @State private var countdown: Int = 3
    @State private var progress: Double = 0
    @State private var isAnimating: Bool = false
    
    var body: some View {
        ZStack {
            // Background
            Constants.backgroundColor
                .edgesIgnoringSafeArea(.all)
            
            ZStack {
                // Track Circle (optional - for more visibility)
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: Constants.lineWidth)
                    .frame(width: Constants.circleSize, height: Constants.circleSize)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        Constants.progressColor,
                        style: StrokeStyle(
                            lineWidth: Constants.lineWidth,
                            lineCap: .round
                        )
                    )
                    .frame(width: Constants.circleSize, height: Constants.circleSize)
                    .rotationEffect(Angle(degrees: -90))
                
                // Countdown Number
                Text("\(countdown)")
                    .font(.system(size: Constants.numberFontSize, weight: .medium))
                    .foregroundColor(Constants.numberColor)
            }
        }
        .onAppear {
            startCountdownAnimation()
        }
    }
    
    private func startCountdownAnimation() {
        // Reset state
        countdown = 3
        progress = 0
        
        // Animation for each number from 3 to 1
        for i in 0..<3 {
            let numberDuration = Constants.countdownDuration / 3.0
            let startDelay = Double(i) * numberDuration
            
            // Start point for this number
            DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                countdown = 3 - i
                
                // Animate progress for this number
                withAnimation(.linear(duration: numberDuration)) {
                    // Calculate progress values for this segment
                    progress = Double(i + 1) / 3.0
                }
            }
        }
        
        // Complete animation
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.countdownDuration) {
            onComplete()
        }
    }
}

struct CountdownView_Previews: PreviewProvider {
    static var previews: some View {
        CountdownView(onComplete: {})
    }
}
