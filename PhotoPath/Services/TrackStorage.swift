//
//  TrackStorage.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 14.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation

struct TrackPoint: Codable {
    let time: Date
    let id: String
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        
        self.time = Date()
        self.id = (String(latitude) + String(longitude)).md5
    }
}

final class TrackStorage: TrackStorageServiceType, PreferencesLoader {
    let key: String
    
    var onTrackPointAdded: ((TrackPoint) -> Void)?
    
    private(set) var tracks: [[TrackPoint]] = [] {
        didSet {
            save(value: tracks)
        }
    }
    
    var currentTrack: [TrackPoint] {
        return tracks.last ?? []
    }
    
    init(storageKey: String = "TrackStorage.tracks") {
        self.key = storageKey
        if let tracks: [[TrackPoint]] = loadValue() {
            self.tracks = tracks
        }
    }
    
    func startNewTrack() {
        tracks.append([])
    }
    
    func add(point: TrackPoint, filterDuplicates: Bool = true) {
        guard !tracks.isEmpty else {
            assertionFailure("No track to add points! Did you call 'startNewTrack()'?")
            return
        }
        
        if filterDuplicates, let lastPoint = tracks.last?.last, lastPoint.id == point.id {
            return
        }
        
        tracks[tracks.count - 1].append(point)
        onTrackPointAdded?(point)
    }
    
    func reset() {
        tracks = []
    }
}
