//
//  LocationServiceAuthorisation.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 18.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import CoreLocation

protocol LocationServiceStatus {
    var isLocationServicesEnabled: Bool { get }
}

extension LocationServiceStatus {
    
    /// Returns if location services are enabled and available (= user has given permission)
    var isLocationServicesEnabled: Bool {
        guard CLLocationManager.locationServicesEnabled() else {
            return false
        }
        
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse, .authorizedAlways:
            return true
        default:
            return false
        }
    }
}

typealias LocationAuthorisationCompletion = (Result<CLAuthorizationStatus, LocationError>) -> Void

final class LocationServiceAuthorisation: NSObject, LocationServiceStatus {
    
    private let locationManager = CLLocationManager()
    private var requestAuthorisationCompletion: LocationAuthorisationCompletion?

    override init() {
        super.init()
        
        self.locationManager.delegate = self
    }
    
    func requestAuthorisation(for status: CLAuthorizationStatus = .authorizedAlways,
                              completion: LocationAuthorisationCompletion? = nil) {
        
        // In case a previous request is still running
        requestAuthorisationCompletion?(.failure(.aborted))
        requestAuthorisationCompletion = nil
        
        let currentStatus = CLLocationManager.authorizationStatus()
        guard currentStatus != status, currentStatus != .authorizedAlways else {
            completion?(.success(currentStatus))
            return
        }
        
        switch currentStatus {
            
        case .notDetermined:
            requestAuthorisationCompletion = completion
            if status == .authorizedAlways {
                locationManager.requestAlwaysAuthorization()
            } else if status == .authorizedWhenInUse {
                locationManager.requestWhenInUseAuthorization()
            }
            
        case .authorizedWhenInUse:
            requestAuthorisationCompletion = completion
            locationManager.requestAlwaysAuthorization()
            
        case .denied:
            completion?(.failure(.permissionDenied))

        default:
            completion?(.failure(.unavailable))
        }
    }
}


extension LocationServiceAuthorisation: CLLocationManagerDelegate {
   
    // MARK: - State Handling
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        DebugLogger.log("[Info] LocationServiceAuthorisation:didChangeAuthorization \(status.prettyPrint)")
            
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            requestAuthorisationCompletion?(.success(status))
            
        default:
            requestAuthorisationCompletion?(.failure(.permissionDenied))
        }
        
        requestAuthorisationCompletion = nil
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        requestAuthorisationCompletion?(.failure(.locationManagerError(error)))
        requestAuthorisationCompletion = nil
    }
}
