//
//  ImageSlider.swift
//  picstore
//
//  Created by Aleksandr Kharkov on 08/07/2018.
//  Copyright © 2018 Oleksandr Kharkov. All rights reserved.
//

import UIKit

class ImageSliderItem: UIScrollView, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    /// representing page
    public var page: Int = -1
    /// position in scrollview
    public var pos: Int = 0

    public var onImageTap: (() -> Void)?

    private var imageView = UIImageView()
    private var tapDouble: UITapGestureRecognizer!
    private var tapOnce: UITapGestureRecognizer!

    public var image: UIImage? {
        set {
            imageView.image = newValue
            initSize()
        }
        get {
            return imageView.image
        }
    }

    init(position: Int) {
        super.init(frame: CGRect.null)

        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        addSubview(imageView)

        self.delegate = self
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.minimumZoomScale = 1.0
        self.maximumZoomScale = 2.0
        self.pos = position

        tapDouble = UITapGestureRecognizer(target: self, action: #selector(onDoubleTap))
        tapDouble.numberOfTapsRequired = 2
        tapDouble.delegate = self
        imageView.addGestureRecognizer(tapDouble)

        tapOnce = UITapGestureRecognizer(target: self, action: #selector(onOneTap))
        tapOnce.delegate = self
        imageView.addGestureRecognizer(tapOnce)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func initSize() {
        let size = calculateContentSize()

        if let image = imageView.image {
            self.maximumZoomScale = image.size.width / size.width
        }
        else {
            self.maximumZoomScale = 1.0
        }
        
        self.setZoomScale(1.0, animated: false)
        self.minimumZoomScale = 1.0

        imageView.frame = CGRect(origin: CGPoint.zero, size: size)
        centerContent()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        centerContent()
    }

    private func calculateContentSize() -> CGSize {
        guard let image = imageView.image else {
            return self.frame.size
        }

        let picRatio = image.size.width / image.size.height
        let screenRatio = self.frame.width / self.frame.height
        var viewSize: CGSize!

        if picRatio > screenRatio {
            viewSize = CGSize(width: self.frame.width, height: self.frame.width / picRatio)
        } else {
            viewSize = CGSize(width: self.frame.height * picRatio, height: self.frame.height)
        }

        return viewSize
    }

    private func centerContent() {
        let intendHorizon = max(0, (self.frame.width - imageView.frame.width) / 2)
        let intendVertical = max(0, (self.frame.height - imageView.frame.height) / 2)
        self.contentInset = UIEdgeInsets(top: intendVertical, left: intendHorizon, bottom: intendVertical, right: intendHorizon)
    }

    private func isZoomed() -> Bool {
        return self.zoomScale > self.minimumZoomScale
    }
    
    @objc func onDoubleTap(_ sender: UITapGestureRecognizer) {
        if isZoomed() {
            self.setZoomScale(self.minimumZoomScale, animated: true)
            return
        }

        let pos = sender.location(in: self.imageView)
        let zoomRect = zoomRectForScale(scale: maximumZoomScale, center: pos)
        zoom(to: zoomRect, animated: true)
    }
    
    private func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero

        zoomRect.size.height = self.imageView.frame.size.height / scale
        zoomRect.size.width  = self.imageView.frame.size.width / scale
        zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)

        return zoomRect
    }

    @objc func onOneTap() {
        onImageTap?()
    }
    
    // MARK: UIScrollViewDelegate

    internal func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }

    internal func scrollViewDidZoom(_ scrollView: UIScrollView) {
        centerContent()
    }

    // MARK: UIGestureRecognizerDelegate

    internal func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == tapDouble && otherGestureRecognizer == tapOnce {
            return true
        }

        return false
    }
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
    public var onImageTap: (() -> Void)?
    {
        didSet {
            for view in scrollView.subviews {
                let iview = view as! ImageSliderItem
                iview.onImageTap = onImageTap
            }
        }
    }

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
        addSubview(scrollView)

        /// current view + advance views in both sides
        let viewsCount = ADVANCE * 2 + 1

        for i in 0..<viewsCount {
            scrollView.addSubview(ImageSliderItem(position: i))
        }

        // setup timer
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // fixes the case when automaticallyAdjustsScrollViewInsets on parenting view controller is set to true
        //scrollView.contentInset = UIEdgeInsets.zero
        layoutScrollView()
    }

    private func layoutScrollView() {
        let size = self.bounds.size
        let count = scrollView.subviews.count
        
        scrollView.frame = self.bounds
        scrollView.contentSize = CGSize(width: size.width * CGFloat(count), height: size.height)

        layoutViews()
    }

    private func layoutViews() {
        let size = scrollView.frame.size

        for case let view as ImageSliderItem in scrollView.subviews {
            /// current page should be in ADVANCE position
            let page = getNormalizedPage((view.pos - ADVANCE) + pageCurrent)
            if view.page != page {
                view.page = page
                view.image = imageForPage?(page)
            }

            view.frame = CGRect(origin: CGPoint(x: size.width * CGFloat(view.pos), y: 0), size: size)
        }

        setScrollViewPosition(ADVANCE)
        
        for case let view as ImageSliderItem in scrollView.subviews {
            view.initSize()
        }
    }

    private func moveVeiws(with delta: Int) {
        for case let view as ImageSliderItem in scrollView.subviews {
            view.pos = getNormalizedPosition(view.pos - delta)
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


extension ImageSlider {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
    }
}
