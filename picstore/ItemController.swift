//
//  ItemController.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 07/07/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class ItemController: UIViewController {
    //@IBOutlet weak var itemSlider: ImageSlider!

    private var toolbar: UIToolbar!
    private var navbar: UINavigationBar!
    private var navitem: UINavigationItem!
    private var btnShuffle: UIBarButtonItem!
    
    private var statusBarHidden: Bool = false {
        didSet{
            UIView.animate(withDuration: 0.2) { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
                self.updateViewConstraints()
            }
         }
    }
    
    private var fullscreen = true
    //private var statusBarHidden = false
    private var items: [ImageObject] = []
    private var itemInds: [Int] = []
    private var startPage = 0
    
    private var itemSlider: ImageSlider!
    private var initPanPoint: CGPoint = CGPoint(x: 0, y: 0)
    private var initViewSize: CGSize!

    override func viewDidLoad() {
        super.viewDidLoad()

        itemSlider = ImageSlider(frame: view.frame)
        view.addSubview(itemSlider)
        
        view.backgroundColor = UIColor.black
        initViewSize = self.view.frame.size
        initToolbar()
        
        itemSlider.imageForPage = getImageFor
        itemSlider.onImageTap = onImageTap
        itemSlider.onImageView = onImageView
        itemSlider.backgroundColor = UIColor.black
        itemSlider.setup(count: items.count, current: startPage)
        
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
    
    private var currentItem: ImageObject {
        return items[itemInds[itemSlider.page]]
    }
    
    private func getImageFor(page: Int) -> UIImage? {
        print("getting image for page: ", page)
        return items[itemInds[page]].image
    }
    
    private func getRatingIcon(rating: Int16) -> UIImage? {
        let iconLike = UIImage(named: "like")
        
        if rating > 0 {
            return iconLike
        }
        
        return nil
    }
    
    private func likeItem() {
        let item = currentItem
        item.rating = (item.rating > 0) ? 0 : 1
        item.save()
        
        //print("like it =", item.rating)
        updateRatingIcon()
    }
    
    private func countItemViews() {
        let item = currentItem
        item.views += 1
        item.save()
        
        //print("views =", item.views)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        statusBarHidden = true
        //setNeedsStatusBarAppearanceUpdate()
        
        itemsShuffle(on: appSettings.slideshowRandom)
    }

    public func setup(items: [ImageObject], start: Int) {
        self.items = items
        self.startPage = start
        
        self.itemInds.removeAll()
        for i in 0..<items.count {
            self.itemInds.append(i)
        }
    }
    
    private func itemsShuffle(on: Bool) {
        let curpage = itemInds[itemSlider.page]
        
        if on {
            itemInds.shuffle()
            if let pos = itemInds.firstIndex(of: curpage) {
                itemInds[pos] = itemInds[itemSlider.page]
                itemInds[itemSlider.page] = curpage
            }
            
            btnShuffle.tintColor = toolbar.items![0].tintColor
        }
        else {
            itemInds.sort()
            itemSlider.setPage(curpage)
            
            btnShuffle.tintColor = UIColor(ciColor: .gray)
        }
    }

    private func onImageTap() {
        toggleFullscreen()
    }

    private func onImageView(page: Int)
    {
        countItemViews()
        updateRatingIcon()
        navitem.title = String.init(format: "%i / %i", itemInds[page]+1, self.items.count)
        
    }
    
    private func updateRatingIcon() {
        navitem.rightBarButtonItem?.image = getRatingIcon(rating: currentItem.rating)
    }
    
    private func toggleFullscreen() {
        statusBarHidden = !statusBarHidden
        fullscreen = !fullscreen
        itemSlider.stopSlideshow()
        
        UIView.animate(withDuration: 0.2) {
            self.toolbar.alpha = self.fullscreen ? 0.0 : 1.0
            self.navbar.alpha = self.fullscreen ? 0.0 : 1.0
           // self.setNeedsStatusBarAppearanceUpdate()
        }
        
        viewDidLayoutSubviews()
    }

    override open var prefersStatusBarHidden: Bool {
        return statusBarHidden
        //return false
        //return fullscreen
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override func viewDidLayoutSubviews() {
        navbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 45)
        toolbar.frame = CGRect(x: 0, y: view.frame.height - 45, width: view.frame.width, height: 45)
    }
    
    private func initToolbar() {
        navbar = UINavigationBar()
        navbar.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 45)
        view.addSubview(navbar)
        
        navitem = UINavigationItem()
        navitem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(onBack))
        navitem.rightBarButtonItem = UIBarButtonItem(image: nil, style: .plain, target: nil, action: nil)
        navbar.items = [navitem]
        navbar.alpha = 0.0

        toolbar = UIToolbar()
        toolbar.frame = CGRect(x: 0, y: view.frame.height - 45, width: view.frame.width, height: 45)
        view.addSubview(toolbar)
        
        let btnDelete = UIBarButtonItem(image: UIImage(named: "delete"), style: .plain, target: self, action: #selector(onDelete))
        let btnSlideshow = UIBarButtonItem(image: UIImage(named: "play"), style: .plain, target: self, action: #selector(onSlideshow))
        let btnExport = UIBarButtonItem(image: UIImage(named: "export"), style: .plain, target: self, action: #selector(onExport))
        btnShuffle = UIBarButtonItem(image: UIImage(named: "shuffle"), style: .plain, target: self, action: #selector(onShuffle))
        btnShuffle.tintColor = UIColor(ciColor: .gray)
        
        let sep1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sep2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sepp = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        sepp.width = 20

        toolbar.items = [btnDelete, sep1, btnSlideshow, sepp, btnShuffle, sep2, btnExport]
        toolbar.alpha = 0.0
    }

    @objc func onBack() {
        dismiss(animated: true)
    }
    
    @objc func onDelete() {
    }

    @objc func onExport() {
    }
    
    @objc func onSlideshow() {
        toggleFullscreen()
        itemSlider.startSlideshow(interval: appSettings.slideshowDelay)
    }
    
    @objc func onShuffle() {
        appSettings.slideshowRandom = !appSettings.slideshowRandom
        itemsShuffle(on: appSettings.slideshowRandom)
        itemSlider.invalidatePages()
    }
}
