//
//  ItemController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 07/07/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class ItemController: UIViewController {
    @IBOutlet weak var itemSlider: ImageSlider!

    private var toolbar: UIToolbar!
    private var navbar: UINavigationBar!
    
    private var fullscreen = true
    private var statusBarHidden = false
    private var items: [ImageObject] = []
    private var startPage = 0
    
    private var initPanPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var initViewSize: CGSize!

    override func viewDidLoad() {
        super.viewDidLoad()

        itemSlider.pagesCount = self.items.count
        itemSlider.pageCurrent = startPage
        itemSlider.imageForPage = getImageFor
        itemSlider.onImageTap = onImageTap
        itemSlider.backgroundColor = UIColor.black
        view.backgroundColor = UIColor.black
        
        initViewSize = self.view.frame.size
        
        initToolbar()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onPanGesture))
        view.addGestureRecognizer(panGesture)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.initViewSize = size
    }
    
    @objc func onPanGesture(_ sender: UIPanGestureRecognizer) {
        let touchPoint = sender.location(in: self.view.window)
        let distance = touchPoint.y - initPanPoint.y
        
        if sender.state == UIGestureRecognizerState.began {
            initPanPoint = touchPoint
        }
        else if sender.state == UIGestureRecognizerState.changed {
            if distance > 0 {
                let height = initViewSize.height - distance
                let mul = height / initViewSize.height
                let width = initViewSize.width * mul
                let x = (initViewSize.width - width) / 2
                
                self.view.frame = CGRect(x: x, y: distance, width: width, height: height)
                self.view.alpha = mul
            }
            else if distance < 0 {
                let point = CGPoint(x: 0, y: max(-100, distance))
                self.itemSlider.frame = CGRect(origin: point, size: self.itemSlider.frame.size)
            }
        }
        else if sender.state == UIGestureRecognizerState.ended || sender.state == UIGestureRecognizerState.cancelled {
            if distance < -100 {
                likeItem()
            }
            
            if distance > 100 {
                self.dismiss(animated: true, completion: nil)
            }
            else {
                UIView.animate(withDuration: 0.3) {
                    self.view.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: self.initViewSize)
                    self.view.alpha = 1.0
                }
            }
            
            UIView.animate(withDuration: 0.3) {
                self.itemSlider.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: self.itemSlider.frame.size)
            }
        }
    }
    
    private func likeItem() {
        let item = items[itemSlider.pageCurrent]
        item.rating = (item.rating > 0) ? 0 : 1
        item.save()
        
        print("like it =", item.rating)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        statusBarHidden = true
        setNeedsStatusBarAppearanceUpdate()
    }

    public func setup(items: [ImageObject], start: Int) {
        self.items = items
        self.startPage = start
    }

    private func getImageFor(page: Int) -> UIImage? {
        print("getting image for page: ", page)
        return self.items[page].image
    }

    private func onImageTap() {
        toggleFullscreen()
    }

    private func toggleFullscreen() {
        fullscreen = !fullscreen
        itemSlider.stopSlideshow()
        
        UIView.animate(withDuration: 0.2) {
            self.toolbar.alpha = self.fullscreen ? 0.0 : 1.0
            self.navbar.alpha = self.fullscreen ? 0.0 : 1.0
        }
    }

    override open var prefersStatusBarHidden: Bool {
        return statusBarHidden
        //return false
    }

    override func viewDidLayoutSubviews() {
        navbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 45)
        toolbar.frame = CGRect(x: 0, y: view.frame.height - 45, width: view.frame.width, height: 45)
    }
    
    private func initToolbar() {
        navbar = UINavigationBar()
        navbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 45)
        view.addSubview(navbar)
        
        let navItem = UINavigationItem()
        navItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(onBack))
        navbar.items = [navItem]
        navbar.alpha = 0.0

        toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: view.frame.height - 45, width: view.frame.width, height: 45)
        view.addSubview(toolbar)
        
        let btnDelete = UIBarButtonItem(image: UIImage(named: "delete"), style: .plain, target: self, action: #selector(onDelete))
        let btnSlideshow = UIBarButtonItem(image: UIImage(named: "play"), style: .plain, target: self, action: #selector(onSlideshow))
        let btnExport = UIBarButtonItem(image: UIImage(named: "export"), style: .plain, target: self, action: #selector(onExport))
        
        let sep1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sep2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [btnDelete, sep1, btnSlideshow, sep2, btnExport]
        toolbar.alpha = 0.0
    }

    @objc func onBack() {
        dismiss(animated: true)
    }
    
    @objc func onDelete() {
    }

    @objc func onCopy() {
    }

    @objc func onExport() {
    }
    
    @objc func onSlideshow() {
        toggleFullscreen()
        itemSlider.startSlideshow(interval: appSettings.slideshowDelay)
    }
}
