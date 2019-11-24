//
//  DistanceMonitoring.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 17.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import CoreLocation

final class DistanceMonitoring: NSObject, LocationMonitoringServiceType {
    
    fileprivate enum Configuration {
        static let defaultDistance: CLLocationDistance = 100 // m
        static let defaultActivityType: CLActivityType = .fitness // for walking
    }
    
    private var onLocationUpdate: LocationMonitoringUpdate?
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.distanceFilter = Configuration.defaultDistance
        self.locationManager.activityType = Configuration.defaultActivityType
        self.locationManager.pausesLocationUpdatesAutomatically = true
    }
    
    func startMonitoring(onLocationUpdate: LocationMonitoringUpdate?) {
        self.onLocationUpdate?(.failure(.aborted))
        self.onLocationUpdate = nil
        
        guard CLLocationManager.authorizationStatus() == .authorizedAlways else {
            DebugLogger.log("[Error] DistanceMonitoring.startMonitoring failed: not authorized")
            onLocationUpdate?(.failure(.insufficientAuthorisation))
            return
        }
        
        self.onLocationUpdate = onLocationUpdate
        locationManager.startUpdatingLocation()
    }
    
    func stopMonitoring() {
        onLocationUpdate = nil
        locationManager.stopUpdatingLocation()
    }
    
    private func reportLocationUpdate(location: CLLocation) {
        let coords = (location.coordinate.latitude, location.coordinate.longitude)
        onLocationUpdate?(.success(coords))
    }
    
    private func reportLocationFailure(error: Error) {
        onLocationUpdate?(.failure(.locationManagerError(error)))
        onLocationUpdate = nil
        stopMonitoring()
    }
}

extension DistanceMonitoring: CLLocationManagerDelegate {
    
    // MARK: - Location Handling
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        DebugLogger.log("[Info] DistanceMonitoring.didUpdateLocations \(location.coordinate.shortDescription)")
        reportLocationUpdate(location: location)
    }
    
    // MARK: - Error Handling
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DebugLogger.log("[Error] locationManager.didFailWithError \(error)")
        reportLocationFailure(error: error)
    }
}
