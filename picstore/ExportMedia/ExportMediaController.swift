//
//  ExportAssetsController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 08.02.2020.
//  Copyright © 2020 Oleksandr Kharkov. All rights reserved.
//

import UIKit

let exportSettings = ExportSettings()

class ExportMediaController: UITableViewController, ExportMediaNotify {
    
    @IBOutlet weak var labelDateFrom: UILabel!
    @IBOutlet weak var labelDateTo: UILabel!
    @IBOutlet weak var labelExportQuality: UILabel!
    @IBOutlet weak var labelSubfolders: UILabel!
    
    @IBOutlet weak var switchNotPhotosAside: UISwitch!

    private var waitView: UIAlertController?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationItem.title = "Export Media"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(exportAssets))
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        updateLabels()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func updateLabels()
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd LLLL yyyy"

        labelDateFrom.text = formatter.string(from: exportSettings.from)
        labelDateTo.text = formatter.string(from: exportSettings.to)
        
        labelSubfolders.text = EExportSubfolders.GetTitle(for: exportSettings.createSubFolders)
        labelExportQuality.text = String(format: "%d%%", Int(exportSettings.jpegQuality * 100))
        
        switchNotPhotosAside.isOn = exportSettings.isNotPhotosAside
    }
    
    @IBAction func onExportQualityChanged(_ sender: UISlider)
    {
        exportSettings.jpegQuality = sender.value
        print("values:", sender.value)
        updateLabels()
    }
    
    @IBAction func onNotPhotosAsideChanged(_ sender: UISwitch)
    {
        exportSettings.isNotPhotosAside = sender.isOn
        updateLabels()
    }
    
    @objc func exportAssets()
    {
        waitView = createWaitModal(title: "Export")
        present(waitView!, animated: true)
        
        DispatchQueue.global(qos: .background).async {
            exportMediaToDocs(with: exportSettings, notifier: self)
            
            DispatchQueue.main.async {
                self.waitView?.dismiss(animated: true)
            }
        }
    }
    
    func onExportMediaStart() {
        print("Export start.")
    }
    
    func onExportMediaStep(step: Int, count: Int) {
        DispatchQueue.main.async {
            self.waitView?.message = String(format: "%d / %d", step, count)
        }
    }
    
    func onExportMediaFinished(size: Int) {
        print("Export done. Size:", size)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "export-date-from"
        {
            let datePicker = segue.destination as! ExportDateController
            
            datePicker.setup(caption: "Export From", date: exportSettings.from, type: .From)
            datePicker.onDatePicked = { date in
                exportSettings.from = date
                self.updateLabels()
            }
        }
        else if segue.identifier == "export-date-to"
        {
            let datePicker = segue.destination as! ExportDateController
            
            datePicker.setup(caption: "Export To", date: exportSettings.to, type: .To)
            datePicker.onDatePicked = { date in
                exportSettings.to = date
                self.updateLabels()
            }
        }
        else if segue.identifier == "export-subfolders"
        {
            let subfoldersPicker = segue.destination as! ExportFoldersController
            
            subfoldersPicker.setup(item: exportSettings.createSubFolders)
            subfoldersPicker.onItemPicked = { item in
                exportSettings.createSubFolders = item
                self.updateLabels()
            }
        }
    }
}
