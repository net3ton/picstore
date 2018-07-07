//
//  ItemViewCell.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 06.04.2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit
import Photos

/*
class ItemViewCell: UICollectionViewCell {
    public static let NAME = "ItemCell"

    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        self.addSubview(imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = self.bounds
    }
}
*/

class ImageViewCell: UICollectionViewCell {
    public static let NAME = "ImageCell"
    
    @IBOutlet weak var imageView: UIImageView!
}


class AlbumViewCell: UICollectionViewCell {
    public static let NAME = "AlbumCell"

    @IBOutlet weak var nameLabel: UILabel!
}

class ParentViewCell: UICollectionViewCell {
    public static let NAME = "ParentCell"
}
