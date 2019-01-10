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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLabels()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        appSettings.save()
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
    }

    @IBAction func onSlideshowRandom(_ sender: UISwitch) {
        appSettings.slideshowRandom = sender.isOn
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
        if indexPath.section == 0 && indexPath.row == 0 {
            let pinView = LockScreen()
            present(pinView, animated: true)
        }
        */

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
}
