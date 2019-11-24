//
//  PhotoPathTests.swift
//  PhotoPathTests
//
//  Created by Andreas Hanft on 13.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import XCTest
@testable import PhotoPath

class PhotoPathTests: XCTestCase {

    override func setUp() {
        
    }
    
    override func tearDown() {
        let track = TrackStorage()
        track.reset()
    }

    func testTrackPointIdMatch() {
        let point1 = TrackPoint(latitude: 51.1242, longitude: 13.2131)
        let point2 = TrackPoint(latitude: 51.1242, longitude: 13.2131)
        XCTAssertEqual(point1.id, point2.id)
    }
    
    func testTrackPointIdMissMatch() {
        let point1 = TrackPoint(latitude: 51.1242, longitude: 13.2131)
        let point2 = TrackPoint(latitude: 51.1241, longitude: 13.2131)
        XCTAssertNotEqual(point1.id, point2.id)
    }
    
    func testTrackStorage() {
        let key = "testTrackStorage"
        
        let point1 = TrackPoint(latitude: 51.1242, longitude: 13.2131)
        let point2 = TrackPoint(latitude: 51.1241, longitude: 13.2131)
        
        let track = TrackStorage(storageKey: key)
        track.startNewTrack()
        track.add(point: point1)
        track.add(point: point2)
        
        let current = track.currentTrack
        XCTAssertEqual(current[0].id, point1.id)
        XCTAssertEqual(current[1].id, point2.id)
        
        // Create a second storage with the same key to check the user default storage loading
        let track2 = TrackStorage(storageKey: key)
        
        let current2 = track2.currentTrack
        XCTAssertEqual(current2[0].id, point1.id)
        XCTAssertEqual(current2[1].id, point2.id)
        
        track.reset()
        
        let currentAfterReset = track.currentTrack
        XCTAssertTrue(currentAfterReset.isEmpty)
    }
    
    func testTrackStorageDuplicatesFiltering() {
        let key = "testTrackStorage"
        
        let point1 = TrackPoint(latitude: 51.1242, longitude: 13.2131)
        let point2 = TrackPoint(latitude: 51.1242, longitude: 13.2131)
        
        let track = TrackStorage(storageKey: key)
        track.startNewTrack()
        track.add(point: point1, filterDuplicates: false)
        track.add(point: point2, filterDuplicates: false)
        
        let current = track.currentTrack
        XCTAssertEqual(current.count, 2)
        
        track.reset()
        
        track.startNewTrack()
        track.add(point: point1, filterDuplicates: true)
        track.add(point: point2, filterDuplicates: true)
        
        let current2 = track.currentTrack
        XCTAssertEqual(current2.count, 1)
    }
}
