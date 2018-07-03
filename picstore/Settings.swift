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

class AppSettings {
    var slideshowDelay: Int = ConfDefaults.SLIDE_DELAY
    var slideshowRandom: Bool = false

    var passType: EPasscodeType = .none
    var passTouchID: Bool = true

    struct ConfNames {
        static let SLIDE_DELAY = "slide-delay"
        static let SLIDE_RANDOM = "slide-random"

        static let PASS_TYPE = "pass-type"
        static let PASS_TOUCHID = "pass-touchid"
    }
    
    struct ConfDefaults {
        static let SLIDE_DELAY: Int = 3
    }
    
    func load() {
        let conf = UserDefaults.standard

        slideshowDelay = conf.object(forKey: ConfNames.SLIDE_DELAY) as? Int ?? ConfDefaults.SLIDE_DELAY
        slideshowRandom = conf.bool(forKey: ConfNames.SLIDE_RANDOM)

        passType = EPasscodeType(rawValue: conf.integer(forKey: ConfNames.PASS_TYPE))!
        passTouchID = conf.bool(forKey: ConfNames.PASS_TOUCHID)
    }

    func save() {
        let conf = UserDefaults.standard

        conf.set(slideshowDelay, forKey: ConfNames.SLIDE_DELAY)
        conf.set(slideshowRandom, forKey: ConfNames.SLIDE_RANDOM)

        conf.set(passType.rawValue, forKey: ConfNames.PASS_TYPE)
        conf.set(passTouchID, forKey: ConfNames.PASS_TOUCHID)
    }
}

let appSettings = AppSettings()
