//
//  DelayController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 10/01/2019.
//  Copyright © 2019 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class DelayController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var delayPicker: UIPickerView!
    
    private let MAX_DELAY = 15
    
    override func viewDidLoad() {
        super.viewDidLoad()

        delayPicker.dataSource = self
        delayPicker.delegate = self
        delayPicker.selectRow(appSettings.slideshowDelay-1, inComponent: 0, animated: false)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return MAX_DELAY
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String.init(format: "%d sec", row+1)
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        appSettings.slideshowDelay = row+1
    }
}
