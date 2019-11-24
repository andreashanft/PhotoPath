//
//  String+Localised.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 17.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation

extension String {
    func localised(_ comment: String? = nil) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: comment ?? "")
    }
}
