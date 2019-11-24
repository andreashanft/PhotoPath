//
//  Data+JSON.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 14.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation

private let defaultDecoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
    return decoder
}()

extension Data {
    func parseJSON<Type: Decodable>() -> Result<Type, APIError> {
        do {
            let value: Type = try defaultDecoder.decode(Type.self, from: self)
            return .success(value)
        } catch {
            return .failure(.parsingError(error))
        }
    }
}
