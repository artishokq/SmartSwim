//
//  AIStartService.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 11.03.2025.
//

import Foundation

enum DeepSeekError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case apiError(String)
    case regionRestricted
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Неверный URL для API"
        case .networkError(let error):
            return "Ошибка сети: \(error.localizedDescription)"
        case .invalidResponse:
            return "Получен некорректный ответ от API"
        case .apiError(let message):
            return "Ошибка API: \(message)"
        case .regionRestricted:
            return "API недоступно в вашем регионе"
        }
    }
}

class AIStartService {
    // MARK: - Singleton
    static let shared = AIStartService()
    
    // MARK: - Properties
    private let apiKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String, !key.isEmpty {
            return key
        }
        print("API_KEY не задан в Info.plist.")
        return ""
    }()
    
    private let endpoint = "https://api.deepseek.com/v1/chat/completions"
    private let model = "deepseek-reasoner" // Модель DeepSeek
    
    // MARK: - Инициализация
    private init() {}
    
    // MARK: - Public Methods
    func generateRecommendation(
        for start: StartEntity,
        completion: @escaping (Result<String, DeepSeekError>) -> Void
    ) {
        // Подготовка данных о старте для запроса к API
        guard let lapEntities = start.laps?.allObjects as? [LapEntity], !lapEntities.isEmpty else {
            completion(.failure(.invalidResponse))
            return
        }
        
        // Сортируем отрезки по номеру
        let sortedLaps = lapEntities.sorted { $0.lapNumber < $1.lapNumber }
        
        // Формируем информацию о старте и отрезках
        let prompt = generatePrompt(for: start, with: sortedLaps)
        
        // Отправляем запрос к API
        sendDeepSeekRequest(with: prompt, completion: completion)
    }
    
    // MARK: - Private Methods
    private func generatePrompt(for start: StartEntity, with laps: [LapEntity]) -> String {
        let styleDescription = getSwimStyleDescription(start.swimmingStyle)
        // Формируем промпт
        var prompt = """
        Проанализируй данные о заплыве пловца и дай конкретные рекомендации по улучшению результатов.
        
        Данные о заплыве:
        - Дистанция: \(start.totalMeters) метров
        - Стиль: \(styleDescription)
        - Размер бассейна: \(start.poolSize) метров
        - Общее время: \(formatTime(start.totalTime)) (формат: мм;сс,мс)
        
        Данные по отрезкам:
        """
        
        // Добавляем информацию по каждому отрезку
        for lap in laps {
            prompt += """
            
            Отрезок \(lap.lapNumber):
            - Время: \(formatTime(lap.lapTime)) (формат: мм;сс,мс)
            - Пульс: \(lap.pulse) уд/мин
            - Количество гребков: \(lap.strokes)
            """
        }
        
        // Добавляем дополнительные инструкции для анализа
        prompt += """
        
        Если значения пульса или количества гребков равны 0 или отсутствуют, игнорируй их и анализируй данные, исходя только из общего времени и времени отрезков.
        
        Проведи детальный анализ данных: объясни, почему распределение усилий, управление пульсом и техника плавания таковы, как есть, и укажи на возможные улучшения. Дай конкретные рекомендации по тренировочным упражнениям для повышения результата.
        
        Обрати внимание: используй формат времени мм;сс,мс для всех временных данных, не используй LaTeX или символы "*" в выводе или жирный шрифт, не используй увеличенный шрифт, пиши всё одним шрифтом, одного размера.
        
        Не забудь похвалить пловца за достигнутый результат, добавить мотивационные комментарии и дать рекомендации, объясняя что и почему можно улучшить.
        
        Ответ сформулируй в двух частях: первый – анализ текущего заплыва с объяснениями, второй – конкретные рекомендации по тренировкам и мотивация. По возможности нумеруй пункты. При выводе не используй жирный шрифт, не используй увеличенный шрифт, пиши всё одним шрифтом, одного размера.
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
                ["role": "system", "content": "Ты - профессиональный тренер по плаванию, который анализирует результаты заплывов и дает точные, конкретные рекомендации."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
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
                    // Удаляем все символы "*" из ответа перед отправкой
                    let cleanedContent = content.replacingOccurrences(of: "*", with: "")
                    
                    completion(.success(cleanedContent))
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
    private func getSwimStyleDescription(_ styleRawValue: Int16) -> String {
        let style = SwimStyle(rawValue: styleRawValue) ?? .freestyle
        switch style {
        case .freestyle: return "Вольный стиль"
        case .breaststroke: return "Брасс"
        case .backstroke: return "На спине"
        case .butterfly: return "Баттерфляй"
        case .medley: return "Комплекс"
        case .any: return "Вольный стиль"
        }
    }
    
    private func formatTime(_ totalSeconds: Double) -> String {
        let minutes = Int(totalSeconds) / 60
        let seconds = Int(totalSeconds) % 60
        let milliseconds = Int((totalSeconds.truncatingRemainder(dividingBy: 1)) * 100)
        
        return String(format: "%02d:%02d,%02d", minutes, seconds, milliseconds)
    }
}
