//
//  WaitView.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 15.02.2020.
//  Copyright © 2020 Oleksandr Kharkov. All rights reserved.
//

import UIKit

public func createWaitModal(title: String) -> UIAlertController {
    let waitView = UIAlertController(title: title, message: "", preferredStyle: .alert)
    
    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
    loadingIndicator.hidesWhenStopped = true
    loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
    loadingIndicator.startAnimating()
    waitView.view.addSubview(loadingIndicator)
    
    return waitView
}


public func presentWaitModal(title: String) -> UIAlertController? {
    if let topView = top_view_controller() {
        let waitView = createWaitModal(title: title)
        topView.present(waitView, animated: true)
        return waitView
    }
    
    return nil
}
