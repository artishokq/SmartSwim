//
//  InfoViewController.swift
//  Smart Swim
//
//  Created by Artem Tkachuk on 14.01.2025.
//

import UIKit
import YandexMapsMobile

protocol InfoDisplayLogic: AnyObject {
    func displayPools(viewModel: InfoModels.GetPools.ViewModel)
    func displayError(message: String)
}

final class InfoViewController: UIViewController {
    // MARK: - Constants
    private enum Constants {
        static let infoTitle = "Бассейны"
        static let infoTitleFont = UIFont.systemFont(ofSize: 20, weight: .semibold)
        static let infoBackgroundColor = UIColor(hexString: "#242531")
        static let barTextColor = UIColor(hexString: "#FFFFFF") ?? .white
        static let mapZoom: Float = 12.0
        static let pinIconName = "search_layer_pin_selected_default"
    }
    
    // MARK: - Fields
    var interactor: InfoBusinessLogic?
    var router: (NSObjectProtocol & InfoRoutingLogic)?
    
    private let titleLabel: UILabel = UILabel()
    private var mapView: YMKMapView!
    private var userLocationLayer: YMKUserLocationLayer?
    private var poolPlacemarks: [YMKPlacemarkMapObject] = []
    private var searchSession: YMKSearchSession?
    
    // MARK: - Configure
    private func configure() {
        let viewController = self
        let interactor = InfoInteractor()
        let presenter = InfoPresenter()
        let router = InfoRouter()
        
        viewController.interactor = interactor
        viewController.router = router
        interactor.presenter = presenter
        presenter.viewController = viewController
        router.viewController = viewController
    }
    
    // MARK: - Initialization
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        requestPoolsInfo()
        setupNavigationBar()
    }
    
    // MARK: - Configurations
    private func configureUI() {
        view.backgroundColor = Constants.infoBackgroundColor
        titleLabel.textColor = Constants.barTextColor
        titleLabel.textAlignment = .center
        titleLabel.font = Constants.infoTitleFont
        titleLabel.text = Constants.infoTitle
        navigationItem.titleView = titleLabel
        
        configureYandexMap()
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.barTintColor = Constants.infoBackgroundColor
        navigationItem.leftItemsSupplementBackButton = true
        navigationItem.titleView = titleLabel
    }
    
    private func configureYandexMap() {
        mapView = YMKMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)
        
        let mapKit = YMKMapKit.sharedInstance()
        userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)
        userLocationLayer?.setVisibleWithOn(true)
        userLocationLayer?.isHeadingEnabled = true
    }
    
    // MARK: - Actions
    private func requestPoolsInfo() {
        let request = InfoModels.GetPools.Request()
        interactor?.getPools(request: request)
    }
    
    // MARK: - Map Helpers
    private func addPoolsToMap(pools: [InfoModels.GetPools.PoolLocationViewModel], userLocation: (latitude: Double, longitude: Double)) {
        let targetLocation = YMKPoint(latitude: userLocation.latitude, longitude: userLocation.longitude)
        mapView.mapWindow.map.move(
            with: YMKCameraPosition(target: targetLocation, zoom: Constants.mapZoom, azimuth: 0, tilt: 0),
            animation: YMKAnimation(type: YMKAnimationType.smooth, duration: 1),
            cameraCallback: nil)
        
        let poolsMapObjects = mapView.mapWindow.map.mapObjects
        poolPlacemarks.forEach { $0.parent.remove(with: $0) }
        poolPlacemarks.removeAll()
        let pinImage = getPinImage()
        
        for pool in pools {
            let poolLocation = YMKPoint(latitude: pool.coordinate.latitude, longitude: pool.coordinate.longitude)
            
            let placemark = poolsMapObjects.addPlacemark()
            placemark.geometry = poolLocation
            placemark.setIconWith(pinImage)
            poolPlacemarks.append(placemark)
        }
    }
    
    private func getPinImage() -> UIImage {
        if let pinImage = UIImage(named: Constants.pinIconName) {
            return pinImage
        }
        else {
            return UIImage(systemName: "figure.pool.swim")?.withTintColor(.blue, renderingMode: .alwaysOriginal) ?? UIImage()
        }
    }
}

// MARK: - InfoDisplayLogic
extension InfoViewController: InfoDisplayLogic {
    func displayPools(viewModel: InfoModels.GetPools.ViewModel) {
        addPoolsToMap(pools: viewModel.pools, userLocation: viewModel.userLocation)
    }
    
    func displayError(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
