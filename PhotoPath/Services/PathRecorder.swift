//
//  PathRecorder.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 18.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import CoreLocation

enum PathRecorderError: Error {
    case aborted
    case noAuthorisation
}

enum LocationError: Error {
    case aborted
    case insufficientAuthorisation
    case unavailable
    case permissionDenied
    case locationManagerError(Error)
}
typealias LocationMonitoringUpdate = (Result<(latidude: Double, longitude: Double), LocationError>) -> Void

protocol LocationMonitoringServiceType {
    func startMonitoring(onLocationUpdate: LocationMonitoringUpdate?)
    func stopMonitoring()
}

protocol TrackStorageServiceType {
    func startNewTrack()
    func add(point: TrackPoint, filterDuplicates: Bool)
    func reset()
    
    var currentTrack: [TrackPoint] { get }

    var onTrackPointAdded: ((TrackPoint) -> Void)? { get set }
}

protocol LocationImageServiceType {
    func searchAndFetchImage(for latitude: Double, _ longitude: Double, identifier: String)
    func fileURL(for identifier: String) -> URL?
    var onImageDownloaded: ((String) -> Void)? { get set }
}

protocol GPX {
    var gpx: String { get }
}

typealias PathRecorderUpdate = (Result<[TrackPoint], Error>) -> Void

final class PathRecorder {

    var isRecording: Bool {
        AppState.isMonitoringActive
    }
    
    private let locationAuthorisation = LocationServiceAuthorisation()
    private var locationMonitoring: LocationMonitoringServiceType
    private var trackStorage: TrackStorageServiceType
    private var imageService: LocationImageServiceType
    private var onUpdate: PathRecorderUpdate?
    
    init(locationMonitoring: LocationMonitoringServiceType,
         trackStorage: TrackStorageServiceType,
         imageService: LocationImageServiceType) {
        self.locationMonitoring = locationMonitoring
        self.trackStorage = trackStorage
        self.imageService = imageService
        
        self.trackStorage.onTrackPointAdded = { [unowned self] trackPoint in
            self.imageService.searchAndFetchImage(for: trackPoint.latitude, trackPoint.longitude, identifier: trackPoint.id)
            self.notifyObserver()
        }
        
        self.imageService.onImageDownloaded = { path in
            print("Downloaded: \(path)")
            self.notifyObserver()
        }
    }
    
    func startRecording(onUpdate: PathRecorderUpdate?) {
        self.onUpdate?(.failure(PathRecorderError.aborted))
        self.onUpdate = nil
        
        let requiredAuthorisationStatus = CLAuthorizationStatus.authorizedAlways
        locationAuthorisation.requestAuthorisation(for: requiredAuthorisationStatus) { [weak self] result in
            switch result {
            case .success(let status):
                guard status == requiredAuthorisationStatus else {
                    onUpdate?(.failure(PathRecorderError.noAuthorisation))
                    return
                }
                self?.setupAndStartRecording(onUpdate: onUpdate)
                
            case .failure(let error):
                onUpdate?(.failure(error))
            }
        }
    }
    
    func stopRecording() {
        onUpdate = nil
        locationMonitoring.stopMonitoring()
        AppState.isMonitoringActive = false
    }
    
    func fileURL(for identifier: String) -> URL? {
        return imageService.fileURL(for: identifier)
    }
    
    private func setupAndStartRecording(onUpdate: PathRecorderUpdate?) {
        self.onUpdate = onUpdate
        AppState.isMonitoringActive = true
        trackStorage.startNewTrack()
        locationMonitoring.startMonitoring(onLocationUpdate: { [unowned self] result in
            switch result {
            case .success(let location):
                let point = TrackPoint(latitude: location.latidude, longitude: location.longitude)
                self.trackStorage.add(point: point, filterDuplicates: true)
            case .failure(let error):
                self.reportError(error)
            }
        })
    }
    
    private func reportError(_ error: Error) {
        onUpdate?(.failure(error))
        onUpdate = nil
        AppState.isMonitoringActive = false
    }
    
    private func notifyObserver() {
        let path = trackStorage.currentTrack
        onUpdate?(.success(path))
    }
}

extension PathRecorder: GPX {
    
    var gpx: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                
        var gpx = """
<?xml version="1.0"?>
<gpx version="1.1" creator="Xcode">

"""
        trackStorage.currentTrack.forEach({
            gpx += String(format: "<wpt lat=\"%f\" lon=\"%f\"><time>%@</time></wpt>\n",
                          $0.latitude, $0.longitude, dateFormatter.string(from: $0.time))
        })
        
        gpx += "</gpx>\n"
        
        return gpx
    }
}
