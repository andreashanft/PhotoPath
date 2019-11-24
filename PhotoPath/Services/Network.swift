//
//  Network.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 13.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

enum HTTPStatusCode: Int {
    // 100 Informational
    case `continue` = 100
    case switchingProtocols
    case processing
    // 200 Success
    case ok = 200
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent
    case multiStatus
    case alreadyReported
    case iMUsed = 226
    // 300 Redirection
    case multipleChoices = 300
    case movedPermanently
    case found
    case seeOther
    case notModified
    case useProxy
    case switchProxy
    case temporaryRedirect
    case permanentRedirect
    // 400 Client Error
    case badRequest = 400
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case proxyAuthenticationRequired
    case requestTimeout
    case conflict
    case gone
    case lengthRequired
    case preconditionFailed
    case payloadTooLarge
    case uriTooLong
    case unsupportedMediaType
    case rangeNotSatisfiable
    case expectationFailed
    case imATeapot
    case misdirectedRequest = 421
    case unprocessableEntity
    case locked
    case failedDependency
    case upgradeRequired = 426
    case preconditionRequired = 428
    case tooManyRequests
    case requestHeaderFieldsTooLarge = 431
    case unavailableForLegalReasons = 451
    // 500 Server Error
    case internalServerError = 500
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    case variantAlsoNegotiates
    case insufficientStorage
    case loopDetected
    case notExtended = 510
    case networkAuthenticationRequired
}

typealias NetworkingResponse = (data: Data, headers: [String: String])
typealias NetworkingCompletion = (_ result: Result<NetworkingResponse, APIError>) -> Void
typealias PayloadCompletion<Payload> = (_ result: Result<Payload, APIError>) -> Void

protocol Networking {
    func requestData(_ url: URL,
                     method: HTTPMethod,
                     queryItems: [URLQueryItem]?,
                     body: Data?,
                     headers: [String: String],
                     timeout: TimeInterval,
                     completion: @escaping NetworkingCompletion)
}

final class URLSessionNetworking: NSObject, Networking {
    
    private var session: URLSession = URLSession(configuration: URLSessionConfiguration.default)

    static func urlRequest(withURL url: URL,
                           method: HTTPMethod,
                           queryItems: [URLQueryItem]?,
                           body: Data?,
                           headers: [String: String],
                           timeout: TimeInterval) -> URLRequest {
        
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        urlComponents.queryItems = queryItems
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = method.rawValue
        request.httpBody = body
        request.allHTTPHeaderFields = headers
        request.timeoutInterval = timeout
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        return request
    }

    func requestData(_ url: URL,
                     method: HTTPMethod,
                     queryItems: [URLQueryItem]?,
                     body: Data?,
                     headers: [String: String],
                     timeout: TimeInterval,
                     completion: @escaping NetworkingCompletion) {

        let request = URLSessionNetworking.urlRequest(withURL: url,
                                                      method: method,
                                                      queryItems: queryItems,
                                                      body: body,
                                                      headers: headers,
                                                      timeout: timeout)
        let task = session.dataTask(with: request) { data, response, sessionError in
            DispatchQueue.main.async {
                if let data = data, let response = response as? HTTPURLResponse, sessionError == nil {
                    guard (HTTPStatusCode.ok.rawValue ..< HTTPStatusCode.multipleChoices.rawValue) ~= response.statusCode else {
                        let error: APIError
                        if let code = HTTPStatusCode.init(rawValue: response.statusCode) {
                            error = .httpError(code)
                        } else {
                            error = .genericError
                        }
                        completion(.failure(error))
                        return
                    }
                    let headers = response.allHeaderFields as? [String: String] ?? [:]
                    completion(.success((data: data, headers: headers)))
                } else {
                    completion(.failure(.networkingError(sessionError)))
                }
            }
        }

        task.resume()
    }
}
