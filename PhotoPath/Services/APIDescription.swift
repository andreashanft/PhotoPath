//
//  APIDescription.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 14.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation

// `APIDescription` describes an API endpoint
protocol APIDescription {
    
    /// The endpoint base `URL`.
    var baseURL: String { get }
    
    /// The path to be appended to `baseURL` to form the full `URL`.
    var endpoint: String { get }
    
    /// The HTTP method used in the request.
    var method: HTTPMethod { get }
    
    /// The query parameters used in the request.
    var queryItems: [URLQueryItem]? { get }
        
    /// The HTTP body to be used in the request. By default returns nil
    var body: Data? { get }
    
    /// The headers to be used in the request. By default returns empty dict
    var headers: [String: String] { get }
    
    /// The full URL for the endpoint. By default the `endpoint` is appended to the `baseURL`.
    var url: URL { get }
}

extension APIDescription {
    var url: URL {
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid URL")
        }
        return url.appendingPathComponent(endpoint)
    }
    
    var body: Data? {
        return nil
    }
    
    var headers: [String: String] {
        [String: String]()
    }
}
