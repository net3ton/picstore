//
//  AlbumController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 07/07/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit

enum EAlbumPin {
    case none
    case pin4
}

enum EAlbumHidden {
    case none
    case hidden
}


class AlbumController: UITableViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sortLabel: UILabel!
    
    private var album: AlbumObject?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Album"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Apply", style: .plain, target: self, action: #selector(apply))
        updateInfo()
    }

    public func setup(album: AlbumObject?) {
        self.album = album
    }

    private func updateInfo() {
        nameLabel.text = album?.name
    }

    @objc func apply() {
    }

    private func onSortPicked(sort: AlbumSort?) {
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "album-sort" {
            if let sortController = segue.destination as? SortingController {
                sortController.onSortPicked = onSortPicked
                sortController.initSort = AlbumSort.Rating
            }
        }
    }
}
