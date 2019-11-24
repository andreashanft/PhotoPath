//
//  FlickrLocationImageService.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 14.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import UIKit

final class FlickrLocationImageService: LocationImageServiceType {
    static let defaultFileType = ".jpg"
    
    var onImageDownloaded: ((String) -> Void)?
    
    fileprivate enum Configuration {
        /// Search radius in km (0-32), default 0.5 (500m)
        static let defaultRadius: Double = 0.5
        
        /// Default number of results
        static let defaultResultCount: Int = 10
    }
    
    private let fileManager = FileManager.default
    private let api = APIClient()
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func searchAndFetchImage(for latitude: Double, _ longitude: Double, identifier: String) {
        
        guard !hasImage(for: identifier) else { return }
        
        let search = FlickrAPI.photoSearch(
            .init(apiKey: apiKey,
                  latitude: latitude, longitude: longitude,
                  radius: Configuration.defaultRadius,
                  results: Configuration.defaultResultCount))
        
        api.request(for: search) { [weak self] (result: Result<FlickrAPI.Response.Search, APIError>) in
            guard let self = self else { return }
            
            switch result {
            case .success(let response):
                guard let info = response.photos.photo.randomElement() else {
                    DebugLogger.log("[Warning] Invalid response or no image found...")
                    return
                }
                
                DebugLogger.log("[Info] Found image (\(info.title))")
                
                let image = FlickrAPI.image(
                    .init(farmId: String(info.farm), serverId: info.server, imageId: info.id, secret: info.secret))
                
                self.api.request(for: image) { (result: Result<Data, APIError>) in
                    switch result {
                    case .success(let data):
                        if !self.saveImage(with: data, name: identifier) {
                            DebugLogger.log("[Error] Unable to save image")
                        }
                    case .failure(let error):
                        DebugLogger.log("[Error] Downloading image from Flickr failed: \(error)")
                    }
                }
                
            case .failure(let error):
                DebugLogger.log("[Error] Searching Flickr for images: \(error)")
            }
        }
    }
    
    @discardableResult
    private func saveImage(with data: Data, name: String) -> Bool {
        do {
            if let fileURL = fileURL(for: name) {
                try data.write(to: fileURL)
                onImageDownloaded?(fileURL.path)
                return true
            }
        } catch {
            print(error)
            DebugLogger.log("[Error] Failed writing to disk: \(error)")
        }
        return false
    }
    
    func fileURL(for identifier: String) -> URL? {
        do {
            let documentDirectory = try fileManager.url(
                for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let fileURL = documentDirectory.appendingPathComponent(identifier + FlickrLocationImageService.defaultFileType)

            return fileURL
        } catch {
            print(error)
            DebugLogger.log("[Error] Failed getting file URL: \(error)")
        }
        return nil
    }
    
    private func hasImage(for identifier: String) -> Bool {
        guard let path = fileURL(for: identifier)?.path else { return false }
        
        return fileManager.fileExists(atPath: path)
    }
}
