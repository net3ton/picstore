//
//  TitleBar.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 10/07/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class Titlebar: UIView {
    private var labelCaption = UILabel()
    private var labelInfo = UILabel()
    
    private var tapState = false
    private let COLOR_LINK = UIColor(red: 0.231, green: 0.576, blue: 0.984, alpha: 1.0)
    
    public var onTapHandler: (() -> Void)? {
        didSet {
            labelCaption.textColor = (onTapHandler == nil) ? UIColor.black : COLOR_LINK
        }
    }
    
    public var caption: String? {
        set {
            labelCaption.text = newValue
        }
        get {
            return labelCaption.text
        }
    }

    public var count: Int {
        set {
            labelInfo.text = String(format: "%i items", newValue)
        }
        get {
            return 0
        }
    }

    public var selected: Int {
        set {
            labelInfo.text = String(format: "%i selected", newValue)
        }
        get {
            return 0
        }
    }
    
    init() {
        let width = 200
        let height = 32

        super.init(frame: CGRect(x: 0, y: 0, width: width, height: height))
        self.isUserInteractionEnabled = true
        
        labelCaption.font = UIFont.boldSystemFont(ofSize: 18)
        labelCaption.textAlignment = .center
        labelCaption.frame = CGRect(x: 0, y: 0, width: width, height: 18)
        self.addSubview(labelCaption)
        
        labelInfo.font = UIFont.systemFont(ofSize: 12)
        labelInfo.textAlignment = .center
        labelInfo.frame = CGRect(x: 0, y: height - 12, width: width, height: 12)
        self.addSubview(labelInfo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func processTap(pressed: Bool) {
        if onTapHandler != nil {
            labelCaption.alpha = pressed ? 0.4 : 1.0
            tapState = pressed
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        processTap(pressed: true)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        let inView = self.bounds.contains(touches.first!.location(in: self))
        if !inView {
            processTap(pressed: false)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let prevState = tapState
        processTap(pressed: false)

        if prevState {
            onTapHandler?()
        }
    }
}
