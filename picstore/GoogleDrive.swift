//
//  googleDrive.swift
//  moneytravel
//
//  Created by Aleksandr Kharkov on 21/06/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit
import GoogleSignIn
import GoogleAPIClientForREST

let appGoogleDrive = GoogleDrive()

class GoogleDrive: NSObject, GIDSignInDelegate, GIDSignInUIDelegate {
    private let driveService = GTLRDriveService()
    private var uiroot: UIViewController?
    private var authCompletion: (() -> Void)?

    public var onFileDownloaded: ((Data, String) -> Void)?

    public func start() {
        GIDSignIn.sharedInstance().clientID = "586434866308-u600eh9utsdgclqbvv9vb3rr4h5bf010.apps.googleusercontent.com"
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().scopes = [kGTLRAuthScopeDrive]
        GIDSignIn.sharedInstance().signInSilently()
    }

    public func handle(url: URL!, sourceApplication: String!, annotation: Any!) -> Bool {
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }

    public func signIn(vc: UIViewController, completion: @escaping (() -> Void)) {
        uiroot = vc
        authCompletion = completion
        GIDSignIn.sharedInstance().signIn()
    }

    public func signOut(completion: @escaping (() -> Void)) {
        authCompletion = completion
        GIDSignIn.sharedInstance().disconnect()
    }

    public func isLogined() -> Bool {
        return GIDSignIn.sharedInstance().hasAuthInKeychain()
    }

    public func showFilePicker(vc: UIViewController) {
        uiroot = vc

        let picker = GoogleDrivePicker(drive: driveService)
        picker.selectedHandler = onPickedFile

        let navController = UINavigationController(rootViewController: picker)
        vc.present(navController, animated: true, completion: nil)
    }

    private func onPickedFile(id: String, name: String) {
        print(String(format: "[Google Drive] File picked: %@ (%@)", name, id))

        downloadFile(fileId: id) { fdata in
            if let data = fdata {
                self.onFileDownloaded?(data, name)
            }
        }
    }

    public func downloadFile(fileId: String, completion: @escaping ((Data?) -> Void)) {
        let waitView = self.createWaitView(title: "Downloading")
        uiroot?.present(waitView, animated: true)

        let queryGet = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileId)
        let task = self.driveService.executeQuery(queryGet) { (ticket, result, error) -> Void in
            if error != nil {
                print("[Google Drive] Failed to download file! Error: " + error!.localizedDescription)
                waitView.dismiss(animated: true)
                completion(nil)
                return
            }
            
            if let file = result as? GTLRDataObject {
                print("[Google Drive] File size: " + String(file.data.count))
                waitView.dismiss(animated: true)
                completion(file.data)
                return
            }
            
            print("[Google Drive] Failed to download file!")
            waitView.dismiss(animated: true)
            completion(nil)
        }
        
        waitView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            task.cancel()
        }))
        
        task.objectFetcher?.receivedProgressBlock = { last, total in
            DispatchQueue.main.async() {
                waitView.message = String(format: "%0.1f Mb", Double(total) / 1048576)
            }
        }
    }

    private func createWaitView(title: String) -> UIAlertController {
        let waitView = UIAlertController(title: title, message: "", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating()
        waitView.view.addSubview(loadingIndicator)
        
        return waitView
    }

    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("[Google Drive] Failed to sign in! ERROR: " + error.localizedDescription)
            return
        }

        print("[Google Drive] sign in")
        driveService.authorizer = user.authentication.fetcherAuthorizer()
        //print(driveService.authorizer)

        authCompletion?()
        authCompletion = nil
    }

    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            print("[Google Drive] Failed to sign out! ERROR: " + error.localizedDescription)
            return
        }

        print("[Google Drive] sign out")
        driveService.authorizer = nil

        authCompletion?()
        authCompletion = nil
    }

    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        uiroot?.present(viewController, animated: true)
    }

    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        viewController.dismiss(animated: true)
    }
}


class GoogleDriveItemHeader: UITableViewHeaderFooterView {
    public static let ID = "GoogleDriveItemHeader"
    public static let HEIGHT: CGFloat = 40
    public var caption: UILabel!

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        caption = UILabel(frame: bounds)
        caption.textAlignment = .center
        caption.textColor = UIColor.darkGray
        addSubview(caption)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        caption.frame = self.bounds
    }
}

class GoogleDriveItemCell: UITableViewCell {
    static public let ID = "GoogleDriveItemCell"

    public var fileName: UILabel!
    public var fileSize: UILabel!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        fileName = UILabel(frame: bounds)
        fileName.textAlignment = .left
        fileName.font = UIFont.systemFont(ofSize: 16)
        addSubview(fileName)

