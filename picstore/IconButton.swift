//
//  IconButton.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 13.04.2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit

@IBDesignable class IconButton: UIButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        initButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initButton()
    }

    func initButton() {
        self.setTitleColor(UIColor.black, for: .normal)
        self.setTitleColor(UIColor.blue, for: .highlighted)
        
        self.backgroundColor = UIColor.white
        self.layer.cornerRadius = 5
        self.titleLabel?.font = self.titleLabel?.font.withSize(10)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if let imgView = self.imageView {
            imgView.frame.size.width = self.frame.size.width / 2
            imgView.frame.size.height = self.frame.size.width / 2
            
            imgView.center.x = self.frame.size.width / 2
            imgView.center.y = imgView.frame.size.height / 2 + 8
        }

        if let txtLabel = self.titleLabel {
            txtLabel.frame.origin.x = 0
            txtLabel.frame.origin.y = self.frame.size.height - 22
            txtLabel.frame.size.width = self.frame.size.width
            txtLabel.frame.size.height = 18
            txtLabel.textAlignment = .center
        }
    }
}
