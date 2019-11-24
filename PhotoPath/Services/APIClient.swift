//
//  APIClient.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 14.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation


enum APIError: Error {
    case networkingError(Error?)
    case parsingError(Error)
    case httpError(HTTPStatusCode)
    case genericError
}

protocol APIClientType: class {
    func request<Payload: Decodable>(
        for service: APIDescription,
        completion: @escaping PayloadCompletion<Payload>)
}

final class APIClient: APIClientType {
    fileprivate enum Configuration {
        static let defaultTimeout: TimeInterval = 30.0 // s
    }
    
    private let backend = URLSessionNetworking()

    /**
     Performs a request using the given API-description and with default timeout
     */
    func request<Payload: Decodable>(
        for service: APIDescription,
        completion: @escaping PayloadCompletion<Payload>) {
        
        request(for: service, timeout: Configuration.defaultTimeout, completion: completion)
    }
    
    private func request<Payload: Decodable>(
        for service: APIDescription,
        timeout: TimeInterval,
        completion: @escaping PayloadCompletion<Payload>) {
        
        request(for: service, timeout: timeout) { (result: Result<NetworkingResponse, APIError>) in
            switch result {
            case .success(let (data, _)):

                if let rawData = data as? Payload {
                    completion(.success(rawData))
                    return
                }
                
                let parsed: Result<Payload, APIError> = data.parseJSON()
                completion(parsed)
                
            case .failure(let error):
                completion(.failure(error))
                return
            }
        }
    }
    
    private func request(
        for service: APIDescription,
        timeout: TimeInterval,
        completion: @escaping NetworkingCompletion) {
        
        backend.requestData(service.url,
                            method: service.method,
                            queryItems: service.queryItems,
                            body: service.body,
                            headers: service.headers,
                            timeout: timeout
        ) { result in
            switch result {
            case .success(let data, let headers):
                let apiResponse = (data: data, headers: headers)
                completion(.success(apiResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
