//
//  MainTableViewCell.swift
//  PhotoPath
//
//  Created by Andreas Hanft on 15.11.19.
//  Copyright © 2019 relto. All rights reserved.
//

import Foundation
import UIKit

final class MainTableViewCell: UITableViewCell {
    @IBOutlet weak var photoView: UIImageView!
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    override func prepareForReuse() {
        super.prepareForReuse()
        
        photoView.image = nil
        activityView.startAnimating()
    }
    
    func configure(with presentation: TrackPointPresentation) {
        guard let path = presentation.photoPath, let image = UIImage(contentsOfFile: path) else { return }
        
        activityView.stopAnimating()
        photoView.image = image
    }
}
