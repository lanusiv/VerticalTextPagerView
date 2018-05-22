//
//  CoreTextView.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 5/1/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit


let IPAD_HORIZONTAL_MARGIN: CGFloat = 40
let IPAD_VERTICAL_MARGIN: CGFloat = 30

let IPHONE_HORIZONTAL_MARGIN: CGFloat = 10
let IPHONE_VERTICAL_MARGIN: CGFloat = 10

class CoreTextView: UIView, TextViewSelection {
    
    // MARK: - Properties
    
    var scrollView: PagerView!
    var pageInfo: CoreTextViewPageInfo?
    var selectedFrame: Int = .max
    var layoutOnlyOnDraw: Bool = false
    
    var caLayerDrawDelegate: CoreTextViewDraw?
    
    // MARK: Properties confirm to TextViewSelection
    
    var isVerticalLayout = true
    
    var frames: [CTFrame]?
    
    var textStorage = NSMutableAttributedString(string: "")
    
    var selectionView: SelectionView?
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.layoutOnlyOnDraw = true
    }
    
    convenience init(scrollView: PagerView) {
        self.init(frame: scrollView.frame)
        self.scrollView = scrollView
        
        self.caLayerDrawDelegate = CoreTextViewDraw(initWithView: self)
        
        self.frames = []
    }
    
    func addSelectionView() {
        if self.selectionView == nil {
            self.selectionView = SelectionView.initSelectionView(self)
            if isVerticalLayout {
                selectionView!.transform = CGAffineTransform(rotationAngle: .pi)
            }
        }
        
        //        selectionView.frame = self.bounds
    }
    
    // MARK: - override methods
    /*
    override func awakeFromNib() {
//        super.awakeFromNib()
        let layer = self.layer
        scrollView = nil
        self.reset()
        // clear the view's background color so that our background
        // fits within the rounded border
        let backgroundColor = self.backgroundColor?.cgColor//[self.backgroundColor CGColor];
        self.backgroundColor = .clear
        layer.backgroundColor = backgroundColor
        
        self.setNeedsDisplay()
    }
 */
    
    // MARK: - behaviors
    
    func reset() {
        self.pageInfo = nil
        self.selectedFrame = .max
        
        if self.caLayerDrawDelegate == nil {
            self.caLayerDrawDelegate = CoreTextViewDraw(initWithView: self)
        }
    }
    
    // MARK: - Touch Handling
    
    /*override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let numTap = touch.tapCount
//            print("touchesBegan tapCount: ", numTap)
            self.selectFrame(at: touch.location(in: self))
        }
        super.touchesBegan(touches, with: event)
    }*/
    
    func selectFrame(at position: CGPoint) {
        let layoutBounds = self.bounds
        var position = position
        position.y = layoutBounds.size.height - position.y
        
        guard let framesToDraw = self.framesToDrawForPage() else { return }
        // walk through frames for current view, find closest frame
        var index: Int = 0
        for frameInfo in framesToDraw {
            if let path = frameInfo.path {
                let bounds = path.boundingBox
                if bounds.contains(position) {
                    if index != self.selectedFrame {
                        self.selectedFrame = index
                        self.scrollView.refreshPage()
                    } else if self.selectedFrame != .max {
                        self.selectedFrame = .max
                        self.scrollView.refreshPage()
                    }
                    break
                }
            }
            index += 1
        }
    }
    
    // MARK: - View Drawing
    
    func framesToDrawForPage() -> [CoreTextViewFrameInfo]? {
        guard let scrollView = self.scrollView, let pageInfo = self.pageInfo else {
            return nil
        }
        
        let pageNumber = pageInfo.pageNumber
        
        let thePagesDict = scrollView.pagesDict
        
        var framesToDraw: [CoreTextViewFrameInfo]?
        
        let theDocument: AttributedStringDoc = scrollView.document
        
        if pageNumber < thePagesDict.count, let framesToDraw = thePagesDict[pageNumber]?.framesToDraw {
            return framesToDraw
        }
        
        framesToDraw = []
        var layoutBounds = CGRect(origin: .zero, size: self.bounds.size)
        if UIScreen.main.bounds.size.width < 500 {
            layoutBounds = layoutBounds.insetBy(dx: IPHONE_HORIZONTAL_MARGIN, dy: IPHONE_VERTICAL_MARGIN)
        } else {
            layoutBounds = layoutBounds.insetBy(dx: IPAD_HORIZONTAL_MARGIN, dy: IPAD_VERTICAL_MARGIN)
        }
        // offset drawing area slightly if we intend to draw page numbers
        if (theDocument.showPageNumbers) {
            layoutBounds.origin.y += 20
        }
        
        var startIndex = 0
        var curIndex = 0
        var prevFreeFlowFrame: CoreTextViewFrameInfo?
        
        if pageNumber > 0, let prevPageInfo = thePagesDict[pageNumber - 1] {
            curIndex = prevPageInfo.rangeEnd
            startIndex = curIndex
            prevFreeFlowFrame = prevPageInfo.lastFreeFlowFrame
        }
        
//        NSArray* pageFrames = [theDocument framesForPage:pageNumber];
        let pageFrames = theDocument.framesForPage(page: pageNumber)
        if pageFrames != nil {
            for frameInfo in pageFrames! {
                // Update frame bounds
                let path = CGMutablePath()
                var frameBounds: CGRect = theDocument.boundsForFrame(frameDesc: frameInfo)!
                let frameType = theDocument.typeForFrame(frameDesc: frameInfo)
                let frameForDisplay = CoreTextViewFrameInfo(type: frameType, andPath: path)
                
//                [frameForDisplay setAccessibilityLabel:[theDocument accessibilityLabelForFrame:frameInfo]];
                frameBounds.origin.y = (layoutBounds.size.height - frameBounds.origin.y) - frameBounds.size.height
                path.addRect(frameBounds)
                
                // Get attributed string data for frame, if applicable, and create framesetter
                let doc = theDocument.objectForFrame(frameInfo)
                if doc != nil {
                    frameForDisplay.value = doc
                    
                    if theDocument.typeForFrame(frameDesc: frameInfo) == .text, let attributedString = doc as? NSAttributedString {
                        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
                        frameForDisplay.setter = framesetter
                    } else {
                        // Not a text-based frame
                        frameForDisplay.setter = nil
                        frameForDisplay.frame = nil
                    }
                } else if theDocument.typeForFrame(frameDesc: frameInfo) == .textFlow {
                    frameForDisplay.value = theDocument
                    curIndex = frameForDisplay.setFrameSetterForStringOffset(stringOffset: curIndex, previousFreeFlowFrame: prevFreeFlowFrame)
                    prevFreeFlowFrame = frameForDisplay
                }
                
                framesToDraw?.append(frameForDisplay)
            }
        } else {
            // No previous frames, so generate our frame "layout"
            
//            int column;
            let columnCount = theDocument.columnsForPage(pageNumber)
//            print("framesToDrawForPage columnCount: ", columnCount)
//            CGRect* columnRects = (CGRect*)calloc(columnCount, sizeof(*columnRects));
            var columnRects = [CGRect](repeating: .zero, count: columnCount)
            
            // Start by setting the first column to cover the entire view.
            columnRects[0] = layoutBounds
            
            // Divide the columns equally across the screen's width.
            let columnWidth: CGFloat = layoutBounds.width / CGFloat(columnCount)
            let isVertical = theDocument.verticalOrientation
            let rectEdge: CGRectEdge = isVertical ? .maxXEdge : .minXEdge
            for column in 0 ..< columnCount - 1 {
                let (slice, remainder) = columnRects[column].divided(atDistance: columnWidth, from: rectEdge)
                columnRects[column] = slice
                columnRects[column + 1] = remainder
            }
            
            // Inset all columns by a few pixels of margin.
//            for (column = 0; column < columnCount; column++) {
            for column in 0 ..< columnCount {
                columnRects[column] = columnRects[column].insetBy(dx: 10.0, dy: 10.0)
            }
            
//            for (column = 0; column < columnCount; column++) {
            for column in 0 ..< columnCount {
                let path = CGMutablePath()
                path.addRect(columnRects[column])
                let frameForDisplay: CoreTextViewFrameInfo = CoreTextViewFrameInfo(type: .textFlow, andPath: path)
                
                frameForDisplay.value = theDocument
                curIndex = frameForDisplay.setFrameSetterForStringOffset(stringOffset: curIndex, previousFreeFlowFrame: prevFreeFlowFrame)
                prevFreeFlowFrame = frameForDisplay
                
//                [framesToDraw addObject:frameForDisplay];
                framesToDraw?.append(frameForDisplay)
            }
        }
        
        let pageInfoEntry: CoreTextViewPageInfo? = thePagesDict[pageNumber]
        
        pageInfoEntry?.framesToDraw = framesToDraw
        pageInfoEntry?.rangeStart = startIndex
        pageInfoEntry?.rangeEnd = curIndex
        pageInfoEntry?.lastFreeFlowFrame = prevFreeFlowFrame
        
        return framesToDraw
    }
    
    func drawIntoLayer(layer: CALayer, inContext context: CGContext) {
        guard let scrollView = self.scrollView, let document = scrollView.document, let pageInfo = self.pageInfo else {
            return
        }
        let pageBeingDrawn = pageInfo.pageNumber
        
        var backgroundColor: CGColor? = nil
        let pageFrames = document.framesForPage(page: pageBeingDrawn)
        if pageFrames != nil {
            backgroundColor = document.copyColorForPage(page: pageBeingDrawn)
        } else {
            // Default to white background
            backgroundColor = UIColor.white.cgColor
        }
        layer.backgroundColor = backgroundColor
        
        context.textMatrix = .identity
        
        self.isVerticalLayout = document.verticalOrientation
        
        if isVerticalLayout {
            // for vertical text layout from right to left
            context.translateBy(x: self.bounds.size.width, y: 0.0)
            context.scaleBy(x: -1.0, y: 1.0)
        } else {
            // normal process
            context.translateBy(x: 0.0, y: self.bounds.size.height)
            context.scaleBy(x: 1.0, y: -1.0)
        }
        
        var layoutCount = 0
        var framesToDraw = pageInfo.framesToDraw
        if framesToDraw == nil {
            framesToDraw = self.framesToDrawForPage()
            layoutCount += 1
        }
        //        NSEnumerator* framesEnumerator = [framesToDraw objectEnumerator];
        //        CoreTextViewFrameInfo* frameInfo;
        
        // Draw each frame
        var frameIndex = 0
        //        while ((frameInfo = [framesEnumerator nextObject]) != NULL) {
        for frameInfo in framesToDraw! {
            let path = frameInfo.path
            let type = frameInfo.frameType
            
            context.setStrokeColor(UIColor.red.cgColor)
            context.stroke(path!.boundingBox)
            
            context.setFillColor(UIColor.green.withAlphaComponent(0.2).cgColor)
            context.fill(self.bounds)
            
            if type == .text || type == .textFlow {
                var frame = frameInfo.frame
                if (frame == nil) {
                    frame = CTFramesetterCreateFrame(frameInfo.setter!, CFRangeMake(0, 0), path!, nil)
                    frameInfo.frame = frame
                }
                if !self.layoutOnlyOnDraw {
                    CTFrameDraw(frame!, context)
                    
                    // collect frames
                    self.frames!.append(frame!)
                    // After drawing frame, draw selected frame highlight rects
                    //                    [self hilightSelectedRangesForFrame:frameInfo inContext:context]
                    
                    // draw text images
                    if let textImagesDict = document.textImagesDict {
                        let textImages = self.attachImagesWithFrame(textImagesDict, ctframe: frame!)
                        self.drawImages(context, textImages)
                    }
                }
            } else if type == .picture && !self.layoutOnlyOnDraw {
                // This document 'frame' is an image, so draw it using CGImage
                let rect = path?.boundingBox
                guard let filePath = frameInfo.value as? NSString else { continue }
                
                let pngDP = CGDataProvider(filename: filePath.fileSystemRepresentation)
                if pngDP != nil {
                    let img = CGImage(pngDataProviderSource: pngDP!, decode: nil, shouldInterpolate: true, intent: .perceptual)  //kCGRenderingIntentPerceptual // true for interpolate, false for not-interpolate
                    if img != nil {
                        context.draw(img!, in: rect!)
                    }
                }
            }
            
            // Draw user-selected frame rect, if any
            if frameIndex == selectedFrame {
                context.setStrokeColor(UIColor.red.cgColor)
                context.setLineWidth(2.0)
                context.stroke(path!.boundingBox)
            }
            frameIndex += 1
        }
        
        if document.showPageNumbers && !self.layoutOnlyOnDraw {
            // Draw the page number (and debug draw counts)
            let sysUIFont = CTFontCreateUIFontForLanguage(.system, 16.0, nil)
            if sysUIFont != nil {
                var attributes: [NSAttributedStringKey : Any] = [:]
                attributes[.font] = sysUIFont
                
                var myPageNumberString: NSAttributedString
                //                #if DEBUG_LAYOUT_DRAW_COUNTS
                //                static int drawCount = 0;
                //                drawCount++;
                //                NSString* pageNumber = [NSString stringWithFormat:@"%@ [L%@/D%@]", [formatter stringFromNumber: [NSNumber numberWithInt: pageBeingDrawn+1]], [formatter stringFromNumber: [NSNumber numberWithInt: layoutCount]], [formatter stringFromNumber: [NSNumber numberWithInt: drawCount]], nil];
                //                #else
                //
                let pageNumber = String(describing: pageBeingDrawn + 1)
                //                #endif
                if pageNumber.count > 0 {
                    myPageNumberString = NSAttributedString(string: pageNumber, attributes: attributes)
                    
                    let ctLine = CTLineCreateWithAttributedString(myPageNumberString)
                    
                    context.textPosition = CGPoint(x: layer.bounds.size.width/2 - CGFloat(CTLineGetTypographicBounds(ctLine, nil, nil, nil)/2), y: 20)
                    
                    CTLineDraw(ctLine, context)
                }
            }
        }
        
        pageInfo.needsRedrawOnLoad = !layoutOnlyOnDraw
        pageInfo.needsReLayout = false
    }
    
}


