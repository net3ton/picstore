//
//  ImportController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 06.04.2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit
import MobileCoreServices
import NohanaImagePicker
import ZIPFoundation
import Photos

enum EImportType {
    case image
    case archive
    case unknown
}

private func get_file_type(ext: String) -> EImportType {
    let fext = ext.lowercased()

    if fext == "jpg" || fext == "jpeg" || fext == "png" {
        return .image
    }

    if fext == "zip" || fext == "cbz" {
        return .archive
    }

    return .unknown
}

private func is_image_data(_ data: Data) -> Bool {
    let JPG = Data(bytes: [0xFF, 0xD8, 0xFF])
    let PNG = Data(bytes: [0x89, 0x50, 0x4E, 0x47])
    let GIF = Data(bytes: [0x47, 0x49, 0x46, 0x38])
    //let RAR = Data(bytes: [0x52, 0x61, 0x72])
    //let A7Z = Data(bytes: [0x37, 0x7A, 0xBC, 0xAF])
    let signs = [JPG, PNG, GIF]

    for signature in signs {
        if data.range(of: signature, options: .anchored, in: 0..<signature.count) != nil {
            return true
        }
    }
    
    return false
}

class ImportController: UIViewController, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    public var root: MainController?
    @IBOutlet weak var separatorImport: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        separatorImport.layer.cornerRadius = 2
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // UIPopoverPresentationControllerDelegate
    internal func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    //override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //    print("prepare")
    //}

    private func addImageToLibrary(data: Data, name: String) {
        if !is_image_data(data) {
            print("Failed to import image! ERROR: wrong image format")
            return
        }

        curData.addImage(data: data, name: name)
    }
    
    @IBAction func photosPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        assetsPickerDelegate.present(vc: root!)
    }

    @IBAction func sharedFolderPressed(_ sender: UIButton) {
        var count = 0

        do {
            let docsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
            let fileList = try FileManager().contentsOfDirectory(atPath: docsPath.path)

            for fileName in fileList {
                let filePath = docsPath.appendingPathComponent(fileName)
                let fileType = get_file_type(ext: filePath.pathExtension)

                if fileType == .image {
                    if let fdata = FileManager().contents(atPath: filePath.path) {
                        addImageToLibrary(data: fdata, name: fileName)
                        count += 1
                    }
                }
                else if fileType == .archive {
                    count += importArchive(at: filePath)
                }

                try FileManager().removeItem(at: filePath)
            }
        }
        catch let error {
            print(error.localizedDescription)
        }

        print(String.init(format: "added %i items", count))

        dismiss(animated: true, completion: nil)
        curData.save()
        root?.refresh()
    }
    
    static public var sharedFolderFilesCount: Int {
        get {
            var count = 0
            
            do {
                let docsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
                let fileList = try FileManager().contentsOfDirectory(atPath: docsPath.path)
                
                for fileName in fileList {
                    if get_file_type(ext: URL(fileURLWithPath: fileName).pathExtension) != .unknown {
                        count += 1
                    }
                }
            }
            catch let error {
                print(error.localizedDescription)
            }
            
            return count
        }
    }

    @IBAction func googlePressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)

        if appGoogleDrive.isLogined() {
            googlePickFile()
        }
        else {
            appGoogleDrive.signIn(vc: root!) {
                self.googlePickFile()
            }
        }
    }

    private func googlePickFile() {
        appGoogleDrive.onFileDownloaded = onFileDownloaded
        appGoogleDrive.showFilePicker(vc: root!)
    }
    
    private func onFileDownloaded(data: Data, name: String) {
        let docsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
        let filePath = docsPath.appendingPathComponent(name)
        let fileType = get_file_type(ext: filePath.pathExtension)

        var count = 0

        if fileType == .image {
            addImageToLibrary(data: data, name: name)
            count += 1
        }
        else if fileType == .archive {
            do {
                try data.write(to: filePath)
                count = importArchive(at: filePath)
                try FileManager().removeItem(at: filePath)
            }
            catch let error {
                print(error.localizedDescription)
                return
            }
        }

        print(String.init(format: "added %i items", count))

        curData.save()
        root?.refresh()
    }

    private func importArchive(at fileUrl: URL) -> Int {
        var count = 0
        if let arch = Archive(url: fileUrl, accessMode: .read) {
            for item in arch {
                if item.type == .file {
                    let pathUrl = URL(fileURLWithPath: item.path)
                    if get_file_type(ext: pathUrl.pathExtension) == .image {
                        do {
                            var fileData = Data(capacity: item.uncompressedSize)
                            let _ = try arch.extract(item, consumer: { (data) in
                                fileData.append(data)
                            })

                            print(item.path)
                            addImageToLibrary(data: fileData, name: pathUrl.lastPathComponent)
                            count += 1
                        }
                        catch let error {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }

        return count
    }

    @IBAction func newFolderPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)

        let alert = UIAlertController(title: "New album", message: "", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
        }

        alert.addAction(UIAlertAction(title: "OK", style: .default) { (_) in
            let textfield = alert.textFields?.first
            let name = textfield?.text ?? ""
            
            if !name.isEmpty {
                if !curData.isAlbumExists(name) {
                    curData.addAlbum(name: name)
                    curData.save()
                    self.root?.refresh()
                }
                else {
                    print("Album with the same name is already exists!")
                }
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        root?.present(alert, animated: true)
    }
}

/*
func imageToData(image: UIImage) -> Data? {
    if let cgImage = image.cgImage, cgImage.renderingIntent == .defaultIntent {
        return UIImageJPEGRepresentation(image, 1.0)
    }

    return UIImagePNGRepresentation(image)
}
*/

let assetsPickerDelegate = AssetsPickerDelegate()

class AssetsPickerDelegate: NSObject, NohanaImagePickerControllerDelegate {
    private var root: MainController?
    
    public func present(vc: MainController) {
        self.root = vc

        let picker = NohanaImagePickerController()
        picker.delegate = self
        picker.maximumNumberOfSelection = 0

        root?.present(picker, animated: true)
    }

    func nohanaImagePickerDidCancel(_ picker: NohanaImagePickerController) {
        root?.dismiss(animated: true, completion: nil)
    }

    internal func nohanaImagePicker(_ picker: NohanaImagePickerController, didFinishPickingPhotoKitAssets pickedAssts: [PHAsset]) {
        let manager = PHImageManager()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.resizeMode = .exact

        for item in pickedAssts {
            if item.mediaType == .image {
                manager.requestImageData(for: item, options: options) { (imageData, dataUTI, orientation, info) in
                    if let imgData = imageData {
                        curData.addImage(data: imgData, name: "")
                    }
                }
            }
        }

        curData.save()
        root?.dismiss(animated: true, completion: nil)
        root?.refresh()
    }
}
