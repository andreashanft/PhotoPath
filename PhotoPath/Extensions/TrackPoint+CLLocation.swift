//
//  TrackPoint+CLLocation.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 14.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import CoreLocation

extension TrackPoint {
    static func makePoint(with coordinate: CLLocationCoordinate2D) -> Self {
        return .init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
