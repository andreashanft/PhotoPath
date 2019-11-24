//
//  MainViewModel.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 13.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

struct TrackPointPresentation {
    let photoPath: String?
    let time: Date

    init(photoPath: String?, time: Date) {
        self.photoPath = photoPath
        self.time = time
    }
}

final class MainViewModel {
    public var onDataChanged: (([TrackPointPresentation]) -> Void)?
    public var onError: (() -> Void)?

    let pathRecorder: PathRecorder
    
    private var trackPresentation: [TrackPointPresentation] = [] {
        didSet {
            onDataChanged?(trackPresentation)
        }
    }

    init(pathRecorder: PathRecorder) {
        self.pathRecorder = pathRecorder
    }
    
    var isMonitoringActive: Bool {
        pathRecorder.isRecording
    }
    
    var numberOfItems: Int {
        trackPresentation.count
    }
    
    func item(for index: Int) -> TrackPointPresentation? {
        guard index < trackPresentation.count else { return nil }
        return trackPresentation[index]
    }
    
    func onStartButtonTapped() {
        DebugLogger.log("[EVENT] Starting track")
        pathRecorder.startRecording { [unowned self] result in
            switch result {
            case .success(let path):
                self.pathDidChange(newPath: path)
            case .failure(let error):
                DebugLogger.log("[Error] Location monitoring failed with error:\n\(error)")
                self.onError?()
            }
        }
    }
    
    func onStopButtonTapped() {
        DebugLogger.log("[EVENT] Stopped track")
        pathRecorder.stopRecording()
    }
    
    func onCopyTrackButtonTapped() {
        UIPasteboard.general.string = pathRecorder.gpx
        DebugLogger.log("[Info] Track copied to clipboard")
    }
    
    private func pathDidChange(newPath: [TrackPoint]) {
        let presentation = newPath
            .map({ TrackPointPresentation(photoPath: self.pathRecorder.fileURL(for: $0.id)?.path, time: $0.time) })
            .sorted(by: { $0.time > $1.time })
        trackPresentation = presentation
    }
}
