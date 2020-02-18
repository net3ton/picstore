//
//  ExportSettings.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 15.02.2020.
//  Copyright © 2020 Oleksandr Kharkov. All rights reserved.
//

import Foundation

public enum EExportSubfolders: Int {
    case None = 0
    case Days = 1
    case Months = 2
    
    // helpers
    static let Count = 3
    static func GetTitle(for value: EExportSubfolders?) -> String {
        let enumTitles: [EExportSubfolders: String] = [
            .None: "None",
            .Days: "For every day",
            .Months: "For every month"
        ]
        
        guard let val = value else {
            return ""
        }
        
        return enumTitles[val] ?? ""
    }
}


public class ExportSettings {
    var folderName: String = "Export"
    
    var jpegQuality: Float = 0.85
    var createSubFolders: EExportSubfolders = .Months
    var notPhotosAside: Bool = true
    
    var from: Date = Date()
    {
        didSet {
            if from > to {
                to = from
            }
        }
    }
    
    var to: Date = Date()
    {
        didSet {
            if to < from {
                from = to
            }
        }
    }
}
