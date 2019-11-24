//
//  DebugLogger.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 15.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation

final class DebugLogger {
    static var onOutputChange: (([String]) -> Void)?
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    private static var output: [String] = [] {
        didSet {
            onOutputChange?(output)
        }
    }
    
    static func log(_ text: String) {
        let timestamp = "[" + dateFormatter.string(from: Date()) + "]"
        let log = timestamp + " " + text
        output.append(log)
        
        #if DEBUG
        print(log)
        #endif
    }
}
