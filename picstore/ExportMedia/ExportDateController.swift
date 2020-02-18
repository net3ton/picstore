//
//  ExportDateController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 15.02.2020.
//  Copyright © 2020 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class ExportDateController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var monthPicker: UIPickerView!
    
    public var onDatePicked: ((Date) -> Void)?
    
    public enum EDateType {
        case From
        case To
    }
    
    private var initDate: Date = Date()
    private var dateType: EDateType = .From
    private var monthsList: [(name: String, date: Date)] = []

    override func viewDidLoad()
    {
        super.viewDidLoad()

        datePicker.setDate(initDate, animated: true)
        datePicker.datePickerMode = .date
        datePicker.maximumDate = Date()
        
        fillMonthsList()
        let monthCount = GetMonthCountFrom(date: initDate)
        
        monthPicker.dataSource = self
        monthPicker.delegate = self
        monthPicker.selectRow(monthCount, inComponent: 0, animated: false)
    }

    public func setup(caption: String, date: Date, type: EDateType)
    {
        navigationItem.title = caption
        self.initDate = date
        self.dateType = type
    }

    func fillMonthsList()
    {
        let countFromNow = 10 * 12 // 10 years
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL YYYY"
        
        // this month's first day
        let calendar = Calendar.current
        var firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!
        
        monthsList.removeAll()
        for _ in 0  ..< countFromNow
        {
            var theDate = firstDay
            
            if dateType == .To {
                // get month's last day
                theDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDay)!
            }
            
            monthsList.append((name: formatter.string(from: theDate), date: theDate))
            
            // get first day in prev month
            firstDay = calendar.date(byAdding: DateComponents(month: -1), to: firstDay)!
        }
    }
    
    func GetMonthCountFrom(date: Date) -> Int
    {
        let calendar = Calendar.current
        let row = calendar.dateComponents([.month], from: date, to: Date()).month ?? 0
        return monthsList.count - row - 1
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        onDatePicked?(datePicker.date)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return monthsList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let ind = monthsList.count - row - 1
        return monthsList[ind].name
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let ind = monthsList.count - row - 1
        datePicker.setDate(monthsList[ind].date, animated: true)
    }
}