        fileSize = UILabel(frame: bounds)
        fileSize.textAlignment = .left
        fileSize.font = UIFont.systemFont(ofSize: 12)
        fileSize.textColor = UIColor.darkGray
        addSubview(fileSize)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if (fileSize.text?.isEmpty)! {
            fileName.frame = CGRect(x: 14, y: 0, width: self.bounds.width, height: self.bounds.height)
        }
        else {
            fileName.frame = CGRect(x: 14, y: 0, width: self.bounds.width - 14, height: self.bounds.height - 14)
            fileSize.frame = CGRect(x: 14, y: self.bounds.height - 16, width: self.bounds.width - 14, height: 12)
        }
    }

    public func initColor(isFolder: Bool) {
        if isFolder {
            backgroundColor = UIColor(red:0.92, green:0.91, blue:0.91, alpha:1.0)
        }
        else {
            backgroundColor = UIColor.white
        }
    }

    public func setFileSize(bytes: Int) {
        if bytes <= 0 {
            fileSize.text = ""
        }
        else if bytes < 1024 {
            fileSize.text = String(format: "%i Bytes", bytes)
        }
        else if bytes < 1048576 {
            fileSize.text = String(format: "%0.1f Kb", Double(bytes) / 1024)
        }
        else {
            fileSize.text = String(format: "%0.1f Mb", Double(bytes) / 1048576)
        }
    }
}

class GoogleDrivePicker: UITableViewController {
    private var waitView: UIAlertController?
    private var driveService: GTLRDriveService
    private var queryTask: GTLRServiceTicket?

    private struct FolderInfo {
        var id: String
        var name: String
    }

    private var folders: [FolderInfo] = []
    private var items: [GTLRDrive_File] = []
    
    private let ROOT_Folder = "root"
    private let MIME_Folder = "application/vnd.google-apps.folder"

    public var selectedHandler: ((String, String) -> Void)?

    init(drive: GTLRDriveService) {
        self.driveService = drive
        super.init(style: .grouped)
        self.tableView.separatorInset = .zero
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(GoogleDriveItemCell.self, forCellReuseIdentifier: GoogleDriveItemCell.ID)
        tableView.register(GoogleDriveItemHeader.self, forHeaderFooterViewReuseIdentifier: GoogleDriveItemHeader.ID)

        navigationItem.title = "Google Drive"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(doCancel))
    }

    private func refresh() {
        tableView.reloadData()

        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(doBack))
        navigationItem.leftBarButtonItem = (folders.count > 1) ? backButton : nil
    }

    @objc func doCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func doBack() {
        openBackFolder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        openFolder(id: ROOT_Folder, name: "")
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: GoogleDriveItemHeader.ID) as! GoogleDriveItemHeader
        header.caption.text = folders.last?.name ?? ""
        return header
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return GoogleDriveItemHeader.HEIGHT
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: GoogleDriveItemCell.ID, for: indexPath) as! GoogleDriveItemCell
        let item = items[indexPath.row]

        cell.initColor(isFolder: item.mimeType == MIME_Folder)
        cell.setFileSize(bytes: Int(truncating: item.size ?? 0))
        cell.fileName.text = item.name

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        if item.mimeType == MIME_Folder {
            openFolder(id: item.identifier!, name: item.name!)
        }
        else {
            dismiss(animated: true, completion: nil)
            selectedHandler?(item.identifier!, item.name!)
        }
    }

    private func openFolder(id: String, name: String) {
        folders.append(FolderInfo(id: id, name: name))
        showWait()

        let querySearch = GTLRDriveQuery_FilesList.query()
        querySearch.q = String.init(format: "'%@' in parents", id)
        querySearch.spaces = "drive"
        querySearch.fields = "nextPageToken, files(id, name, size, mimeType)"
        
        queryTask = driveService.executeQuery(querySearch) { (ticket, result, error) -> Void in
            if error == nil {
                if let filesList = result as? GTLRDrive_FileList {
                    if let files = filesList.files {
                        self.items.removeAll()
                        for file in files {
                            self.items.append(file)
                        }

                        self.items.sort(by: { (fa, fb) -> Bool in
                            if fa.mimeType == self.MIME_Folder && fb.mimeType != self.MIME_Folder {
                                return true
                            }

                            return fa.name! < fb.name!
                        })
                    }
                }
            }
            else {
                print("[Google Drive] Failed to get filelist! Error: " + error!.localizedDescription)
            }

            self.hideWait()
            self.queryTask = nil
            self.refresh()
        }
    }
    
    private func openBackFolder() {
        if folders.count > 1 {
            folders.removeLast()
            let folder = folders.popLast()!
            openFolder(id: folder.id, name: folder.name)
        }
    }

    private func showWait() {
        waitView = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating()
        waitView?.view.addSubview(loadingIndicator)

        waitView?.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
            if let task = self.queryTask {
                task.cancel()
                self.queryTask = nil
                self.refresh()
            }
        }))

        present(waitView!, animated: true, completion: nil)
    }

    private func hideWait() {
        waitView?.dismiss(animated: true, completion: nil)
    }
}
