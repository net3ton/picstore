//
//  Main2Controller.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 05/07/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class MainController: UIViewController {
    @IBOutlet weak var itemsView: UICollectionView!

    public var album: AlbumInfo?
    private var editMode: Bool = false
    private var itemsDelegate = ItemsDelegate()

    override func viewDidLoad() {
        super.viewDidLoad()

        if album == nil {
            appSettings.load()
            appGoogleDrive.start()

            album = appData.open()
        }

        itemsDelegate.openAlbum = openAlbum
        itemsDelegate.openItem = openItem
        itemsDelegate.albumData = album

        itemsView.delegate = itemsDelegate
        itemsView.dataSource = itemsDelegate

        navigationItem.title = album!.getName()
        //navigationItem.backBarButtonItem = UIBarButtonItem(title: "Albums", style: .plain, target: nil, action: nil)
        navigationItem.setHidesBackButton(true, animated: false)

        updateNavigation()
    }

    public func refresh() {
        itemsView.reloadData()
    }

    private func updateNavigation() {
        if editMode {
            //let btnBack = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(onBack))
            let btnEditDone = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(onEditDone))
            navigationItem.setRightBarButtonItems([btnEditDone], animated: true)
            navigationItem.setLeftBarButtonItems([], animated: true)
        }
        else {
            if album!.isRoot() {
                let btnSettings = UIBarButtonItem(image: UIImage(named: "settings"), style: .plain, target: self, action: #selector(onSettings))
                navigationItem.setLeftBarButtonItems([btnSettings], animated: true)
            }
            else {
                let btnBack = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(onBack))
                let btnAlbumInfo = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(onAlbumInfo))
                navigationItem.setLeftBarButtonItems([btnBack], animated: true)
            }

            let btnAdd = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onAddItem))
            let btnEdit = UIBarButtonItem(image: UIImage(named: "props"), style: .plain, target: self, action: #selector(onEdit))
            navigationItem.setRightBarButtonItems([btnEdit], animated: true)
        }
    }

    @objc func onSettings() {
        let sboard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard
        let view = sboard.instantiateViewController(withIdentifier: "settings-main")
        navigationController?.pushViewController(view, animated: true)
    }

    @objc func onAddItem() {
        let sboard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard
        let view = sboard.instantiateViewController(withIdentifier: "import-view") as! ImportController

        view.setup(vc: self, album: album!)
        view.modalPresentationStyle = .popover
        view.popoverPresentationController?.delegate = view
        view.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem

        present(view, animated: true)
    }

    @objc func onEdit() {
        editMode = true
        navigationController?.setToolbarHidden(false, animated: true)

        let btnDelete = UIBarButtonItem(image: UIImage(named: "delete"), style: .plain, target: self, action: nil)
        let btnCopy = UIBarButtonItem(image: UIImage(named: "copy"), style: .plain, target: self, action: nil)
        let btnExport = UIBarButtonItem(image: UIImage(named: "export"), style: .plain, target: self, action: nil)

        let sep1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sep2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.toolbarItems = [btnDelete, sep1, btnCopy, sep2, btnExport]

        updateNavigation()
    }

    @objc func onEditDone() {
        editMode = false
        navigationController?.setToolbarHidden(true, animated: true)

        updateNavigation()
    }

    @objc func onBack() {
        navigationController?.popViewController(animated: true)
    }

    @objc func onAlbumInfo() {
        let sboard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard
        let view = sboard.instantiateViewController(withIdentifier: "settings-album")
        navigationController?.pushViewController(view, animated: true)
    }
    
    private func openAlbum(album: AlbumObject?) {
        let sboard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard
        let view = sboard.instantiateViewController(withIdentifier: "album-view") as! MainController

        view.album = appData.open(album: album)
        navigationController?.pushViewController(view, animated: true)

        //curData.open(album: album)
        //refresh()
    }

    private func openItem(item: ImageObject?) {
        let sboard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard
        let view = sboard.instantiateViewController(withIdentifier: "item-view") as! ItemController

        view.setup(items: album?.items)
        navigationController?.pushViewController(view, animated: true)
    }

    //override func didReceiveMemoryWarning() {
    //    super.didReceiveMemoryWarning()
    //}
}


class ItemsDelegate: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public var albumData: AlbumInfo?
    public var openAlbum: ((AlbumObject?) -> Void)?
    public var openItem: ((ImageObject?) -> Void)?

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albumData?.getItemsCount() ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let album = albumData?.getAlbum(index: indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumViewCell.NAME, for: indexPath) as! AlbumViewCell
            cell.nameLabel.text = album.name
            return cell
        }

        if let item = albumData?.getItem(index: indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ImageViewCell.NAME, for: indexPath) as! ImageViewCell
            cell.imageView.image = item.icon
            return cell
        }
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: ParentViewCell.NAME, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width;
        return CGSize(width: width/4 - 1, height: width/4 - 1);
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //if editMode {
        //curData.select(indexPath.row)
        //return
        //}

        if let album = albumData?.getAlbum(index: indexPath.row) {
            openAlbum?(album)
            return
        }

        if let item = albumData?.getItem(index: indexPath.row) {
            openItem?(item)
            return
        }
    }
}
