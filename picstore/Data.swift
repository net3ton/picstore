//
//  Data.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 27/06/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import Foundation
import UIKit
import CoreData

extension AlbumObject {
    
}

extension ImageObject {
    public var image: UIImage? {
        get {
            if data != nil {
                return UIImage(data: data!)
            }

            return nil
        }
    }

    public var icon: UIImage? {
        get {
            if thumb == nil {
                thumb = makeThumbImage(from: data)
            }

            if thumb != nil {
                return UIImage(data: thumb!)
            }

            return nil
        }
    }

    private func makeThumbImage(from data: Data?) -> Data? {
        var thumbData: Data?
        
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 256] as CFDictionary
        
        data?.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            if let cdata = CFDataCreateWithBytesNoCopy(nil, bytes, data!.count, kCFAllocatorNull) {
                if let source = CGImageSourceCreateWithData(cdata, nil) {
                    if let thumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options) {
                        thumbData = UIImageJPEGRepresentation(UIImage(cgImage: thumb), 0.8)
                    }
                }
            }
        }
        
        return thumbData
    }
    
    public func save() {
        appData.save()
    }
}


class AlbumInfo {
    private(set) var parent: AlbumObject?
    private(set) var items: [ImageObject] = []
    private(set) var albums: [AlbumObject] = []

    private var selected: [Int] = []

    init(parent: AlbumObject?, items: [ImageObject], albums: [AlbumObject]) {
        self.parent = parent
        self.items = items
        self.albums = albums
    }

    public func refresh(finish: (() -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            let allitems = appData.getAllItems(album: self.parent)

            DispatchQueue.main.async {
                self.items = allitems
                finish?()
            }
        }
    }

    public func isRoot() -> Bool {
        return parent == nil
    }

    public func getName() -> String {
        if parent == nil {
            return "Main"
        }

        return parent?.name ?? ""
    }

    public func getItemsCount() -> Int {
        return albums.count + items.count
    }

    public func getAlbumIndex(_ index: Int) -> Int? {
        return (index >= 0 && index < albums.count) ? index : nil
    }

    public func getItemIndex(_ index: Int) -> Int? {
        let ind = index - albums.count
        return (ind >= 0 && ind < items.count) ? ind : nil
    }

    public func getAlbum(index: Int) -> AlbumObject? {
        if let ind = getAlbumIndex(index) {
            return albums[ind]
        }
        return nil
    }

    public func getItem(index: Int) -> ImageObject? {
        if let ind = getItemIndex(index) {
            return items[ind]
        }
        return nil
    }

    public func isAlbumExists(_ name: String) -> Bool {
        for album in albums {
            if album.name == name {
                return true
            }
        }

        return false
    }

    public func addImage(data: Data, name: String) {
        let item = appData.addImage(name, data: data, pos: items.count, parent: parent)
        items.append(item)
    }

    public func addAlbum(name: String) {
        if isAlbumExists(name) {
            print("Album with this name is already exists!")
            return
        }

        let album = appData.addAlbum(name, parent: parent)
        albums.append(album)
    }

    public func save() {
        appData.save()
    }

    public func select(index: Int) {
        if let pos = selected.index(of: index) {
            selected.remove(at: pos)
        }
        else {
            selected.append(index)
        }
    }

    public func isSelected(index: Int) -> Bool {
        return selected.contains(index)
    }

    public func isAnySelected() -> Bool {
        return !selected.isEmpty
    }

    public func getSelectedCount() -> Int {
        return selected.count
    }
    
    public func clearSelection() {
        selected.removeAll()
    }

    public func deleteSelected() {
        if !isAnySelected() {
            return
        }

        var itemsToDelete: [ImageObject] = []
        var albumsToDelete: [AlbumObject] = []

        for ind in selected {
            if let album = getAlbum(index: ind) {
                albumsToDelete.append(album)
            }
            else if let item = getItem(index: ind) {
                itemsToDelete.append(item)
            }
        }

        for item in itemsToDelete {
            if let ind = self.items.index(of: item) {
                self.items.remove(at: ind)
            }

            appData.delete(item)
        }

        for album in albumsToDelete {
            if let ind = self.albums.index(of: album) {
                self.albums.remove(at: ind)
            }

            appData.delete(album)
        }

        clearSelection()
        save()
    }
}


