//
//  AppDelegate.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 13.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import UIKit
import CoreLocation

enum AppState {
    @UserDefault("AppState.isMonitoringActive", defaultValue: false)
    static var isMonitoringActive: Bool
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    lazy var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    
    fileprivate let pathRecorder = PathRecorder(
        
        // Uncomment to toggle between Distance and Boundary monitoring method
//        locationMonitoring: DistanceMonitoring(),
        locationMonitoring: BoundaryMonitoring(),
        
        trackStorage: TrackStorage(),
        imageService: FlickrLocationImageService(apiKey: Configuration.Flickr.apiKey))

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        guard !Configuration.Flickr.apiKey.isEmpty else {
            fatalError("A Flickr API Key is required. Please set your key in 'Configuration.swift'")
        }
        
        guard let window = window, let viewController = MainViewController.makeFromStoryboard() else {
            return false
        }
        
        viewController.viewModel = MainViewModel(pathRecorder: pathRecorder)
        
        window.rootViewController = UINavigationController(rootViewController: viewController)
        window.makeKeyAndVisible()
        
        return true
    }
}