extension CoreTextView {
    
    func attachImagesWithFrame(_ imagesDict: [[String: Any]],
                               ctframe: CTFrame) -> [(image: UIImage, frame: CGRect)] {
        var reusltImages: [(image: UIImage, frame: CGRect)] = []
        if imagesDict.count <= 0 {
            return reusltImages
        }
        
        let lines = CTFrameGetLines(ctframe) as! [CTLine]
        
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(ctframe, CFRangeMake(0, 0), &origins)
        
        var imageIndex = 0
        //3
        var nextImage = imagesDict[imageIndex]
        guard var imgLocation = nextImage["location"] as? Int else {
            return reusltImages
        }
        
        for lineIndex in 0 ..< lines.count {
            let line = lines[lineIndex]
            
            if let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun],
                let imageFilename = nextImage["filename"] as? String,
                let img = UIImage(named: imageFilename) {
                for run in glyphRuns {
                    
                    let runRange = CTRunGetStringRange(run)
                    if runRange.location > imgLocation || runRange.location + runRange.length <= imgLocation {
                        continue
                    }
                    
                    var imgBounds: CGRect = .zero
                    var ascent: CGFloat = 0
                    imgBounds.size.width = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, nil, nil))
                    imgBounds.size.height = ascent
                    
                    print("imgLocation", imgLocation, "CTRunGetStringRange(run).location", CTRunGetStringRange(run).location)
                    var xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location + 1, nil)
                    // to be tuned
//                    if !scrollView.document.showPageNumbers {
//                        xOffset += 20
//                    }
                    //                    print("xOffset", xOffset, "origins[lineIndex].y", origins[lineIndex].y)
                    let path = CTFrameGetPath(ctframe)
                    let frameBounds = path.boundingBox
                    imgBounds.origin.x = origins[lineIndex].x - imgBounds.width / 2 + frameBounds.origin.x
//                    imgBounds.origin.y = self.bounds.height - xOffset// + frameBounds.origin.y
                    
                    let topOffset = self.bounds.maxY - frameBounds.maxY
                    let correctOffset = xOffset - topOffset
                    
                    imgBounds.origin.y = frameBounds.size.height - correctOffset + frameBounds.origin.y
                    
                    reusltImages += [(image: img, frame: imgBounds)]
                    
                    imageIndex += 1
                    if imageIndex < imagesDict.count {
                        nextImage = imagesDict[imageIndex]
                        imgLocation = (nextImage["location"] as AnyObject).intValue
                    }
                }
            }
        }
        return reusltImages
    }
    
    func drawImages(_ context: CGContext, _ images: [(image: UIImage, frame: CGRect)]) {
        for imageData in images {
            if let image = imageData.image.cgImage {
                let imgBounds = imageData.frame
                print("imgBounds", imgBounds)
                context.setStrokeColor(UIColor.red.cgColor)
                context.stroke(imgBounds)
                context.draw(image, in: imgBounds)
                //                print("imgBounds", imgBounds)
            }
        }
    }
}
