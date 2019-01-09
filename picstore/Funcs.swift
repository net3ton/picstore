//
//  Funcs.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 07/11/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit

func top_view_controller(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
    if let navigationController = controller as? UINavigationController {
        return top_view_controller(controller: navigationController.visibleViewController)
    }
    if let tabController = controller as? UITabBarController {
        if let selected = tabController.selectedViewController {
            return top_view_controller(controller: selected)
        }
    }
    if let presented = controller?.presentedViewController {
        return top_view_controller(controller: presented)
    }
    return controller
}
