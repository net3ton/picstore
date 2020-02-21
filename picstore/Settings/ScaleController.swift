//
//  ScaleController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 11/01/2019.
//  Copyright © 2019 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class ScaleController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var scalePicker: UIPickerView!

    override func viewDidLoad() {
        super.viewDidLoad()

        scalePicker.dataSource = self
        scalePicker.delegate = self
        scalePicker.selectRow(appSettings.defaultScale.rawValue, inComponent: 0, animated: false)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return appInfoDefaultScale.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return appInfoDefaultScale[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let scale = EDefaultScale(rawValue: row) {
            appSettings.defaultScale = scale
        }
    }
}
