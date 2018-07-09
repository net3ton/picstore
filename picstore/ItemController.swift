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

    private var fullscreen = false
    private var items: [ImageObject] = []
    private var startPage = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        itemSlider.pagesCount = self.items.count
        itemSlider.pageCurrent = startPage
        itemSlider.imageForPage = getImageFor

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onViewTap))
        itemSlider.addGestureRecognizer(tapGesture)

        initToolbar()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    public func setup(items: [ImageObject], start: Int) {
        self.items = items
        self.startPage = start
    }

    //override func didReceiveMemoryWarning() {
    //    super.didReceiveMemoryWarning()
    //}

    private func getImageFor(page: Int) -> UIImage? {
        print("getting image for page: ", page)
        return self.items[page].image
    }

    @objc func onViewTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .recognized {
            fullscreen = !fullscreen
            toggleFullscreen()
        }
    }

    private func toggleFullscreen() {
        navigationController?.setToolbarHidden(fullscreen, animated: true)
        navigationController?.setNavigationBarHidden(fullscreen, animated: true)

        UIView.animate(withDuration: 0.3) {
            self.itemSlider.backgroundColor = self.fullscreen ? UIColor.black : UIColor.white
        }
    }

    override open var prefersStatusBarHidden: Bool {
        return fullscreen
    }

    private func initToolbar() {
        let btnDelete = UIBarButtonItem(image: UIImage(named: "delete"), style: .plain, target: self, action: #selector(onDelete))
        let btnCopy = UIBarButtonItem(image: UIImage(named: "copy"), style: .plain, target: self, action: #selector(onCopy))
        let btnExport = UIBarButtonItem(image: UIImage(named: "export"), style: .plain, target: self, action: #selector(onExport))
        let btnInfo = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(onInfo))

        let sep1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sep2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sep3 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.toolbarItems = [btnDelete, sep1, btnCopy, sep2, btnInfo, sep3, btnExport]

        navigationController?.setToolbarHidden(false, animated: true)
    }

    @objc func onDelete() {
    }

    @objc func onCopy() {
    }

    @objc func onExport() {
    }

    @objc func onInfo() {
    }
}
