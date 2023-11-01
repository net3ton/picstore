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

//let RAR = Data(bytes: [0x52, 0x61, 0x72])
//let A7Z = Data(bytes: [0x37, 0x7A, 0xBC, 0xAF])

private func is_image_data(_ data: Data) -> Bool {
    let JPG = Data(bytes: [0xFF, 0xD8, 0xFF])
    let PNG = Data(bytes: [0x89, 0x50, 0x4E, 0x47])
    let GIF = Data(bytes: [0x47, 0x49, 0x46, 0x38])

    let signs = [JPG, PNG, GIF]
    
    for signature in signs {
        if data.subdata(in: 0..<signature.count).elementsEqual(signature) {
            return true
        }
    }
    
    return false
}

class ImportController: UIViewController, UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    private var root: MainController?
    private var album: AlbumInfo?

    private var waitView: UIAlertController?
    
    @IBOutlet weak var separatorImport: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        separatorImport.layer.cornerRadius = 2
    }

    // UIPopoverPresentationControllerDelegate
    internal func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }

    public func setup(vc: MainController, album: AlbumInfo) {
        self.root = vc
        self.album = album
    }

    private func addImageToLibrary(data: Data, name: String, numDone: Int) -> Int {
        if !is_image_data(data) {
            print("Failed to import image! ERROR: wrong image format!")
            return numDone
        }
        
        DispatchQueue.main.async {
            self.album?.addImage(data: data, name: name)
            self.waitView?.message = String(format: "%d", numDone)
        }
        return numDone + 1
    }

    private func importArchiveToLibrary(at fileUrl: URL, numDone: Int) -> Int {
        var count = numDone
        
        if let arch = Archive(url: fileUrl, accessMode: .read) {
            for item in arch {
                autoreleasepool {
                    if item.type == .file {
                        let pathUrl = URL(fileURLWithPath: item.path)
                        if get_file_type(ext: pathUrl.pathExtension) == .image {
                            //DispatchQueue.global(qos: .userInitiated).async {
                                do {
                                    var fileData = Data(capacity: Int(item.uncompressedSize))
                                    let _ = try arch.extract(item, consumer: { (data) in
                                        fileData.append(data)
                                    })

                                    count = self.addImageToLibrary(data: fileData, name: pathUrl.lastPathComponent, numDone: count)
                                }
                                catch let error {
                                    print(error.localizedDescription)
                                }
                            //}
                        }
                    }
                }
            }
        }

        return count
    }
    
    private func processFile(url: URL, name: String) -> Int {
        let fileType = get_file_type(ext: URL(fileURLWithPath: name).pathExtension)
        //let fileType = get_file_type(ext: url.pathExtension)
        var count = 0
        
        print("process:", url, "name:", name, "ext:", fileType)
        
        do {
            if fileType == .image {
                print("image!")
                //if let fdata = FileManager().contents(atPath: filePath.path)
                
                let data = try Data(contentsOf: url)
                count = addImageToLibrary(data: data, name: name, numDone: count)
            }
            else if fileType == .archive {
                print("arch!")
                count = importArchiveToLibrary(at: url, numDone: count)
            }
            
            try FileManager().removeItem(at: url)
        }
        catch let error {
            print(error.localizedDescription)
        }
        
        return count
    }
    
    @IBAction func photosPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        assetsPickerDelegate.present(vc: root!, album: album!)
    }
    
    @IBAction func exportMediaPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        
        let sboard = UIStoryboard(name: "ExportMedia", bundle: nil) as UIStoryboard
        let view = sboard.instantiateViewController(withIdentifier: "export-media")
        //root?.navigationController?.pushViewController(view, animated: true)
        
        //let btnExit = UIBarButtonItem(title: "Back", style: .plain, target: self, action: nil)
        
        let nav = UINavigationController()
        nav.viewControllers = [view]
        //nav.setLeftBarButtonItems([btnExit], animated: true)
        
        root?.present(nav, animated: true)
    }
    
    @IBAction func sharedFolderPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
        
        waitView = createWaitModal(title: "Import")
        present(waitView!, animated: true)
        
        DispatchQueue.global(qos: .background).async {
            var count = 0

            do {
                let docsPath = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!)
                let fileList = try FileManager().contentsOfDirectory(atPath: docsPath.path)

                for fileName in fileList {
                    let filePath = docsPath.appendingPathComponent(fileName)
                    count += self.processFile(url: filePath, name: fileName)
                }
            }
            catch let error {
                print(error.localizedDescription)
            }
            
            DispatchQueue.main.async {
                self.waitView?.dismiss(animated: true)
                self.waitView = nil
            }
            
            print(String.init(format: "added %i items", count))

            self.album?.save()
            self.root?.refresh()
        }
    }

    @IBAction func googlePressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)

        if appGoogleDrive.isDriveEnabled() {
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

    private func onFileDownloaded(url: URL, name: String) {
        self.waitView = createWaitModal(title: "Import")
        self.root?.present(self.waitView!, animated: true)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let count = self.processFile(url: url, name: name)
            
            DispatchQueue.main.async {
                self.waitView?.dismiss(animated: true)
                self.waitView = nil
                
                print(String.init(format: "added %i items", count))

                self.album?.save()
                self.root?.refresh()
            }
        }
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
                if let album = self.album {
                    if !album.isAlbumExists(name) {
                        album.addAlbum(name: name)
                        album.save()
                        self.root?.refresh()
                    }
                    else {
                        print("Album with the same name is already exists!")
                    }
                }
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        root?.present(alert, animated: true)
    }
}


let assetsPickerDelegate = AssetsPickerDelegate()

class AssetsPickerDelegate: NSObject, NohanaImagePickerControllerDelegate {
    private var root: MainController?
    private var album: AlbumInfo?
    
    public func present(vc: MainController, album: AlbumInfo) {
        self.root = vc
        self.album = album

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
                        self.album?.addImage(data: imgData, name: "")
                    }
                }
            }
        }

        album?.save()
        root?.dismiss(animated: true, completion: nil)
        root?.refresh()
    }
}
