//
//  ImageSlider.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 08/07/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class ImageSliderItem: UIImageView {
    /// representing page
    public var page: Int = -1
    /// position in scrollview
    public var pos: Int = 0
}

class ImageSlider: UIView {
    private let scrollView = UIScrollView()
    //private var slideshowTimer: Timer?

    /// count of advance views in both sides
    /// and also current view (middle) index
    private let ADVANCE = 1

    public var pageCurrent: Int = 0
    public var pagesCount = 5

    public var imageForPage: ((_ page: Int) -> UIImage?)?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        autoresizesSubviews = true
        clipsToBounds = true

        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.bounces = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.autoresizingMask = self.autoresizingMask
        addSubview(scrollView)

        /// current view + advance views in both sides
        let viewsCount = ADVANCE * 2 + 1

        for i in 0..<viewsCount {
            let view = ImageSliderItem()
            view.contentMode = .scaleAspectFit
            view.pos = i
            scrollView.addSubview(view)
        }

        // setup timer
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        print("layoutSubviews")
        // fixes the case when automaticallyAdjustsScrollViewInsets on parenting view controller is set to true
        scrollView.contentInset = UIEdgeInsets.zero
        layoutScrollView()
    }

    private func layoutScrollView() {
        let size = scrollView.frame.size
        let count = scrollView.subviews.count

        //UIView.animate(withDuration: 0.4) {
        //    self.scrollView.frame = self.bounds
        //    self.scrollView.contentSize = CGSize(width: size.width * CGFloat(count), height: size.height)
        //}

        scrollView.frame = self.bounds
        scrollView.contentSize = CGSize(width: size.width * CGFloat(count), height: size.height)

        layoutViews()
    }

    private func layoutViews() {
        let size = scrollView.frame.size

        for view in scrollView.subviews {
            let iview = view as! ImageSliderItem
            iview.frame = CGRect(origin: CGPoint(x: size.width * CGFloat(iview.pos), y: 0), size: size)

            /// current page should be in ADVANCE position
            let page = getNormalizedPage((iview.pos - ADVANCE) + pageCurrent)
            if iview.page != page {
                iview.page = page
                iview.image = imageForPage?(page)
            }
        }

        setScrollViewPosition(ADVANCE)
    }

    private func moveVeiws(with delta: Int) {
        for view in scrollView.subviews {
            let iview = view as! ImageSliderItem
            iview.pos = getNormalizedPosition(iview.pos - delta)
        }

        layoutViews()
    }

    private func normalizeCicledPos(_ pos: Int, count: Int) -> Int {
        if count <= 0 {
            return 0
        }

        let norm = pos % count
        if norm < 0 {
            return count + norm
        }

        return norm
    }
    
    private func getNormalizedPage(_ page: Int) -> Int {
        return normalizeCicledPos(page, count: pagesCount)
    }

    private func getNormalizedPosition(_ pos: Int) -> Int {
        return normalizeCicledPos(pos, count: scrollView.subviews.count)
    }

    private func getScrollViewPosition() -> Int {
        let size = scrollView.frame.size
        return size.width > 0 ? Int(scrollView.contentOffset.x + size.width / 2) / Int(size.width) : 0
    }

    private func setScrollViewPosition(_ pos: Int) {
        let origin = CGPoint(x: scrollView.frame.size.width * CGFloat(pos), y: 0)
        let rect = CGRect(origin: origin, size: scrollView.frame.size)

        scrollView.scrollRectToVisible(rect, animated: false)
    }
}


extension ImageSlider: UIScrollViewDelegate {
    open func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // stop timer
    }
    
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pos = getScrollViewPosition()
        let delta = pos - ADVANCE

        if delta != 0 {
            pageCurrent = getNormalizedPage(pageCurrent + delta)
            moveVeiws(with: delta)
        }
    }
}
