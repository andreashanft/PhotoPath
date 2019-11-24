//
//  FlickrAPI.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 14.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation

enum FlickrAPI {
    
    /// Search for photos with given parameters
    case photoSearch(Request.PhotoSearchParameter)
    
    /// Request raw data of a single image with the info from the photo search
    case image(Request.ImageParameter)

    enum Request {
        enum GeoContext: Int {
            case undefined
            case indoors
            case outdoors
        }
        
        struct PhotoSearchParameter {
            let apiKey: String
            let latitude: Double
            let longitude: Double
            let radius: Double
            let results: Int
            let geoContext: GeoContext

            init(apiKey: String, latitude: Double, longitude: Double, radius: Double, results: Int, geoContext: GeoContext = .undefined) {
                self.apiKey = apiKey
                self.latitude = latitude
                self.longitude = longitude
                self.radius = radius
                self.results = results
                self.geoContext = geoContext
            }
        }
        
        enum ImageSize: String {
            case smallSquare = "s" // klein, quadratisch, 75 x 75
            case largeSquare = "q" // large square 150x150
            case thumb = "t" // Thumbnail, 100 an der Längsseite
            case xxs = "m" // klein, 240 an der Längsseite
            case xs = "n" // small, 320 on longest side
            case s = "-" // mittel, 500 an der Längsseite
            case m = "z" // mittel 640, 640 an der längsten Seite
            case l = "c" // mittel 800, 800 an der längsten Seite†
            case xl = "b" // groß, 1024 an der längsten Seite*
            case xxl = "h" // groß mit 1600 Pixel, 1600 an längster Seite†
            case xxxl = "k" // groß mit 2048 Pixel, 2048 an längster Seite†
            case original = "o" // Originalbild, entweder JPG, GIF oder PNG, je nach Quellformat
        }
        
        // https://farm{farm-id}.staticflickr.com/{server-id}/{id}_{secret}_[mstzb].jpg
        class ImageParameter {
            let farmId: String
            let serverId: String
            let imageId: String
            let secret: String
            let size: ImageSize
            
            init(farmId: String, serverId: String, imageId: String, secret: String, size: FlickrAPI.Request.ImageSize = .xl) {
                self.farmId = farmId
                self.serverId = serverId
                self.imageId = imageId
                self.secret = secret
                self.size = size
            }
        }
    }
    
    enum Response {
        struct Search: Codable {
            let photos: PhotosResult
        }
        
        struct PhotosResult: Codable {
            let photo: [Photo]
        }
        
        struct Photo: Codable {
            let id: String
            let secret: String
            let server: String
            let farm: Int
            let title: String
        }
    }
}

extension FlickrAPI: APIDescription {
    var baseURL: String {
        switch self {
        case .photoSearch:
            return "https://www.flickr.com/services"
        case .image(let request):
            return "https://farm\(request.farmId).staticflickr.com"
        }
    }
    
    var endpoint: String {
        switch self {
        case .photoSearch:
            return "/rest"
        case .image(let request):
            let endpoint = String(format: "/%@/%@_%@_%@.jpg",
                                  request.serverId,
                                  request.imageId,
                                  request.secret,
                                  request.size.rawValue)
            return endpoint
        }
    }
    
    var queryItems: [URLQueryItem]? {
        var items: [URLQueryItem] = []
        
        switch self {
        case .photoSearch(let request):
            items.append(URLQueryItem(name: "method", value: "flickr.photos.search"))
            items.append(URLQueryItem(name: "format", value: "json"))
            items.append(URLQueryItem(name: "nojsoncallback", value: "1"))
            items.append(URLQueryItem(name: "api_key", value: request.apiKey))
            items.append(URLQueryItem(name: "lat", value: String(request.latitude)))
            items.append(URLQueryItem(name: "lon", value: String(request.longitude)))
            items.append(URLQueryItem(name: "radius", value: String(request.radius)))
            items.append(URLQueryItem(name: "per_page", value: String(request.results)))
            items.append(URLQueryItem(name: "geo_context", value: String(request.geoContext.rawValue)))

        default:
            return nil
        }
        
        return items
    }
    
    var method: HTTPMethod {
        .get
    }
}

