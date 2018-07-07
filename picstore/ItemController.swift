//
//  ItemController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 28/06/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit
import ImageSlideshow

class ItemController: UIViewController {
    private var items: [ImageObject] = []

    @IBOutlet weak var imageView: ImageSlideshow!

    override func viewDidLoad() {
        super.viewDidLoad()

        var mas: [InputPicSource] = []
        for item in items {
            mas.append(InputPicSource(item: item))
        }

        imageView.preload = .fixed(offset: 1)
        imageView.pageControlPosition = .hidden
        imageView.backgroundColor = UIColor.black
        imageView.setImageInputs(mas)
        //imageView.setCurrentPage(4, animated: false)
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        imageView.addGestureRecognizer(gestureRecognizer)
    }

    public func setup(items: [ImageObject]?) {
        self.items = items ?? []
    }

    @objc func viewTapped() {
        imageView.presentFullScreenController(from: self)
    }
}


class InputPicSource: NSObject, InputSource {
    private var item: ImageObject

    init(item: ImageObject) {
        self.item = item
    }

    func load(to imageView: UIImageView, with callback: @escaping (UIImage?) -> Void) {
        imageView.image = item.image
        callback(imageView.image)
    }
}
