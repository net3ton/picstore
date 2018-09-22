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

    private var album: AlbumObject?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Album info"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(save))
        updateInfo()
    }

    public func setup(album: AlbumObject?) {
        self.album = album
    }

    private func updateInfo() {
        nameLabel.text = album?.name
    }

    @objc func save() {
        
    }

    //override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //}
}
