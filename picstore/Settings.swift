//
//  Settings.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 19.04.2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import Foundation

enum EPasscodeType: Int {
    case none = 0
    case pin4 = 1
}

enum EDefaultScale: Int {
    case ImageFit = 0
    case ScreenFit = 1
}

let appInfoDefaultScale: [String] = [
    "ImageFit",
    "ScreenFit"
]

class AppSettings {
    var defaultScale: EDefaultScale = ConfDefaults.DEFAULT_SCALE

    var slideshowDelay: Int = ConfDefaults.SLIDE_DELAY
    var slideshowRandom: Bool = false

    var passType: EPasscodeType = .none
    var passTouchID: Bool = true

    struct ConfNames {
        static let DEFAULT_SCALE = "default-scale"
        
        static let SLIDE_DELAY = "slide-delay"
        static let SLIDE_RANDOM = "slide-random"

        static let PASS_TYPE = "pass-type"
        static let PASS_TOUCHID = "pass-touchid"
    }
    
    struct ConfDefaults {
        static let DEFAULT_SCALE: EDefaultScale = .ImageFit
        static let SLIDE_DELAY: Int = 3
    }
    
    func load() {
        let conf = UserDefaults.standard
        
        defaultScale = EDefaultScale(rawValue: conf.integer(forKey: ConfNames.DEFAULT_SCALE)) ?? ConfDefaults.DEFAULT_SCALE
        
        slideshowDelay = conf.object(forKey: ConfNames.SLIDE_DELAY) as? Int ?? ConfDefaults.SLIDE_DELAY
        slideshowRandom = conf.bool(forKey: ConfNames.SLIDE_RANDOM)

        passType = EPasscodeType(rawValue: conf.integer(forKey: ConfNames.PASS_TYPE))!
        passTouchID = conf.bool(forKey: ConfNames.PASS_TOUCHID)
    }

    func save() {
        let conf = UserDefaults.standard

        conf.set(defaultScale.rawValue, forKey: ConfNames.DEFAULT_SCALE)
        
        conf.set(slideshowDelay, forKey: ConfNames.SLIDE_DELAY)
        conf.set(slideshowRandom, forKey: ConfNames.SLIDE_RANDOM)

        conf.set(passType.rawValue, forKey: ConfNames.PASS_TYPE)
        conf.set(passTouchID, forKey: ConfNames.PASS_TOUCHID)
    }
}

let appSettings = AppSettings()
