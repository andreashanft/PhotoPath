//
//  CLLocationCoordinate2D+Debug.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 17.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    var shortDescription: String {
        return String(format: "[lat: %.3f lon: %.3f]", latitude, longitude)
    }
}
