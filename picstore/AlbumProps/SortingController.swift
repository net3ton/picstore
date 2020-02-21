//
//  SortingController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 10/01/2019.
//  Copyright © 2019 Oleksandr Kharkov. All rights reserved.
//

import UIKit

enum AlbumSort: Int {
    case None = 0
    case Views = 1
    case Rating = 2
}

let AlbumSortInfo: [(name: String, pred: NSSortDescriptor)] = [
    ("None", NSSortDescriptor(key: "pos", ascending: true)),
    ("Views", NSSortDescriptor(key: "views", ascending: true)),
    ("Rating", NSSortDescriptor(key: "rating", ascending: false))
]


class SortingController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    @IBOutlet weak var sortPicker: UIPickerView!

    public var onSortPicked: ((AlbumSort?) -> ())?
    public var initSort: AlbumSort!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sortPicker.dataSource = self
        sortPicker.delegate = self
        sortPicker.selectRow(initSort.rawValue, inComponent: 0, animated: false)
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return AlbumSortInfo.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return AlbumSortInfo[row].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        onSortPicked?(AlbumSort.init(rawValue: row))
    }
}
