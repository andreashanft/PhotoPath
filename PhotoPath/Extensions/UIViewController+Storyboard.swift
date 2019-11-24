//
//  UIViewController+Storyboard.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 13.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    
    public static func makeFromStoryboard() -> Self? {
        
        let sceneStoryboard = UIStoryboard(name: String(describing: self), bundle: Bundle(for: self))
        let viewController = sceneStoryboard.instantiateInitialViewController()
        
        guard let typedViewController = viewController as? Self else {
            assertionFailure("Could not create view controller from storyboard \(sceneStoryboard) with class \(self)")
            return nil
        }
        return typedViewController
    }
}
