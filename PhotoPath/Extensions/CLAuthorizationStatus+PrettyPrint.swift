//
//  CLAuthorizationStatus+PrettyPrint.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 17.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import CoreLocation

extension CLAuthorizationStatus {
    var prettyPrint: String {
        switch self {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        @unknown default:
            return "unknown"
        }
    }
}
