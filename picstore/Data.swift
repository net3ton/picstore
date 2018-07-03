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


let curData = CurrentData()

class CurrentData {
    private(set) var current: AlbumObject?
    private(set) var items: [ImageObject] = []
    private(set) var albums: [AlbumObject] = []

    private var container: NSPersistentContainer

    public init() {
        container = NSPersistentContainer(name: "Main")
        container.loadPersistentStores() { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Core Data init ERROR: \(error.localizedDescription), \(error.userInfo)")
            }
        }

        open()
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

    public func openParentAlbum() {
        if current != nil {
            open(album: current?.parent)
        }
    }

    public func open(album: AlbumObject? = nil) {
        current = album

        let albumsRequest = NSFetchRequest<AlbumObject>(entityName: "Album")
        let imagesRequest = NSFetchRequest<ImageObject>(entityName: "Image")

        do {
            var predicate: NSPredicate?
            
            if current == nil {
                predicate = NSPredicate(format: "parent = nil")
            }
            else {
                predicate = NSPredicate(format: "parent = %@", current!)
            }

            albumsRequest.predicate = predicate
            albums = try container.viewContext.fetch(albumsRequest)

            imagesRequest.predicate = predicate
            items = try container.viewContext.fetch(imagesRequest)
        }
        catch let error {
            print("Failed to fetch spend record! ERROR: " + error.localizedDescription)
        }
    }

    public func isRootAlbum() -> Bool {
        return current == nil
    }
    
    public func getCurrentAlbumName() -> String {
        if current == nil {
            return "Main"
        }

        return current?.name ?? ""
    }
    
    public func getItemsCount() -> Int {
        return albums.count + items.count + (isRootAlbum() ? 0 : 1)
    }

    public func getAlbum(index: Int) -> AlbumObject? {
        var ind = index

        if !isRootAlbum() {
            if ind == 0 {
                return nil
            }

            ind -= 1
        }

        if ind < 0 || ind >= albums.count {
            return nil
        }

        return albums[ind]
    }

    public func getItem(index: Int) -> ImageObject? {
        var ind = index

        if !isRootAlbum() {
            if ind == 0 {
                return nil
            }

            ind -= 1
        }

        ind -= albums.count

        if ind < 0 || ind >= items.count {
            return nil
        }

        return items[ind]
    }

    public func addImage(data: Data, name: String) {
        let itemEntity = NSEntityDescription.entity(forEntityName: "Image", in: container.viewContext)

        let item = ImageObject(entity: itemEntity!, insertInto: container.viewContext)
        item.name = name
        item.date = Date()
        item.rating = 0
        item.views = 0

        item.data = data
        item.thumb = nil
        item.parent = current

        items.append(item)
    }

    public func addAlbum(name: String) {
        if isAlbumExists(name) {
            print("Album with this name is already exists!")
            return
        }

        let albumEntity = NSEntityDescription.entity(forEntityName: "Album", in: container.viewContext)
        
        let album = AlbumObject(entity: albumEntity!, insertInto: container.viewContext)
        album.name = name
        album.date = Date()
        album.parent = current

        albums.append(album)
    }

    public func isAlbumExists(_ name: String) -> Bool {
        for album in albums {
            if album.name == name {
                return true
            }
        }

        return false
    }

    public func removeImage(index: Int) {
        let item = items[index]
        container.viewContext.delete(item)
    }

    public func removeAlbum(index: Int) {
        
    }
}
