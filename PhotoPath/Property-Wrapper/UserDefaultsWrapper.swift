//
//  UserDefaultsWrapper.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 14.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation

/**
Wraps a property that is automatically stored in the user defaults.

Usage:

    @UserDefault("defaults.key.for.property", defaultValue: "Leeroy")
    var username: String
*/
@propertyWrapper
struct UserDefault<Type> {
    let defaults = UserDefaults.standard
    let key: String
    let defaultValue: Type

    init(_ key: String, defaultValue: Type) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: Type {
        get {
            return defaults.object(forKey: key) as? Type ?? defaultValue
        }
        set {
            defaults.set(newValue, forKey: key)
        }
    }
}
