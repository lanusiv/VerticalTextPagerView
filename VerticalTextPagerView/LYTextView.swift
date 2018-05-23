//
//  LYTextView.swift
//  VerticalTextPagerView
//
//  Created by Leray Lanusiv on 5/22/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class LYTextView: UIScrollView {

    // MARK: - Properties
    
    // MARK:  page properties
    var pageDisplayed: Int = 0
    var pageCount: Int = 0
    
    // MARK: coretext properties
    let textStorage = NSMutableAttributedString(string: "")
    var framesetter: CTFramesetter!
    var attrString: NSAttributedString? {
        didSet {
            loadText(withAttrString: attrString!)
        }
    }
    var stringAttributes: [NSAttributedStringKey : Any] = [:]
    
    var imageDict: [[String : Any]]?
    
    var isVerticalLayout = true
    var contentView: UIView
    var pageWidth: CGFloat!
    
    var scrollFeedbackFromOtherControl: Bool = true
    
    
    
    override init(frame: CGRect) {
        contentView = UIView(frame: frame)
        super.init(frame: frame)
        initSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        contentView = UIView(coder: aDecoder)!
        super.init(coder: aDecoder)
        initSetup()
    }
    
    private func initSetup() {
        self.isPagingEnabled = true
//        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        
        self.pageWidth = self.bounds.width
        contentView.frame = self.bounds
        self.addSubview(contentView)
        self.delegate = self
    }
    
    
    func loadText(withAttrString attrString: NSAttributedString) {
        var frameAttributes: [NSAttributedStringKey : Any] = [:]
        let attrString = NSMutableAttributedString(attributedString: attrString)
        if isVerticalLayout {
            frameAttributes = [kCTFrameProgressionAttributeName as NSAttributedStringKey: NSNumber(value: CTFrameProgression.rightToLeft.rawValue)]
            attrString.addAttributes([.verticalGlyphForm: NSNumber(value: true)], range: NSRange(location: 0, length: attrString.length))
        } else {
            attrString.addAttributes([.verticalGlyphForm: NSNumber(value: false)], range: NSRange(location: 0, length: attrString.length))
        }
        self.textStorage.setAttributedString(attrString)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        
        var pageView: LYCoreTextView
        var textPos = 0
        var pageIndex: CGFloat = 0
        
        while textPos < attrString.length {
            let path = CGMutablePath()
            path.addRect(self.bounds.insetBy(dx: 20, dy: 10))
            
            let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, frameAttributes as CFDictionary)
            let offsetX = isVerticalLayout ? -pageIndex * pageWidth : pageIndex * pageWidth
            let pageFrame = self.bounds.offsetBy(dx: offsetX, dy: 0)
            
            pageView = LYCoreTextView(frame: pageFrame, ctframe: ctframe)
            contentView.addSubview(pageView)
            pageView.name = "page # \(pageIndex)"
            
            let frameRange = CTFrameGetVisibleStringRange(ctframe)
            textPos += frameRange.length
            
            pageIndex += 1
        }
        
        self.pageCount = Int(pageIndex)
        
        contentSize = CGSize(width: pageIndex * pageWidth,
                             height: self.bounds.height)
        
        print("loadPage, contentView.frame", contentView.frame, "contentView.bounds", contentView.bounds)
        
        if isVerticalLayout {
            let translationX = CGFloat(pageIndex - 1) * pageWidth
            // make negative origin.x positive
            for view in contentView.subviews {
                view.frame.origin.x += translationX
            }
            print("loadPage, translationX", translationX)
//            contentView.transform = CGAffineTransform(translationX: translationX, y: 0.0)
            self.setContentOffset(CGPoint(x: self.contentSize.width - self.bounds.width, y: 0), animated: false)
            
            contentView.frame.size.width = contentSize.width
        }
        
        self.scrollFeedbackFromOtherControl = true
        
        self.pageDisplayed = 0
        if let page = contentView.subviews[pageDisplayed] as? LYCoreTextView {
            self.pageSelected(page)
        }
    }
    
    private func setPage(_ pageToDisplay: Int) {
        var pageToDisplay = pageToDisplay
        if isVerticalLayout {
            pageToDisplay = pageCount - pageToDisplay - 1
        }
        if pageToDisplay == self.pageDisplayed || pageToDisplay >= pageCount || pageToDisplay < 0 {
            return
        }
        self.pageDisplayed = pageToDisplay
        if let page = contentView.subviews[pageToDisplay] as? LYCoreTextView {
            self.pageSelected(page)
        }
    }
    
    func pageSelected(_ page: LYCoreTextView) {
        print("pageDisplayed", pageDisplayed, "page name: ", page.name)
        let attributedString = self.textStorage
        page.textStorage.setAttributedString(attributedString)
        page.addSelectionView()
    }
}


extension LYTextView: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        print("scrollViewDidScroll ")
        if scrollFeedbackFromOtherControl {
            return
        }
        
        let pageWidth = self.frame.size.width
        let page = Int(floor((self.contentOffset.x - pageWidth / 2) / pageWidth)) + 1
        self.setPage(page)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        //        print("scrollViewDidEndScrollingAnimation ")
        let pageWidth = self.frame.size.width
        let page = Int(floor((self.contentOffset.x - pageWidth / 2) / pageWidth)) + 1
        self.setPage(page)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        //        print("scrollViewWillBeginDragging")
        self.scrollFeedbackFromOtherControl = false
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        //        print("scrollViewWillBeginDragging")
        self.scrollFeedbackFromOtherControl = true
    }
}



class LYCoreTextView: UIView, TextViewSelection {
    
    var frames: [CTFrame]?
    
    var textStorage = NSMutableAttributedString(string: "")
    
    var isVerticalLayout: Bool = true
    
    var selectionView: SelectionView?
    
    // test
    var name = "not defined"
    
    
    // MARK: - Properties
    var ctFrame: CTFrame!
    var images: [(image: UIImage, frame: CGRect)] = []
    
    // MARK: - Initializers
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    required init(frame: CGRect, ctframe: CTFrame) {
        super.init(frame: frame)
        self.ctFrame = ctframe
        backgroundColor = .white
        
        self.frames = [ctframe]
    }
    
    func addSelectionView() {
        if self.selectionView == nil {
            let selectionView = SelectionView.initSelectionView(self)
            print("self.frame", self.frame, "self.bounds", self.bounds)
//            selectionView.backgroundColor = UIColor.green.withAlphaComponent(0.1)
            self.selectionView = selectionView
        }
    }
    
    // MARK: - Life Cycle
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        
        CTFrameDraw(ctFrame, context)
        
        for imageData in images {
            if let image = imageData.image.cgImage {
                let imgBounds = imageData.frame
                context.draw(image, in: imgBounds)
            }
        }
    }
}
