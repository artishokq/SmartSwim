//
//  LocationWorker.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 02.04.2025.
//

import Foundation
import CoreLocation

enum LocationError: Error {
    case locationServicesDisabled
    case authorizationDenied
    case failedToGetLocation
    
    var localizedDescription: String {
        switch self {
        case .locationServicesDisabled:
            return "Службы геолокации отключены"
        case .authorizationDenied:
            return "Доступ к геолокации запрещен"
        case .failedToGetLocation:
            return "Не удалось получить местоположение"
        }
    }
}

struct Location {
    let latitude: Double
    let longitude: Double
}

protocol LocationWorkerProtocol {
    func getCurrentLocation(completion: @escaping (Result<Location, LocationError>) -> Void)
    func getDefaultLocation() -> Location
}

final class LocationWorker: NSObject {
    private var locationManager: CLLocationManager?
    private var completion: ((Result<Location, LocationError>) -> Void)?
    
    override init() {
        super.init()
        // Инициализируем менеджер локации при создании объекта
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func getCurrentLocation(completion: @escaping (Result<Location, LocationError>) -> Void) {
        self.completion = completion
        // Проверяем статус авторизации напрямую
        checkAuthorizationStatus()
    }
    
    private func checkAuthorizationStatus() {
        guard let locationManager = locationManager else {
            completion?(.failure(.failedToGetLocation))
            return
        }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            // У нас есть разрешение, запрашиваем местоположение
            locationManager.startUpdatingLocation()
            
        case .notDetermined:
            // Запрашиваем разрешение
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            // Пользователь отклонил доступ к геолокации
            completion?(.failure(.authorizationDenied))
            
        @unknown default:
            // Неизвестный статус
            completion?(.failure(.authorizationDenied))
        }
    }
    
    func getDefaultLocation() -> Location {
        return Location(latitude: 55.7558, longitude: 37.6173)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationWorker: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorizationStatus()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            completion?(.failure(.failedToGetLocation))
            return
        }
        
        // Получили местоположение
        let userLocation = Location(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        // Вызываем callback с результатом
        completion?(.success(userLocation))
        
        // Останавливаем обновление и очищаем ресурсы
        manager.stopUpdatingLocation()
        completion = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        completion?(.failure(.failedToGetLocation))
        completion = nil
    }
}
