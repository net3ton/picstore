//
//  ExportMedia.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 15.02.2020.
//  Copyright © 2020 Oleksandr Kharkov. All rights reserved.
//

import UIKit
import Photos

private func getImageExt(_ data: Data) -> String? {
    let JPG  = Data(bytes: [0xFF, 0xD8, 0xFF])
    let PNG  = Data(bytes: [0x89, 0x50, 0x4E, 0x47])
    let GIF  = Data(bytes: [0x47, 0x49, 0x46, 0x38])
    let HEIC = Data(bytes: [0x66, 0x74, 0x79, 0x70, 0x68, 0x65, 0x69, 0x63]) // since 4th byte
    
    let knownFormats = [
        (sign: JPG, since: 0, ext: ".jpg"),
        (sign: PNG, since: 0, ext: ".png"),
        (sign: GIF, since: 0, ext: ".gif"),
        (sign: HEIC, since: 4, ext: ".heic"),
    ]
    
    for format in knownFormats {
        let signfrom = format.since
        let signto = format.since + format.sign.count
        
        if data.subdata(in: signfrom..<signto).elementsEqual(format.sign) {
            return format.ext
        }
    }
    
    return nil
}


private func exportImageWithData(_ imgData: Data?, _ imgName: String, to exportPath: URL, or nonPhotoPath: URL?, quality: Float) -> Int {
    guard var imageData = imgData else {
        return 0
    }
    
    guard var imageExt = getImageExt(imageData) else {
        print("Could not export, unkown image format: ", imgName)
        return 0
    }
    
    // convert from HEIC to JPEG
    if imageExt == ".heic" {
        let image: UIImage = UIImage(data: imageData)!
        imageData = UIImageJPEGRepresentation(image, CGFloat(quality))!
        imageExt = ".jpg"
    }
    
    // fix filename ext
    let newName = URL(fileURLWithPath: imgName).deletingPathExtension().lastPathComponent + imageExt
    var filePath = exportPath.appendingPathComponent(newName)
    
    // if not a photo - check if we should save it saparately
    if imageExt != ".jpg", let nonPhotoPath = nonPhotoPath {
        filePath = nonPhotoPath.appendingPathComponent(newName)
    }
    
    if FileManager().createFile(atPath: filePath.path, contents: imageData, attributes: nil) {
        //print("Saved: ", newName)
        return imageData.count
    }
    
    print("Could not export, save error: ", newName)
    return 0
}

private func exportVideo(_ videoData: AVAsset?, _ videoName: String, to exportPath: URL) -> Int {
    guard let avUrlAsset = videoData as? AVURLAsset else {
        print("Could not save video, base video url is empty: ", videoName)
        return 0
    }
    
    let videoPath = exportPath.appendingPathComponent(videoName)
    
    do {
        if FileManager().fileExists(atPath: videoPath.absoluteString) {
            print("Video already exists! Overwriting: ", videoName)
            try FileManager().removeItem(at: videoPath)
        }
        
        try FileManager().copyItem(at: avUrlAsset.url, to: videoPath)
        //print("Saved [video]: ", videoName)
        return 0
    }
    catch let error {
        print("Could not copy video: ", error.localizedDescription)
    }
    
    return 0
}


private func createFolder(parent: URL, name: String) -> URL? {
    let resultPath = parent.appendingPathComponent(name)
    
    if !FileManager().fileExists(atPath: resultPath.absoluteString) {
        do {
            try FileManager().createDirectory(at: resultPath, withIntermediateDirectories: true, attributes: nil)
        }
        catch {
            print("Could not create folder: ", resultPath.absoluteString)
            return nil
        }
    }
    
    return resultPath
}


private func createFolder(parent: URL, for date: Date, forEveryMonth: Bool) -> URL? {
    let formatter = DateFormatter()
    formatter.dateFormat = forEveryMonth ? "YYYY-MM" : "YYYY-MM-dd"

    let folderName = formatter.string(from: date)
    return createFolder(parent: parent, name: folderName)
}


public protocol ExportMediaNotify {
    func onExportMediaStart()
    func onExportMediaStep(step: Int, count: Int)
    func onExportMediaFinished(size: Int)
}


public func exportMediaToDocs(with cfg: ExportSettings, notifier: ExportMediaNotify) {
    let manager = PHImageManager()
    
    let imgOptions = PHImageRequestOptions()
    imgOptions.isNetworkAccessAllowed = true
    imgOptions.version = .current
    imgOptions.isSynchronous = true
    imgOptions.resizeMode = .none // .exact
    imgOptions.deliveryMode = .highQualityFormat

    let videoOptions = PHVideoRequestOptions()
    videoOptions.isNetworkAccessAllowed = true
    videoOptions.version = .current
    
    // create export documents subfolder
    let docPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
    guard let exportPath = createFolder(parent: docPath, name: cfg.folderName) else {
        return
    }
    
    // create subfolder for non-photos if needed
    var nonPhotoFolder: URL? = nil
    if cfg.notPhotosAside {
        nonPhotoFolder = createFolder(parent: exportPath, name: "Media")
    }
    
    // fetch all assets in specified date range
    let fetchOptions = PHFetchOptions()
    fetchOptions.predicate = NSPredicate(format: "creationDate > %@ AND creationDate < %@", cfg.from as NSDate, cfg.to as NSDate)
    
    var exportedSize = 0
    let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
    
    notifier.onExportMediaStart()
    
    for index in 0  ..< fetchResult.count  {
        notifier.onExportMediaStep(step: index, count: fetchResult.count)
        
        let asset = fetchResult.object(at: index)
        
        // fetch asset name
        guard let assetName = asset.value(forKey: "filename") as? String else {
            print("Could not get asset name! Asset was skipped.")
            continue
        }
        
        let assetDate = asset.creationDate!
        var assetFolder = exportPath
        
        // create subfolder if specified
        if cfg.createSubFolders != .None {
            let everyMonth = (cfg.createSubFolders == .Months)
            
            if let subFolderPath = createFolder(parent: exportPath, for: assetDate, forEveryMonth: everyMonth) {
                assetFolder = subFolderPath
            }
        }
        
        autoreleasepool {
            if asset.mediaType == .image {
                manager.requestImageData(for: asset, options: imgOptions) { (imageData, dataUTI, orientation, info) in
                    exportedSize += exportImageWithData(imageData, assetName, to: assetFolder, or: nonPhotoFolder, quality: cfg.jpegQuality)
                }
            }
            else if asset.mediaType == .video {
                manager.requestAVAsset(forVideo: asset, options: videoOptions) { (avAsset, audioMix, info) in
                    exportedSize += exportVideo(avAsset, assetName, to: assetFolder)
                }
            }
            else {
                print("Unknown type media:", assetName)
            }
        }
    }
    
    notifier.onExportMediaFinished(size: exportedSize)
}
