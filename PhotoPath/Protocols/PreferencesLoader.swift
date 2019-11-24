//
//  PreferencesLoader.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 14.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation

protocol PreferencesLoader {
    var key: String { get }
    func loadValue<Type>() -> Type? where Type: Decodable
    func save<Type>(value: Type?) where Type: Encodable
}

extension PreferencesLoader {
    func loadValue<Type>() -> Type? where Type: Decodable {
        let defaults = UserDefaults.standard
        if let data = defaults.value(forKey: key) as? Data {
            do {
                let value = try PropertyListDecoder().decode(Type.self, from: data)
                return value
            } catch {
                return nil
            }
        }
        return nil
    }
    
    func save<Type>(value: Type?) where Type: Encodable {
        let defaults = UserDefaults.standard
        
        guard let value = value else {
            defaults.removeObject(forKey: key)
            return
        }
        
        if let encoded = try? PropertyListEncoder().encode(value) {
            defaults.set(encoded, forKey: key)
        }
    }
}
