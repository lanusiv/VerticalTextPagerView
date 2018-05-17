//
//  PagerView.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/28/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

protocol DocumentPager {
    
    // Data source and entry point for PagerView
    // Reset scroll view with new document and delegate
    func reset(doc: AttributedStringDoc)
    
    // current displayed page
    func pageSelected(page: CoreTextView)
    
    // Change to next/previous page
    func pageUp()
    func pageDown()
    
    // Set currently displayed page
    func setPage(_ pageToDisplay: Int)
    
    // Re-layout text for whole document
    func relayoutDoc()
    
    // Redraw currently displayed page on load (does not re-layout text)
    func refreshPage()
    
    // Redraw all pages on load (does not re-layout text), used for highlighting
    func refreshDoc()
    
    // Mark page as needing refresh on next load
    func pageNeedsDisplay(_ pageNumber: Int)
    
    // Get page for given document text string offset
    func pageForStringOffset(_ offset: Int) -> Int
    
    // Get document text string range for current page
    func stringRangeForCurrentPage() -> NSRange?
    
    // Selection handling (for user frame selections)
    func addSelectionRange(range: NSRange)
    func clearSelectionRanges()
    
    // Change document with overriding font/font features
    func fontFamilyChange(fontFamilyName: String)
    func optionsChange(optionName: String)

}

// MARK: - CoreTextViewFrameInfo

class CoreTextViewFrameInfo: NSObject {
    
    
    var frameType: ASDFrameType = .typeDefault
    var path: CGPath?
    var stringOffsetForSetter: Int = 0
    var setter: CTFramesetter?
    var frame: CTFrame?
    var stringRange: NSRange = NSRange(location: 0, length: 0)
    var value: Any? // store text, which may be any of there kind of texts: AttributedStringDoc for ASDFrameType.textFlow, NSAttributedString for ASDFrameType.text, and file path(string) for ASDFrameType.picture
    
    override init() {
        super.init()
    }
    
    convenience init(type: ASDFrameType, andPath path: CGPath) {
        self.init()
        
        self.frameType = type
        self.path = path
        
        self.stringRange.location = 0
        self.stringRange.length = 0
        self.stringOffsetForSetter = 0
    }
    
    override var description: String {
        return "<CoreTextViewFrameInfo> type: \(self.frameType), path: \(String(describing: self.path))"
    }
    
