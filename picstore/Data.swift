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

    public func getAlbum(index: Int) -> AlbumObject? {
        if index >= 0 && index < albums.count {
            return albums[index]
        }

        return nil
    }

    public func getItem(index: Int) -> ImageObject? {
        let ind = index - albums.count
        if ind >= 0 && ind < items.count {
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
        let context = appData.getContext()
        let itemEntity = NSEntityDescription.entity(forEntityName: "Image", in: context)
        let item = ImageObject(entity: itemEntity!, insertInto: context)

        item.name = name
        item.date = Date()
        item.rating = 0
        item.views = 0
        item.pos = Int32(items.count)

        item.data = data
        item.thumb = nil
        item.parent = parent

        items.append(item)
    }

    public func addAlbum(name: String) {
        if isAlbumExists(name) {
            print("Album with this name is already exists!")
            return
        }

        let context = appData.getContext()
        let albumEntity = NSEntityDescription.entity(forEntityName: "Album", in: context)
        let album = AlbumObject(entity: albumEntity!, insertInto: context)

        album.name = name
        album.date = Date()
        album.parent = parent

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

    public func clearSelection() {
        selected.removeAll()
    }

    public func deleteSelected() {
        let context = appData.getContext()

        for ind in selected {
            if let album = getAlbum(index: ind) {
                context.delete(album)
            }
            else if let item = getItem(index: ind) {
                context.delete(item)
            }
        }
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

    public func getContext() -> NSManagedObjectContext {
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
            albums = try container.viewContext.fetch(albumsRequest)

            imagesRequest.predicate = predicate
            items = try container.viewContext.fetch(imagesRequest)
        }
        catch let error {
            print("Failed to fetch spend record! ERROR: " + error.localizedDescription)
        }

        return AlbumInfo(parent: album, items: items, albums: albums)
    }
}