let appData = AppData()

class AppData {
    private var container: NSPersistentContainer
    
    public init() {
        container = NSPersistentContainer(name: "Main")
        container.loadPersistentStores() { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Core Data init ERROR: \(error.localizedDescription), \(error.userInfo)")
            }
        }
    }

    private func getContext() -> NSManagedObjectContext {
        return container.viewContext
    }
    
    public func save() {
        let context = getContext()
        if context.hasChanges {
            do {
                try context.save()
            }
            catch let error {
                fatalError("Core Data save ERROR \(error.localizedDescription)")
            }
        }
    }

    public func open(album: AlbumObject? = nil) -> AlbumInfo {
        let albumsRequest = NSFetchRequest<AlbumObject>(entityName: "Album")
        let imagesRequest = NSFetchRequest<ImageObject>(entityName: "Image")
        let context = getContext()

        var albums: [AlbumObject] = []
        var items: [ImageObject] = []

        do {
            var predicate: NSPredicate?
            
            if album == nil {
                predicate = NSPredicate(format: "parent = nil")
            }
            else {
                predicate = NSPredicate(format: "parent = %@", album!)
            }
            
            albumsRequest.predicate = predicate
            albums = try context.fetch(albumsRequest)

            imagesRequest.predicate = predicate
            imagesRequest.sortDescriptors = [NSSortDescriptor(key: "pos", ascending: true)]
            //imagesRequest.propertiesToFetch = ["name", "thumb"]
            //imagesRequest.resultType = .dictionaryResultType
            imagesRequest.fetchLimit = 28
            items = try context.fetch(imagesRequest)
        }
        catch let error {
            print("Failed to fetch spend record! ERROR: " + error.localizedDescription)
        }
        
        return AlbumInfo(parent: album, items: items, albums: albums)
    }
    
    public func getAllItems(album: AlbumObject?) -> [ImageObject] {
        let imagesRequest = NSFetchRequest<ImageObject>(entityName: "Image")
        let context = getContext()

        do {
            var predicate: NSPredicate?
            
            if album == nil {
                predicate = NSPredicate(format: "parent = nil")
            }
            else {
                predicate = NSPredicate(format: "parent = %@", album!)
            }

            imagesRequest.predicate = predicate
            imagesRequest.sortDescriptors = [NSSortDescriptor(key: "pos", ascending: true)]
            //imagesRequest.propertiesToFetch = ["name", "thumb"]
            return try context.fetch(imagesRequest)
        }
        catch let error {
            print("Failed to fetch spend record! ERROR: " + error.localizedDescription)
        }

        return []
    }

    public func getFavoriteItems() -> [ImageObject] {
        do {
            let imagesRequest: NSFetchRequest<ImageObject> = ImageObject.fetchRequest()
            
            imagesRequest.predicate = NSPredicate(format: "rating > 0")
            imagesRequest.sortDescriptors = [NSSortDescriptor(key: "pos", ascending: true)]
            
            return try getContext().fetch(imagesRequest)
        }
        catch let error {
            print("Failed to fetch spend record! ERROR: " + error.localizedDescription)
        }
        
        return []
    }
    
    public func addAlbum(_ name: String, parent: AlbumObject?) -> AlbumObject {
        let context = getContext()
        let albumEntity = NSEntityDescription.entity(forEntityName: "Album", in: context)
        let album = AlbumObject(entity: albumEntity!, insertInto: context)
        
        album.name = name
        album.date = Date()
        album.parent = parent

        return album
    }

    public func addImage(_ name: String, data: Data, pos: Int, parent: AlbumObject?) -> ImageObject {
        let context = getContext()
        let itemEntity = NSEntityDescription.entity(forEntityName: "Image", in: context)
        let item = ImageObject(entity: itemEntity!, insertInto: context)

        item.name = name
        item.date = Date()
        item.rating = 0
        item.views = 0
        item.pos = Int32(pos)

        item.data = data
        item.thumb = nil
        item.parent = parent

        return item
    }

    public func delete(_ object: NSManagedObject) {
        getContext().delete(object)
    }
}