    func setFrameSetterForStringOffset(stringOffset: Int, previousFreeFlowFrame: CoreTextViewFrameInfo?) -> Int {
        
        guard let doc = self.value as? AttributedStringDoc, let path = self.path else {
            return 0
        }
        var iWidth: CGFloat = 0.0
        var helveticaLineHeight: CGFloat = 0.0
        
        
        // Estimate how much text we can fit into the frame. We do so by getting the glyph metrics for the letter 'x' in Helvetica
        // and see how many of these glyphs we can fit into the frame. Obviously this is not exact (and a bit more precise would be
        // to use the font being used in the attributed string), but this is a conservative first approximation
        let frameRect: CGRect = path.boundingBox
        if (iWidth == 0) {
            // First time here, so use Helvetica 'x' to approximate as described above
            //            const UniChar iChar = 'x';
            
            var iChar: UniChar = UniChar(65)
            var iGlyph: CGGlyph = CGGlyph()
            let font = CTFontCreateWithName("Helvetica" as CFString, 12.0, nil)
            if CTFontGetGlyphsForCharacters(font, &iChar, &iGlyph, 1) {
                var iBoundRect: CGRect = .zero
                CTFontGetBoundingRectsForGlyphs(font, .horizontal, &iGlyph, &iBoundRect, 1)
                iWidth = iBoundRect.size.width
            } else {
                iWidth = 3.0    // should have found the glyph width - be conservative and assume something small
            }
            helveticaLineHeight = CTFontGetAscent(font) + CTFontGetDescent(font) + CTFontGetLeading(font)
        }
        
        var maxLength = 0
        if let length = doc.attributedString?.length {
            maxLength = length - stringOffset
        }
        
        var len = Int((frameRect.size.width / iWidth) * (frameRect.size.height / helveticaLineHeight))
        if (len > maxLength) {
            len = maxLength
        }
        var range: NSRange = NSMakeRange(stringOffset, len)
        var framesetter: CTFramesetter?
        var workFrame: CTFrame?
        var visibleRange: CFRange = CFRangeMake(0, 0)
        
        var frameAttributes: [NSAttributedStringKey : Any] = [:]
        if doc.verticalOrientation {
            frameAttributes[kCTFrameProgressionAttributeName as NSAttributedStringKey] = NSNumber(value: CTFrameProgression.rightToLeft.rawValue)
        }
        
        // Figure out if the previous setter can be used to render the current frame
        if let previousFreeFlowFrame = previousFreeFlowFrame, let prevFrame = previousFreeFlowFrame.frame {
            let prevVisRange: CFRange = CTFrameGetVisibleStringRange(prevFrame)
            let prevStringRange: CFRange = CTFrameGetStringRange(prevFrame)
            
            var newFrameRange: CFRange = CFRangeMake(prevVisRange.location + prevVisRange.length, 0)
            newFrameRange.length = (prevStringRange.location + prevStringRange.length) - newFrameRange.location
            if newFrameRange.length > 0, let setter = previousFreeFlowFrame.setter {
                // Generate CTFrame using previous setter to get visible range
                framesetter = setter
                workFrame = CTFramesetterCreateFrame(framesetter!, newFrameRange, path, frameAttributes as CFDictionary)
                visibleRange = CTFrameGetVisibleStringRange(workFrame!)
                if (visibleRange.length < newFrameRange.length || newFrameRange.length >= maxLength) {
                    self.stringOffsetForSetter = previousFreeFlowFrame.stringOffsetForSetter
                }
                else {
                    // Will need to use new framesetter below
                    framesetter = nil
                    workFrame = nil
                }
            }
        }
        
        if (framesetter == nil) {
            repeat {
                // Create new setter and frame to get visible range
                let attributedString = doc.attributedString?.attributedSubstring(from: range)
                framesetter = CTFramesetterCreateWithAttributedString(attributedString! as CFAttributedString)
                workFrame = CTFramesetterCreateFrame(framesetter!, CFRangeMake(0, 0), path, frameAttributes as CFDictionary)
                visibleRange = CTFrameGetVisibleStringRange(workFrame!)
                
                if (visibleRange.length < range.length || range.length >= maxLength) {
                    self.stringOffsetForSetter = range.location
                    break
                }
                
                range.length *= 2 // pad
                if range.length > maxLength {
                    range.length = maxLength
                }
                
            } while (true)
        }
        
        self.setter = framesetter
        self.frame = workFrame
        
        self.stringRange.location = stringOffset
        self.stringRange.length = visibleRange.length
        
        return visibleRange.length + stringOffset
    }
    
    func refreshTextFrame() {
        guard let doc = self.value as? AttributedStringDoc, let attrString = doc.attributedString?.attributedSubstring(from: self.stringRange) else {
            return
        }
        
        if (!(frameType == .textFlow || frameType == .text)) {
            return
        }
        
        var isVertical = false
        
        if frameType == .textFlow {
            isVertical = doc.verticalOrientation
        }
        
        // Create setter with current attributed string
        self.setter = CTFramesetterCreateWithAttributedString(attrString)
        
        var frameAttributes: [NSAttributedStringKey : Any] = [:]
        if (isVertical) {
            frameAttributes[kCTFrameProgressionAttributeName as NSAttributedStringKey] = NSNumber(value: CTFrameProgression.rightToLeft.rawValue)
        }
        
        // Create and cache CTFrame for current path
        self.frame = CTFramesetterCreateFrame(self.setter!, CFRangeMake(0, 0), self.path!, frameAttributes as CFDictionary)
    }
    
}

// MARK: - CoreTextViewPageInfo

class CoreTextViewPageInfo: NSObject {
    
    // MARK: - Properities
    
    var pageNumber: Int = 0
    var framesToDraw: [CoreTextViewFrameInfo]?
    var rangeStart: Int = 0
    var rangeEnd: Int = 0
    var lastFreeFlowFrame: CoreTextViewFrameInfo?
    var pageLayer: CALayer?
    var needsRedrawOnLoad = false
    var needsReLayout = false
    
