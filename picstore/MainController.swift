//
//  ItemsController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 05.04.2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit
import Photos

class MainController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    //private var editMode: Bool = false
    //private var toolbar: UIToolbar?

    override func viewDidLoad() {
        super.viewDidLoad()
        appSettings.load()
        appGoogleDrive.start()

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
        collectionView!.register(ItemViewCell.self, forCellWithReuseIdentifier: ItemViewCell.NAME)

        //let longPress = UILongPressGestureRecognizer(target: self, action: #selector(onLongPressed))
        //collectionView?.addGestureRecognizer(longPress)

        //toolbar = UIToolbar(frame: CGRect(x: 0, y: view.frame.height - 40, width: view.frame.width, height: 40))
    }

    //override func didReceiveMemoryWarning() {
    //    super.didReceiveMemoryWarning()
    //}

    func refresh() {
        navigationItem.title = curData.getCurrentAlbumName()
        collectionView?.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return curData.getItemsCount()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let album = curData.getAlbum(index: indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AlbumViewCell.NAME, for: indexPath) as! AlbumViewCell
            cell.nameLabel.text = album.name
            return cell
        }

        if let item = curData.getItem(index: indexPath.row) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ItemViewCell.NAME, for: indexPath) as! ItemViewCell
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

    func showItemView() {
        let sboard = UIStoryboard(name: "Main", bundle: nil) as UIStoryboard
        let view = sboard.instantiateViewController(withIdentifier: "item-view") as! ItemController
        
        //view.setup(category: info)
        navigationController?.pushViewController(view, animated: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let album = curData.getAlbum(index: indexPath.row) {
            curData.open(album: album)
            refresh()
            return
        }

        if let item = curData.getItem(index: indexPath.row) {
            showItemView()
            return
        }

        curData.openParentAlbum()
        refresh()
    }

    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        //let cell = collectionView.cellForItem(at: indexPath)
        //cell?.backgroundColor = UIColor.brown
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        //let cell = collectionView.cellForItem(at: indexPath)
        //cell?.backgroundColor = UIColor.white
    }

    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "add_item" {
            if let importVC = segue.destination as? ImportController {
                importVC.popoverPresentationController?.delegate = importVC
                importVC.root = self
            }
        }
    }
}
