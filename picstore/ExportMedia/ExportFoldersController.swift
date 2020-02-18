//
//  ExportFoldersController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 15.02.2020.
//  Copyright © 2020 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class ExportFoldersController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var pickerSubfolders: UIPickerView!
    
    public var onItemPicked: ((EExportSubfolders) -> Void)?
    private var initItem: EExportSubfolders = .Months

    override func viewDidLoad() {
        super.viewDidLoad()

        pickerSubfolders.dataSource = self
        pickerSubfolders.delegate = self
        pickerSubfolders.selectRow(self.initItem.rawValue, inComponent: 0, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        let selectedRow = pickerSubfolders.selectedRow(inComponent: 0)
        let selectedItem = EExportSubfolders(rawValue: selectedRow)!
        onItemPicked?(selectedItem)
    }
    
    public func setup(item: EExportSubfolders)
    {
        self.initItem = item
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return EExportSubfolders.Count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return EExportSubfolders.GetTitle(for: EExportSubfolders(rawValue: row))
    }
}