    // MARK: - Initializers
    override init() {
        super.init()
    }
//
    convenience init(frames: [CoreTextViewFrameInfo], pageNumber: Int, rangeStart: Int, rangeEnd: Int, layer: CALayer) {
        self.init()
        
        self.pageNumber = pageNumber
        self.framesToDraw = frames
        self.rangeStart = rangeStart
        self.rangeEnd = rangeEnd
        self.pageLayer = layer
    }
    
    convenience init(layer: CALayer, pageNumber: Int) {
        self.init()
        
        self.pageLayer = layer
        self.pageNumber = pageNumber
    }
    
}

// MARK: - CoreTextViewDraw is our UIView subclass that handles drawing

class CoreTextViewDraw: UIView {
    var target: CoreTextView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(initWithView view: CoreTextView) {
        self.init(frame: CGRect.zero)  // we don't need this view to display, if we did , it would prevent scrollView from scrolling by user drag events
        self.target = view
    }
    
    override func draw(_ layer: CALayer, in ctx: CGContext) {
        self.target.drawIntoLayer(layer: layer, inContext: ctx)
    }
}

// MARK: - AsyncLayerOperation implementation

class AsyncLayerOperation: Operation {
    
    // MARK: - Properties
    var scrollView: PagerView?
    var nextPageToLoad: Int = .max
    
    override init() {
        fatalError("must be initialized with a layer (use initWithLayer()")
    }
    
    init(withPagerView pagerView: PagerView, forNextPageToLoad page: Int) {
        super.init()
        self.scrollView = pagerView
        self.nextPageToLoad = page
    }
    
    static func operationWithPagerView(_ pagerView: PagerView, forNextPageToLoad page: Int) -> AsyncLayerOperation {
        return AsyncLayerOperation(withPagerView: pagerView, forNextPageToLoad: page)
    }
    
    override func main() {
        if self.nextPageToLoad < 0 {
            print("Do we not have any content to display?")
            return
        }
        guard let scrollView = self.scrollView else {
            return
        }
        let currentPage = self.nextPageToLoad
        if let startPosition = scrollView.pagesDict[currentPage + 1]?.rangeEnd, let doc = scrollView.document, let attributedString = doc.attributedString {
            if startPosition < attributedString.length || doc.framesForPage(page: currentPage) != nil {
                if let ctView = scrollView.loadPage(pageToLoad: currentPage), let pageInfo = ctView.pageInfo {
                    let layer  = pageInfo.pageLayer
                    CATransaction.begin()
                    ctView.layoutOnlyOnDraw = true
                    layer?.display()
                    ctView.layoutOnlyOnDraw = false
                    CATransaction.commit()
                    pageInfo.pageLayer?.delegate = nil
                    pageInfo.pageLayer = nil
                    
                    scrollView.addPageToScrollView()
                    scrollView.loadAsyncPageAfter(currentPage: currentPage)
                }
            }
            
        }
        
    }
}

// MARK: - PagerView page index
let prevCoreTextView = 0
let currCoreTextView = 1
let nextCoreTextView = 2

let coreTextViewCount = 3

// MARK: - PagerView

class PagerView: UIScrollView, DocumentPager {
    
    var frames: [CTFrame]?
    
    var textStorge = NSMutableAttributedString(string: "")
    
    var isVerticalLayout: Bool = true
    
    
    // MARK: - Properities
    
    var document: AttributedStringDoc!
    var pagesDict: [Int : CoreTextViewPageInfo] = [:]
    var selectionRanges: [NSRange]?
    var pageCount: Int = 0
    var pageDisplayed: Int = 0
    var pageViews: [CoreTextView] = [CoreTextView](repeating: CoreTextView(), count: 4)
    
    var operationQueue: OperationQueue!
    
    var scrollFeedbackFromOtherControl: Bool!
    
    // MARK: - initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
//        reset(doc: nil, withDelegate: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        document = nil
        
        pageDisplayed = 0
        pageCount = 0
        
        selectionRanges = nil
        
        pagesDict = [:]
        
        // Alloc cached current and prev/next CoreTextViews
        pageViews[prevCoreTextView] = CoreTextView(scrollView: self)
        pageViews[currCoreTextView] = CoreTextView(scrollView: self)
        pageViews[nextCoreTextView] = CoreTextView(scrollView: self)
        
        self.isPagingEnabled = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        self.scrollsToTop = false
        
