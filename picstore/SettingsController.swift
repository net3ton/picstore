//
//  SettingsController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 06.04.2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit
import SmileLock

class SettingsController: UITableViewController {
    @IBOutlet weak var labelPasscode: UILabel!
    @IBOutlet weak var labelSlideshowDelay: UILabel!
    @IBOutlet weak var checkTouchID: UISwitch!
    @IBOutlet weak var checkSlideshowRandom: UISwitch!
    @IBOutlet weak var labelGoogleDrive: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func updateLabels() {
        labelSlideshowDelay.text = "\(appSettings.slideshowDelay) sec."
        labelPasscode.text = "none"

        checkTouchID.isOn = appSettings.passTouchID
        checkSlideshowRandom.isOn = appSettings.slideshowRandom

        labelGoogleDrive.text = appGoogleDrive.isLogined() ? "Sign out" : "Sign in"
    }
    
    @IBAction func onTouchIDEnabled(_ sender: UISwitch) {
        appSettings.passTouchID = sender.isOn
        appSettings.save()
    }

    @IBAction func onSlideshowRandom(_ sender: UISwitch) {
        appSettings.slideshowRandom = sender.isOn
        appSettings.save()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0 {
            let pinView = LockScreen()
            present(pinView, animated: true)
        }

        if indexPath.section == 1 && indexPath.row == 0 {
            let alert = UIAlertController(title: "Delay Interval", message: "", preferredStyle: .alert)
            alert.addTextField { (textField) in
                textField.text = String(appSettings.slideshowDelay)
            }
 
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                let textfield = alert.textFields?.first
                if let delay = Int(textfield?.text ?? "") {
                    appSettings.slideshowDelay = delay
                    self.updateLabels()
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: {
                tableView.deselectRow(at: indexPath, animated: true)
            })
        }

        if indexPath.section == 2 && indexPath.row == 0 {
            if appGoogleDrive.isLogined() {
                appGoogleDrive.signOut() {
                    self.updateLabels()
                }
            }
            else {
                appGoogleDrive.signIn(vc: self) {
                    self.updateLabels()
                }
            }
        }
    }

    //override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //}
}
