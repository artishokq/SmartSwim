//
//  ContentView.swift
//  SSwim Watch App
//
//  Created by Artem Tkachuk on 19.02.2025.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @ObservedObject private var healthManager = HealthManager.shared
    @ObservedObject private var sessionManager = WatchSessionManagerObservable.shared
    @State private var isTracking = false
    @State private var currentPulse: Int = 0
    @State private var strokeCount: Int = 0
    
    var body: some View {
        VStack {
            Text("Smart Swim")
                .font(.headline)
            
            Spacer()
            
            if isTracking {
                Text("Отслеживание активно")
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Пульс: \(currentPulse) уд/мин")
                    }
                    
                    HStack {
                        Image(systemName: "figure.pool.swim")
                            .foregroundColor(.blue)
                        Text("Гребки: \(strokeCount)")
                    }
                }
                .padding()
                .background(Color.black.opacity(0.2))
                .cornerRadius(10)
                
                Spacer()
                
                Button(action: {
                    stopTracking()
                }) {
                    Text("Остановить")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            } else {
                Text("Начните отслеживание для синхронизации с телефоном")
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
                
                Button(action: {
                    startTracking()
                }) {
                    Text("Начать отслеживание")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .onReceive(healthManager.$heartRate) { newHeartRate in
            if isTracking {
                currentPulse = Int(newHeartRate)
                sessionManager.sendHeartRateToPhone(heartRate: currentPulse)
            }
        }
        .onReceive(healthManager.$strokeCount) { newStrokeCount in
            if isTracking {
                strokeCount = newStrokeCount
                sessionManager.sendStrokeCountToPhone(strokeCount: strokeCount)
            }
        }
        .onReceive(sessionManager.$commandFromPhone) { command in
            if command == "start" {
                startTracking()
            } else if command == "stop" {
                stopTracking()
            }
        }
        .onAppear {
            WatchSessionManagerObservable.shared.startSession()
            HealthManager.shared.requestAuthorization()
        }
    }
    
    private func startTracking() {
        isTracking = true
        healthManager.startHeartRateMonitoring()
        healthManager.startStrokeCountMonitoring()
        WatchSessionManagerObservable.shared.sendMessageToPhone(message: ["watchStatus": "started"])
    }
    
    private func stopTracking() {
        isTracking = false
        healthManager.stopMonitoring()
        WatchSessionManagerObservable.shared.sendMessageToPhone(message: ["watchStatus": "stopped"])
        
        // Reset counters
        currentPulse = 0
        strokeCount = 0
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