        // init our asynch operation queue for secondary thread rendering
//        operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue = OperationQueue()
        
    }
    
    /*
     override func letkeFromNib() {
        let layer = self.layer
        self.reset(doc: nil, withDelegate: nil)
        // clear the view's background color so that our background
        // fits within the rounded border
        let backgroundColor = self.backgroundColor?.cgColor
        self.backgroundColor = .clear
        layer.backgroundColor = backgroundColor
        
        self.setNeedsDisplay()
    }
    */
    
    // MARK: - Entry point for PagerView
    
    func reset(doc: AttributedStringDoc) {
        // Don't reset until any pending operations on previous doc are done
        //        [operationQueue waitUntilAllOperationsAreFinished];
        self.operationQueue.waitUntilAllOperationsAreFinished()
        
        self.delegate = self
        
        self.pagesDict.removeAll()
        
        self.document = doc
        
        if doc.verticalOrientation {
            // rotate by 180 degree to support right-to-left text layout
            self.transform = CGAffineTransform(rotationAngle: .pi)
        } else {
            self.transform = .identity
        }
        
        self.scrollFeedbackFromOtherControl = true // ???
        
        self.pageDisplayed = 0
        self.pageCount = 0
        self.selectionRanges = nil
        
        // Remove any existing cached CoreTextViews
        for idx in 0 ..< coreTextViewCount {
            pageViews[idx].removeFromSuperview()
            pageViews[idx] = CoreTextView(scrollView: self)
        }
        
        // Load first page of doc and asynch load next page (if any)
        _ = self.loadPage(pageToLoad: 0)
        _ = self.loadPage(pageToLoad: 1)
        self.loadAsyncPageAfter(currentPage: 1)
        
        self.setNeedsDisplay()
        
        // collect selection info
        let ctView = pageViews[currCoreTextView]
        self.pageSelected(page: ctView)
        
    }
    
    // MARK: - pager view methods
    
    func loadPage(pageToLoad: Int) -> CoreTextView? {
//        guard let document = self.document else {
//            return nil
//        }
        // Sanity check page index
        if (pageToLoad < 0) {
            return nil
        }
        
        if (pageToLoad > 0) {
            if (pageToLoad > pageCount) {
                return nil
            }
            
            if let rangeMax = pagesDict[pageToLoad - 1]?.rangeEnd, let attrString = document.attributedString {
                if rangeMax >= attrString.length && document.framesForPage(page: pageToLoad) == nil {
                    return nil
                }
            } else {
                if document.framesForPage(page: pageToLoad) == nil {
                    return nil
                }
            }
        }
        
        var isNotScratch = true
        var ctView: CoreTextView
        // Find cached CoreTextView for page index, if applicable
        if (pageToLoad == pageDisplayed) {
            ctView = pageViews[currCoreTextView]
        }
        else if (pageToLoad < pageDisplayed && (pageToLoad + 1) == pageDisplayed) {
            ctView = pageViews[prevCoreTextView]
        }
        else if (pageToLoad > pageDisplayed && (pageToLoad - 1) == pageDisplayed) {
            ctView = pageViews[nextCoreTextView]
        }
        else {
            // Need to create new CoreTextView
            ctView = CoreTextView()
            isNotScratch = false
        }
        
        if let pageInfo = ctView.pageInfo, pageInfo.needsReLayout {
            pageInfo.needsRedrawOnLoad = true
        }
        
//        if (ctView.pageInfo != nil && ctView.pageInfo.needsRedrawOnLoad == false) {
        if let pageInfo = ctView.pageInfo, pageInfo.needsReLayout == false {
            return ctView
        }
        
        // If we've already loaded & drawn the page, return the CoreTextView
        let pageToLoadNum = pageToLoad
        var pageInfoEntry = self.pagesDict[pageToLoadNum]
        if let pageInfoEntry = pageInfoEntry {
            ctView.pageInfo = pageInfoEntry
            if (pageInfoEntry.needsRedrawOnLoad == false && pageInfoEntry.needsReLayout == false) {
                return ctView
            }
        }
        
        // Create and setup CALayer for our CoreTextView
        
        let layer: CALayer = CALayer()
        //        theLayer = [CALayer layer];
        layer.contentsScale = UIScreen.main.scale
        
        let bounds = ctView.bounds
        layer.position = CGPoint(x: bounds.size.width/2.0, y: bounds.size.height/2.0)
        
        layer.bounds = bounds
        layer.backgroundColor = UIColor.clear.cgColor
        
        //        [theLayer setDelegate: ctView.caLayerDrawDelegate];
        layer.delegate = ctView.caLayerDrawDelegate
        
        let viewLayer = ctView.layer
        if let subLayers = viewLayer.sublayers {
            // Remove any previous CALayer
            for subLayer in subLayers {
                subLayer.removeFromSuperlayer()
            }
        }
        ctView.layer.addSublayer(layer)
        
        layer.name = String(describing: pageToLoad)
        
        if /*let pageInfo = ctView.pageInfo, pageInfo.needsReLayout ||*/ pageInfoEntry == nil {
            // Need to re-layout text for new CoreTextViewPageInfo
            let newEntry = pageInfoEntry == nil
            pageInfoEntry = CoreTextViewPageInfo(layer: layer, pageNumber: pageToLoad)
            //            [pagesInfo setObject:pageInfoEntry forKey:pageToLoadNum];
            self.pagesDict[pageToLoadNum] = pageInfoEntry
            if newEntry {
                pageInfoEntry?.needsReLayout = true
            }
        }
        
        ctView.pageInfo = pageInfoEntry
        
        if isNotScratch {
            // Re-using a CoreTextView, so refresh
            ctView.setNeedsDisplay()
            layer.setNeedsDisplay()
            layer.display()  // displays the layer and fills out the rest of the info for the pageInfoEntry
            
            ctView.removeFromSuperview()
            
            var frame = self.frame
            frame.origin.x = frame.size.width * CGFloat(pageToLoad)
            frame.origin.y = 0
            ctView.frame = frame
            self.addSubview(ctView)
            
            if pageToLoad == pageCount {
                self.addPageToScrollView()// only add a page to the scrollView when it is a brand new page and it is fully drawn
            }
        }
        
        return ctView
    }
    
    func loadAsyncPageAfter(currentPage: Int) {
        operationQueue.addOperation(AsyncLayerOperation.operationWithPagerView(self, forNextPageToLoad: currentPage))
    }
    
    func addPageToScrollView() {
        self.pageCount += 1
        // Note that self.contentSize likely triggers a call into the delegate method scrollViewDidScroll
        self.contentSize = CGSize(width: self.frame.size.width * CGFloat(self.pageCount), height: self.frame.size.height)
    }
    
    private func switchPageMovingUp(up: Bool) {
        let newPage = self.pageDisplayed + (up ? 1 : -1)
        let curPageDisplayed = self.pageDisplayed
        
        if newPage >= 0 && newPage < self.pageCount {
            self.setPage(newPage)
        }
        
        if curPageDisplayed != self.pageDisplayed {
            var frame = self.frame
            frame.origin.x = frame.size.width * CGFloat(self.pageDisplayed)
            frame.origin.y = 0
            self.scrollRectToVisible(frame, animated: true)
        }
    }
    
    private func pageSharesAPreviousPageFrameSetter(_ pageNumber: Int) -> Bool {
        // Determine if page shared a framesetter from a previous page
        if pageNumber < 1 {
            return false
        }
        
        let page = self.pagesDict[pageNumber]
        
        let framesToDraw = page?.framesToDraw
        // If page has no frames to draw, it will not be using a framesetter at all
        if framesToDraw == nil {
            return false
        }
        
        // see if the setter for first free flow text frame of this page matches the setter from a previous page last free flow frame
        //        for (NSUInteger idx=0; idx<[framesToDraw count]; idx++) {
        for idx in 0 ..< framesToDraw!.count {
            let frameInfo = framesToDraw![idx]
            if frameInfo.frameType == .textFlow {
                var curPrevPage = pageNumber - 1
                repeat {
                    let prevPage = pagesDict[curPrevPage]//[pagesInfo objectForKey:[NSNumber numberWithInt:curPrevPage]];
                    if prevPage == nil {
                        return false
                    }
                    
                    if prevPage!.lastFreeFlowFrame != nil {
                        return prevPage!.lastFreeFlowFrame!.setter == frameInfo.setter
                    }
                    curPrevPage -= 1
                } while (curPrevPage > 0)
                
                break // we've already examined the first free flow text frame for this page - no point in going on
            }
        }
        
        return false
    }
    
    private func relayoutDocFromPage(pageStart: Int) {
        // It may be the case that the page that we wish to start laying out from shares the framesetter
        // with a previous page. If that is the case, then it is best to start laying out from the first
        // page that contains that framesetter. For example, if we change the font in page 9 and it shares
        // the framesetter with page 8, if we don't start laying out from page 8, page 9 will not get the
        // new font as it is using the cached framesetter from page 8 to draw
        var pageStart = pageStart
        while (self.pageSharesAPreviousPageFrameSetter(pageStart)) {
            pageStart -= 1
        }
        
        // If the current page displayed exceeds pageStart, then we need to reload all those pages first
        // synchrounously. Any remainging pages can be loaded asyncronously
        var page = self.pagesDict[self.pageDisplayed]//[pagesInfo objectForKey:[NSNumber numberWithInt:pageDisplayed]];
        let offsetToStopAt = page?.rangeStart
        var pageToStopAt = Int.max
        if offsetToStopAt == 0 && document.framesForPage(page: pageDisplayed) != nil {
            pageToStopAt = pageDisplayed
        }
        
        // Remove any pages we need to relayout from memory
        var pagesToRemove = [Int]()
        for (pageNumObj, _) in pagesDict {
            page = pagesDict[pageNumObj]
            if (page?.pageNumber)! >= pageStart {
                let aLayer = page?.pageLayer
                if aLayer != nil {
                    page?.pageLayer = nil
                }
                page?.needsReLayout = true
                pagesToRemove.append(pageNumObj)
            }
        }
        for pageNumObj in pagesToRemove {
            self.pagesDict.removeValue(forKey: pageNumObj)
            self.pageCount -= 1
        }
        
        if pageStart < self.pageDisplayed {
            // process any pages we need to load synchronously
            var curPage = pageStart
            
            while (true) {
                pageDisplayed = curPage + 1   // forces loadPage to draw the page into prevCoreTextView
                _ = self.loadPage(pageToLoad: curPage)
                guard let page = self.pagesDict[curPage] else { break }
                
                curPage += 1
                // NOTE!!! page can be nil
                if curPage == pageToStopAt || page.rangeEnd > offsetToStopAt! {
                    break
                }
            }
            
            self.pageDisplayed = curPage + 1    // forces loadPage to draw the page into prevCoreTextView
            _ = self.loadPage(pageToLoad: curPage)
            
            self.pageDisplayed = .max  // force reload of surrounding pages around curPage into appropriate views
            self.setPage(curPage - 1)
        } else {
            // easy case - we are just relaying out from the current page displayed
            _ = self.loadPage(pageToLoad: self.pageDisplayed - 1)
            _ = self.loadPage(pageToLoad: self.pageDisplayed)
            _ = self.loadPage(pageToLoad: self.pageDisplayed + 1)
        }
        
        self.loadAsyncPageAfter(currentPage: self.pageCount - 1)
        
        // update the scroll view to the appropriate page
        var frame = self.frame
        frame.origin.x = frame.size.width * CGFloat(pageDisplayed)
        frame.origin.y = 0
        self.scrollRectToVisible(frame, animated: false)
        
        self.setNeedsDisplay()
    }
    
    // MARK: - DocumentPager implementation
    
    func pageSelected(page: CoreTextView) {
        print("pageSelected, page number", self.pageDisplayed)
//        SelectionView.initSelectionView(self, bounds: page.frame)
//
        if let attributedString = self.document.attributedString {
            //            print("PageViewer, attributedString", attributedString.string)
            page.textStorage.setAttributedString(attributedString)
            page.addSelectionView()
        }
//        self.frames = page.frames
    }
    
    func pageUp() {
        switchPageMovingUp(up: true)
    }
    
    func pageDown() {
        switchPageMovingUp(up: false)
    }
    
    func relayoutDoc() {
        // Do not do relayout untill all secondary thread operations are finished
//        [operationQueue waitUntilAllOperationsAreFinished];
        self.operationQueue.waitUntilAllOperationsAreFinished()
        
        // Re-layout of cached doc text requires recreating all cached CoreTextViews
        for idx in 0 ..< coreTextViewCount {
            let ctView = pageViews[idx]
            
            if ctView.pageInfo != nil {
                ctView.pageInfo!.pageLayer = nil
            }
            ctView.removeFromSuperview()
            
            pageViews[idx] = CoreTextView(scrollView: self)
        }
        
        // Flag for relayout of all pages
        self.relayoutDocFromPage(pageStart: 0)
    }
    
    func refreshPage() {
        // Mark current page as needing redisplay
        if let pageInfo = self.pagesDict[self.pageDisplayed] {
            pageInfo.needsRedrawOnLoad = true
            _ = self.loadPage(pageToLoad: self.pageDisplayed)
            self.setNeedsDisplay()
        }
    }
    
    func refreshDoc() {
        // Mark all pages in doc as needing redisplay
        for (pageNumber, _) in pagesDict {
            if let pageInfo = pagesDict[pageNumber] {
                pageInfo.needsRedrawOnLoad = true
            }
        }
        
        // Re-load current and adjacent cached pages
        _ = self.loadPage(pageToLoad: pageDisplayed - 1)
        _ = self.loadPage(pageToLoad: pageDisplayed)
        _ = self.loadPage(pageToLoad: pageDisplayed + 1)
        
        self.setNeedsDisplay()
    }
    
    func pageNeedsDisplay(_ pageNumber: Int) {
        // Flag that page needs redisplay via its CoreTextViewPageInfo
        if self.pagesDict.count > pageNumber {
            self.pagesDict[pageNumber]?.needsRedrawOnLoad = true
        }
    }
    
    func setPage(_ pageToDisplay: Int) {
        if pageToDisplay == pageDisplayed {
            return
        } else if pageToDisplay == pageDisplayed + 1 {
            // Display next page view, which we should already have cached
            pageViews[prevCoreTextView].removeFromSuperview()
            pageViews[prevCoreTextView].pageInfo?.pageLayer = nil
            //            pageViews[prevCoreTextView] = nil
            
            // Next page view is now current, previous current is now previous
            pageViews[prevCoreTextView] = pageViews[currCoreTextView]
            pageViews[currCoreTextView] = pageViews[nextCoreTextView]
            pageViews[nextCoreTextView] = CoreTextView(scrollView: self)
            
            pageDisplayed = pageToDisplay
            if self.loadPage(pageToLoad: pageToDisplay + 1) == nil {
                // Could not load next page (possibly not present)
                pageViews[nextCoreTextView].removeFromSuperview()
                pageViews[nextCoreTextView].pageInfo?.pageLayer = nil
                pageViews[nextCoreTextView] = CoreTextView(scrollView: self)
            }
        } else if pageToDisplay == pageDisplayed - 1 {
            // Display previous page view, which we should already have cached
            pageViews[nextCoreTextView].removeFromSuperview()
            pageViews[nextCoreTextView].pageInfo?.pageLayer = nil
            //            pageViews[nextCoreTextView] = nil
            
            // Previous page view is now current, previous current is now next
            pageViews[nextCoreTextView] = pageViews[currCoreTextView]
            pageViews[currCoreTextView] = pageViews[prevCoreTextView]
            pageViews[prevCoreTextView] = CoreTextView(scrollView: self)
            
            pageDisplayed = pageToDisplay
            if pageToDisplay > 0 {
                _ = self.loadPage(pageToLoad: pageToDisplay-1)
            } else {
                // No previous page because we are at the start of the document
                pageViews[prevCoreTextView].removeFromSuperview()
                pageViews[prevCoreTextView].pageInfo?.pageLayer = nil
                pageViews[prevCoreTextView] = CoreTextView(scrollView: self)
            }
        } else {
            // Loading general page that we don't have cached
            for idx in 0 ..< coreTextViewCount {
                pageViews[idx].removeFromSuperview()
                pageViews[idx].pageInfo?.pageLayer = nil
                pageViews[idx] = CoreTextView(scrollView: self)
            }
            
            pageDisplayed = pageToDisplay
            if pageToDisplay > 0 {
                _ = self.loadPage(pageToLoad: pageToDisplay - 1)
            }
            _ = self.loadPage(pageToLoad: pageToDisplay)
            _ = self.loadPage(pageToLoad: pageToDisplay + 1)
        }
        
        for idx in 0 ..< coreTextViewCount {
            let ctView = pageViews[idx]
            if ctView.pageInfo == nil {
                continue
            }
            
            let pageToLoad = ctView.pageInfo?.pageNumber
            
            // If there is a selected frame in a page that is not being displayed, unselect it and force a redraw
            if pageDisplayed != pageToLoad && ctView.selectedFrame != .max {
                ctView.selectedFrame = .max
                if ctView.pageInfo?.pageLayer != nil {
                    ctView.pageInfo?.pageLayer = nil
                }
            }
            
            if ctView.pageInfo?.pageLayer == nil {
                let pageToLoad = ctView.pageInfo?.pageNumber
                
                // Create the CALayer for the CoreTextView
                
                let layer = CALayer()
                
                let bounds = ctView.bounds
                layer.position = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)
                
                layer.bounds = bounds
                layer.backgroundColor = UIColor.clear.cgColor
                layer.contentsScale = UIScreen.main.scale
                
                //                [theLayer setDelegate: ctView.caLayerDrawDelegate];
                layer.delegate = ctView.caLayerDrawDelegate
                
                let viewLayer = ctView.layer
                let subLayers = viewLayer.sublayers
                // Remove any previous layer
                for aSubLayer in subLayers! {
                    aSubLayer.removeFromSuperlayer()
                }
                viewLayer.addSublayer(layer)
                
                layer.name = String(describing: pageToLoad)
                
                let pageToLoadNum = pageToLoad
                var pageInfoEntry = self.pagesDict[pageToLoadNum!]//(CoreTextViewPageInfo*)[pagesInfo objectForKey:pageToLoadNum];
                if pageInfoEntry == nil {
                    // Need new CoreTextViewPageInfo
                    pageInfoEntry = CoreTextViewPageInfo(layer: layer, pageNumber: pageToLoad!)//[[[CoreTextViewPageInfo alloc] initWithLayer:theLayer pageNumber:pageToLoad] autorelease];
                    //                    [pagesInfo setObject:pageInfoEntry forKey:pageToLoadNum];
                    self.pagesDict[pageToLoadNum!] = pageInfoEntry
                } else {
                    pageInfoEntry?.pageLayer = layer
                }
                pageInfoEntry?.needsRedrawOnLoad = true
                
                ctView.pageInfo = pageInfoEntry
                
                layer.setNeedsDisplay()
                layer.display()    // Displays the layer
                
                var frame = self.frame
                frame.origin.x = frame.size.width * CGFloat(pageToLoad!)
                frame.origin.y = 0
                ctView.frame = frame
                self.addSubview(ctView)
            }
        }
        
        let ctView = pageViews[currCoreTextView]
        self.pageSelected(page: ctView)
        // Post accessibility notification letting accessibility know that major screen change has occured
        //        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, NULL);
    }
    
    func pageForStringOffset(_ offset: Int) -> Int {
        for (pageNumber, page) in self.pagesDict {
            if offset >= page.rangeStart && offset < page.rangeEnd {
                return pageNumber
            }
        }
        return Int.max
    }
    
    func stringRangeForCurrentPage() -> NSRange? {
        // Get the text range from the appropriate CoreTextViewPageInfo
        if let pageInfo = self.pagesDict[self.pageDisplayed] {
            let result = NSRange(location: pageInfo.rangeStart, length: pageInfo.rangeEnd - pageInfo.rangeStart)
            return result
        }
        return nil
    }

    
    func addSelectionRange(range: NSRange) {
//        let rangeArray: [Int] = [range.location, range.length]
        if self.selectionRanges == nil {
            self.selectionRanges = []
        }
        self.selectionRanges!.append(range)
        self.pageNeedsDisplay(self.pageForStringOffset(range.location))
    }
    
    func clearSelectionRanges() {
        if self.selectionRanges != nil {
            for range in self.selectionRanges! {
                self.pageNeedsDisplay(self.pageForStringOffset(range.location))
            }
            self.selectionRanges = nil
        }
    }
    
    func fontFamilyChange(fontFamilyName: String) {
        //
        self.operationQueue.waitUntilAllOperationsAreFinished()
    }
    
    func optionsChange(optionName: String) {
        //
        self.operationQueue.waitUntilAllOperationsAreFinished()
    }
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

// MARK: - extended to confirm to UIScrollViewDelegate to implement page selection

extension PagerView: UIScrollViewDelegate {
    
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
