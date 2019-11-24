//
//  BoundaryMonitoring.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 13.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import CoreLocation

struct Boundary {
    let identifier: String
    let center: CLLocationCoordinate2D
    let radius: CLLocationDistance
    
    init(identifier: String, center: CLLocationCoordinate2D,
         radius: CLLocationDistance = BoundaryMonitoring.Configuration.defaultRadius) {
        self.identifier = identifier
        self.center = center
        self.radius = radius
    }
    
    fileprivate func makeMonitoringRegion() -> CLCircularRegion {
        let region = CLCircularRegion(center: center, radius: radius, identifier: identifier)
        region.notifyOnEntry = false
        region.notifyOnExit = true
        
        return region
    }
}

final class BoundaryMonitoring: NSObject, LocationMonitoringServiceType {
    
    fileprivate enum Configuration {
        static let defaultRadius: CLLocationDistance = 80 // m
    }
    
    private var onLocationUpdate: LocationMonitoringUpdate?
    private let locationManager = CLLocationManager()
    private let regionIdentifier: String
    
    init(regionIdentifier: String = "RegionMonitoring.defaultIdentifier") {
        self.regionIdentifier = regionIdentifier
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        self.locationManager.allowsBackgroundLocationUpdates = true
    }
    
    func startMonitoring(onLocationUpdate: LocationMonitoringUpdate?) {
        self.onLocationUpdate?(.failure(.aborted))
        self.onLocationUpdate = nil
        
        guard CLLocationManager.authorizationStatus() == .authorizedAlways else {
            DebugLogger.log("[Error] BoundaryMonitoring.startMonitoring failed: not authorized")
            onLocationUpdate?(.failure(.insufficientAuthorisation))
            return
        }
        
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            DebugLogger.log("[Error] BoundaryMonitoring.startMonitoring failed: not supported")
            onLocationUpdate?(.failure(.unavailable))
            return
        }
        
        self.onLocationUpdate = onLocationUpdate
        locationManager.requestLocation()
    }
    
    func stopMonitoring() {
        stopMonitoring(for: regionIdentifier)
    }

    private func reportLocationUpdate(location: CLLocation) {
        let coords = (location.coordinate.latitude, location.coordinate.longitude)
        onLocationUpdate?(.success(coords))
    }
    
    private func reportLocationFailure(error: LocationError) {
        onLocationUpdate?(.failure(error))
        onLocationUpdate = nil
        stopMonitoring()
    }
    
    private func createBoundary(at location: CLLocation) {
        let boundary = Boundary(identifier: regionIdentifier, center: location.coordinate)
        locationManager.startMonitoring(for: boundary.makeMonitoringRegion())
        
        DebugLogger.log("[Info] BoundaryMonitoring.startMonitoring \(regionIdentifier) center: \(location.coordinate.shortDescription)")
    }
    
    
    private func stopMonitoring(for identifier: String) {
        let regions = locationManager.monitoredRegions
            .compactMap({ $0 as? CLCircularRegion})
            .filter({ $0.identifier == identifier})
        
        regions.forEach({ locationManager.stopMonitoring(for: $0) })
        
        DebugLogger.log("[Info] BoundaryMonitoring.stopMonitoring \(identifier) (#\(regions.count))")
    }
    
    private func handleRegionExit(_ region: CLRegion) {
        guard let boundary = region as? CLCircularRegion, boundary.identifier == regionIdentifier else { return }
        guard let location = locationManager.location else { return }
        
        stopMonitoring(for: regionIdentifier)
        DebugLogger.log("[Info] BoundaryMonitoring.handleRegionExit \(location.coordinate.shortDescription)")
        reportLocationUpdate(location: location)
        createBoundary(at: location)
    }
}

extension BoundaryMonitoring: CLLocationManagerDelegate {
    
    // MARK: - Region Handling
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DebugLogger.log("[Info] BoundaryMonitoring.didExitRegion \(region)")
        
        guard region is CLCircularRegion else { return }
        
        handleRegionExit(region)
    }
    
    // MARK: - Location Handling
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        reportLocationUpdate(location: location)
        createBoundary(at: location)
    }
    
    // MARK: - Error Handling
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DebugLogger.log("[Error] locationManager.didFailWithError \(error)")
        reportLocationFailure(error: .locationManagerError(error))
    }
}
