//
//  AIWorkoutService.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 30.03.2025.
//

import Foundation

class AIWorkoutService {
    // MARK: - Singleton
    static let shared = AIWorkoutService()
    
    // MARK: - Properties
    private let apiKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String, !key.isEmpty {
            return key
        }
        print("API_KEY не задан")
        return ""
    }()
    
    private let endpoint = "https://api.deepseek.com/v1/chat/completions"
    private let model = "deepseek-reasoner" // Модель DeepSeek
    
    // MARK: - Инициализация
    private init() {}
    
    // MARK: - Public Methods
    func generateRecommendation(
        for workoutSession: WorkoutSessionEntity,
        completion: @escaping (Result<String, DeepSeekError>) -> Void
    ) {
        // Получаем упражнения для сессии
        guard let exercises = workoutSession.exerciseSessions?.allObjects as? [ExerciseSessionEntity], !exercises.isEmpty else {
            completion(.failure(.invalidResponse))
            return
        }
        
        // Сортируем упражнения по порядковому номеру
        let sortedExercises = exercises.sorted { $0.orderIndex < $1.orderIndex }
        
        // Формируем информацию о тренировке
        let prompt = generatePrompt(for: workoutSession, with: sortedExercises)
        
        // Отправляем запрос к API
        sendDeepSeekRequest(with: prompt, completion: completion)
    }
    
    // MARK: - Private Methods
    private func generatePrompt(for workoutSession: WorkoutSessionEntity, with exercises: [ExerciseSessionEntity]) -> String {
        // Формируем промпт
        var prompt = """
        Проанализируй данные о тренировке пловца и дай конкретные рекомендации по улучшению тренировочного процесса.
        
        Данные о тренировке:
        - Дата: \(formatDate(workoutSession.date ?? Date()))
        - Общее время: \(formatTime(workoutSession.totalTime))
        - Общая дистанция: \(calculateTotalMeters(from: exercises)) м
        - Размер бассейна: \(workoutSession.poolSize) м
        - Средний пульс: \(Int(calculateAverageHeartRate(from: exercises))) уд/мин
        - Сожжено калорий: \(Int(workoutSession.totalCalories)) ккал
        - Название тренировки: \(workoutSession.workoutName ?? "Тренировка")
        
        Упражнения:
        """
        
        // Добавляем информацию по каждому упражнению
        for (index, exercise) in exercises.enumerated() {
            let lapEntities = getLaps(for: exercise)
            
            prompt += """
            
            Упражнение \(index + 1):
            - Тип: \(getExerciseTypeDescription(exercise.type))
            - Стиль: \(getSwimStyleDescription(exercise.style))
            - Дистанция: \(exercise.meters * exercise.repetitions) м (\(exercise.repetitions)x\(exercise.meters)м)
            """
            
            if exercise.hasInterval {
                prompt += "\n- Режим отдыха: \(exercise.intervalMinutes):\(String(format: "%02d", exercise.intervalSeconds))"
            }
            
            // Если у упражнения есть отрезки, добавляем информацию о них
            if !lapEntities.isEmpty {
                let avgHeartRate = calculateAverageHeartRate(from: lapEntities)
                let totalStrokes = calculateTotalStrokes(from: lapEntities)
                
                prompt += """
                
                - Средний пульс: \(Int(avgHeartRate)) уд/мин
                - Всего гребков: \(totalStrokes)
                """
            }
        }
        
        // Добавляем дополнительные инструкции для анализа
        prompt += """
        
        Проведи детальный анализ тренировки: оцени распределение нагрузки, интенсивность по пульсу, соотношение разминки/основной части/заминки, и укажи на возможные улучшения. Дай конкретные рекомендации по структуре тренировки, интенсивности и типам упражнений для повышения эффективности.
        
        Обрати внимание: не используй LaTeX или символы "*" в выводе или жирный шрифт, не используй увеличенный шрифт, пиши всё одним шрифтом, одного размера, не пиши явно "Параграф 1" и "Параграф 2".
        
        Не забудь похвалить пловца за проделанную работу, добавить мотивационные комментарии и дать рекомендации по дальнейшему совершенствованию техники и физической подготовки.
        
        Ответ сформулируй в двух частях: первый – анализ тренировки с объяснениями, второй – конкретные рекомендации по улучшению тренировочного процесса и мотивация. По возможности нумеруй пункты. При выводе не используй жирный шрифт, не используй увеличенный шрифт, пиши всё одним шрифтом, одного размера.
        Максимум 300 слов.
        """
        
        return prompt
    }
    
    private func sendDeepSeekRequest(
        with prompt: String,
        completion: @escaping (Result<String, DeepSeekError>) -> Void
    ) {
        // Подготовка URL и запроса
        guard let url = URL(string: endpoint) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Создание тела запроса для DeepSeek API
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "Ты - профессиональный тренер по плаванию, который анализирует тренировки и дает точные, конкретные рекомендации."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 600
        ]
        
        // Преобразование тела запроса в JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(.failure(.invalidResponse))
            return
        }
        
        // Настройка запроса
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        // Выполнение запроса
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Обработка ошибок сети
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            // Проверка HTTP статуса
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    // Получаем информацию об ошибке из ответа, если возможно
                    if let data = data, let jsonError = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let errorInfo = jsonError["error"] as? [String: Any],
                       let message = errorInfo["message"] as? String {
                        completion(.failure(.apiError(message)))
                    } else {
                        completion(.failure(.apiError("HTTP Error: \(httpResponse.statusCode)")))
                    }
                    return
                }
            }
            
            // Проверка данных ответа
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            // Для отладки: вывести JSON-ответ
            if let jsonString = String(data: data, encoding: .utf8) {
                print("DeepSeek API Response: \(jsonString)")
            }
            
            // Обработка JSON-ответа
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    // Возвращаем только текст ответа
                    completion(.success(content))
                } else {
                    // Если не удалось распарсить ответ по ожидаемой структуре
                    if let jsonString = String(data: data, encoding: .utf8) {
                        completion(.failure(.apiError("Unexpected response format: \(jsonString)")))
                    } else {
                        completion(.failure(.invalidResponse))
                    }
                }
            } catch {
                completion(.failure(.networkError(error)))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        return dateFormatter.string(from: date)
    }
    
    private func formatTime(_ totalSeconds: Double) -> String {
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let seconds = Int(totalSeconds) % 60
        
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func getSwimStyleDescription(_ styleRawValue: Int16) -> String {
        let style = SwimStyle(rawValue: styleRawValue) ?? .freestyle
        switch style {
        case .freestyle: return "Вольный стиль"
        case .breaststroke: return "Брасс"
        case .backstroke: return "На спине"
        case .butterfly: return "Баттерфляй"
        case .medley: return "Комплекс"
        case .any: return "Любой стиль"
        }
    }
    
    private func getExerciseTypeDescription(_ typeRawValue: Int16) -> String {
        let type = ExerciseType(rawValue: typeRawValue) ?? .main
        switch type {
        case .warmup: return "Разминка"
        case .main: return "Основное"
        case .cooldown: return "Заминка"
        }
    }
    
    private func calculateTotalMeters(from exercises: [ExerciseSessionEntity]) -> Int16 {
        return exercises.reduce(0) { sum, exercise in
            return sum + exercise.meters * exercise.repetitions
        }
    }
    
    private func calculateAverageHeartRate(from exercises: [ExerciseSessionEntity]) -> Double {
        var totalHeartRate: Double = 0
        var lapCount = 0
        
        for exercise in exercises {
            let laps = getLaps(for: exercise)
            if !laps.isEmpty {
                totalHeartRate += laps.reduce(0) { $0 + $1.heartRate }
                lapCount += laps.count
            }
        }
        
        return lapCount > 0 ? totalHeartRate / Double(lapCount) : 0
    }
    
    private func calculateAverageHeartRate(from laps: [LapSessionEntity]) -> Double {
        guard !laps.isEmpty else { return 0 }
        return laps.reduce(0) { $0 + $1.heartRate } / Double(laps.count)
    }
    
    private func calculateTotalStrokes(from laps: [LapSessionEntity]) -> Int {
        return laps.reduce(0) { $0 + Int($1.strokes) }
    }
    
    private func getLaps(for exercise: ExerciseSessionEntity) -> [LapSessionEntity] {
        return (exercise.laps?.allObjects as? [LapSessionEntity])?.sorted(by: { $0.lapNumber < $1.lapNumber }) ?? []
    }
}
