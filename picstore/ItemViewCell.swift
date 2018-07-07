//
//  ItemViewCell.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 06.04.2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit
import Photos

class ImageViewCell: UICollectionViewCell {
    public static let NAME = "ImageCell"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageSelection: UIImageView!

    public func setSelected(on: Bool) {
        imageSelection.isHidden = !on
    }
}

class AlbumViewCell: UICollectionViewCell {
    public static let NAME = "AlbumCell"

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var imageSelection: UIImageView!

    public func setSelected(on: Bool) {
        imageSelection.isHidden = !on
    }
}

class ParentViewCell: UICollectionViewCell {
    public static let NAME = "ParentCell"
}
