//
//  LockController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 03/07/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit
import SmileLock

class LockScreen: UIViewController, PasswordInputCompleteProtocol {
    private var passwordView: PasswordContainerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 13.0, *) {
            self.isModalInPresentation = true
        }
        
        passwordView = PasswordContainerView.create(withDigit: 4)
        passwordView.delegate = self
        passwordView.touchAuthenticationEnabled = true
        
        passwordView.tintColor = UIColor.darkGray
        passwordView.highlightedColor = UIColor(red: 0.808, green: 0.753, blue: 0.459, alpha: 1.0)
        
        let posx = (view.bounds.width - passwordView.bounds.width) / 2
        let posy = (view.bounds.height - passwordView.bounds.height) / 2
        passwordView.frame.origin = CGPoint(x: posx, y: posy)
        
        view.backgroundColor = UIColor.white
        view.addSubview(passwordView)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    static func showModal() {
        if let topView = top_view_controller() {
            if topView is LockScreen {
                return
            }

            topView.present(LockScreen(), animated: true)
        }
    }
    
    func passwordInputComplete(_ passwordContainerView: PasswordContainerView, input: String) {
        if validation(input) {
            validationSuccess()
        } else {
            validationFail()
        }
    }
    
    func touchAuthenticationComplete(_ passwordContainerView: PasswordContainerView, success: Bool, error: Error?) {
        if success {
            self.validationSuccess()
        } else {
            passwordContainerView.clearInput()
        }
    }
    
    func validation(_ input: String) -> Bool {
        return input == "1224"
    }
    
    func validationSuccess() {
        print("success!")
        dismiss(animated: true, completion: nil)
    }
    
    func validationFail() {
        print("failure!")
        passwordView.wrongPassword()
    }
}
