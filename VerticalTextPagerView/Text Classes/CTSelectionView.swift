//
//  CTSelectionView.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/25/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class CTSelectionView: UIView {

    // MARK: - Properties
    
    let textStorge = NSMutableAttributedString(string: "")
    
    var attrString: NSAttributedString?
    
    var imageDict: [[String : Any]]?
    
    var stringAttributes: [NSAttributedStringKey : Any] = [:]
    
    var frames: [CTFrame]?
    
    var images: [(image: UIImage, frame: CGRect)] = []
    
    let verticalLayout = true
    
    let columnCount = 1
    
    
    // MARK: properties for selection logic
    
    var tapPosition: CGPoint?
    
    var touchPosition1: CGPoint?
    var touchPosition2: CGPoint?
    
    var selectionRange: NSRange?
    var selectionPath: CGPath?
    var selectionWord: String? // single word
    
    var startSelectionHandlePath: UIBezierPath?
    var endSelectionHandlePath: UIBezierPath?
    
    var selectionWordRect: CGRect?
    
    // MARK: - initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        self.addGestureRecognizer(doubleTapRecognizer)
        
        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewDidTap(_:)))
        self.addGestureRecognizer(singleTapRecognizer)
        
        let dragRecognizer = UIPanGestureRecognizer(target: self, action: #selector(viewDidDrag(_:)))
        self.addGestureRecognizer(dragRecognizer)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(viewDidLongPress(_:)))
//        longPressRecognizer.minimumPressDuration
        self.addGestureRecognizer(longPressRecognizer)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.translateBy(x: 0.0, y: self.bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.textMatrix = .identity
        
        context.setStrokeColor(UIColor.red.cgColor)
        context.stroke(self.bounds)
        
        // highlight selection line if available
        if let selectionPath = self.selectionPath, let startSelectionHandlePath = self.startSelectionHandlePath, let endSelectionHandlePath = self.endSelectionHandlePath {
            context.setFillColor(UIColor.blue.withAlphaComponent(0.3).cgColor)
            context.addPath(selectionPath)
            context.fillPath()
            
            // draw selection handles
            UIColor.blue.set()
            startSelectionHandlePath.stroke()
            startSelectionHandlePath.fill()
            endSelectionHandlePath.stroke()
            endSelectionHandlePath.fill()
            
            // debug
//            context.setStrokeColor(UIColor.red.cgColor)
//            context.setLineWidth(3.0)
//            context.stroke(selectionPath.boundingBox)
        }
        
        self.drawColumnFrames(context)
        
//        self.drawImages(context)
    }
    
    // MARK: - draw frames into columns
    func drawColumnFrames(_ context: CGContext) {
        let string = chineseString
        let font = CTFontCreateUIFontForLanguage(.system, 20.0, nil)
        self.stringAttributes[.font] = font
        if verticalLayout {
            self.stringAttributes[.verticalGlyphForm] = NSNumber(value: true)
            let attributedString = NSMutableAttributedString(string: string, attributes: stringAttributes)
            self.textStorge.setAttributedString(attributedString)
        } else {
            let attributedString = NSMutableAttributedString(string: string)
            self.textStorge.setAttributedString(attributedString)
        }
        if let attrString = self.attrString {
            
            self.textStorge.setAttributedString(attrString)
        }
        /*
        if let selectionRange = self.selectionRange {
            var selectionAttributes = [NSAttributedStringKey.backgroundColor : UIColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.9).cgColor]
            selectionAttributes[.foregroundColor] = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
            self.textStorge.addAttributes(selectionAttributes, range: selectionRange)
//            self.selectionRange = nil
        }
        */
        // Create the framesetter with the attributed string.
        let framesetter = CTFramesetterCreateWithAttributedString(self.textStorge)
        var frameAttributes: CFDictionary?
        if verticalLayout {
            frameAttributes = [kCTFrameProgressionAttributeName as NSAttributedStringKey: NSNumber(value: CTFrameProgression.rightToLeft.rawValue)] as CFDictionary
        } else {
            frameAttributes = nil
        }
        
        
        let columnPaths = self.createColumns(withColumnCount: columnCount)
        
        //        let pathCount: CFIndex = CFArrayGetCount(columnPaths)
        let pathCount = columnPaths.count
        var startIndex: CFIndex = 0
        
        self.frames = [CTFrame]()
        // Create a frame for each column (path).
        for column in 0 ..< pathCount {
            // Get the path for this column.
            let path = columnPaths[column]
            
            // draw frame path
            context.setStrokeColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
            context.addPath(path)
            context.strokePath()
            
            // Create a frame for this column and draw it.
            let frame = CTFramesetterCreateFrame(
                framesetter, CFRangeMake(startIndex, 0), path,  frameAttributes)
            self.frames?.append(frame)
            CTFrameDraw(frame, context)
            
            if let imageDict = self.imageDict {
                self.images = self.attachImagesWithFrame(imageDict, ctframe: frame)
                self.drawImages(context)
            }
            // Start the next frame at the first character not visible in this frame.
            let frameRange: CFRange = CTFrameGetVisibleStringRange(frame)
            startIndex += frameRange.length
            
//            print("start index", startIndex)
        }
    }
    
    // MARK: Dividing a view into columns
    func createColumns(withColumnCount columnCount: Int) -> [CGMutablePath] {
        var columnRects = [CGRect](repeating: CGRect.zero, count: columnCount)
        // Set the first column to cover the entire view.
        columnRects[0] = self.bounds;
        
        // Divide the columns equally across the frame's width.
        let columnWidth = self.bounds.width / CGFloat(columnCount)
        
        for column in 0 ..< columnCount - 1 {
            let (slice, remainder) = columnRects[column].divided(atDistance: columnWidth, from: .maxXEdge)
            columnRects[column] = slice
            columnRects[column + 1] = remainder
        }
        
        // Inset all columns by a few pixels of margin.
        for column in 0 ..< columnCount {
            columnRects[column] = columnRects[column].insetBy(dx: 0.0, dy: 0.0)
        }
        
        // Create an array of layout paths, one for each column.
        var array = [CGMutablePath]()
        
        for column in 0 ..< columnCount {
            let path = CGMutablePath()
            path.addRect(columnRects[column])
            array.append(path)
        }
        // get column paths, reverse paths because we layout vertical text
        return array
    }
    
    func attachImagesWithFrame(_ imagesDict: [[String: Any]],
                               ctframe: CTFrame) -> [(image: UIImage, frame: CGRect)] {
        //1
        let lines = CTFrameGetLines(ctframe) as NSArray
        //2
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(ctframe, CFRangeMake(0, 0), &origins)
        
        var reusltImages: [(image: UIImage, frame: CGRect)] = []
        var imageIndex = 0
        if imagesDict.count <= 0 {
            return reusltImages
        }
        //3
        var nextImage = imagesDict[imageIndex]
        guard var imgLocation = nextImage["location"] as? Int else {
            return reusltImages
        }
        //4
        for lineIndex in 0..<lines.count {
            let line = lines[lineIndex] as! CTLine
            //5
            if let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun],
                let imageFilename = nextImage["filename"] as? String,
                let img = UIImage(named: imageFilename)  {
                for run in glyphRuns {
                    // 1
                    let runRange = CTRunGetStringRange(run)
                    if runRange.location > imgLocation || runRange.location + runRange.length <= imgLocation {
                        continue
                    }
                    //2
                    var imgBounds: CGRect = .zero
                    var ascent: CGFloat = 0
                    imgBounds.size.width = CGFloat(CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, nil, nil))
                    imgBounds.size.height = ascent
                    //3
                    let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, nil)
//                    print("xOffset", xOffset, "origins[lineIndex].y", origins[lineIndex].y)
                    let path = CTFrameGetPath(ctframe)
                    let frameBounds = path.boundingBox
                    imgBounds.origin.x = origins[lineIndex].x
                    imgBounds.origin.y = frameBounds.height - xOffset //origins[lineIndex].y
                    //4
                    reusltImages += [(image: img, frame: imgBounds)]
                    //5
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
    
    func drawImages(_ context: CGContext) {
        for imageData in images {
            if let image = imageData.image.cgImage {
                let imgBounds = imageData.frame
                context.draw(image, in: imgBounds)
//                print("imgBounds", imgBounds)
            }
        }
    }
}

// MARK: - selction extension

extension CTSelectionView {
    
    override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            return true
        } else if action == #selector(_lookup(_:)) {
            if let _ = getRootViewController() {
                return true
            }
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    override func copy(_ sender: Any?) {
        print("copy")
        if let selectionRange = self.selectionRange {
            let selectionString = textStorge.attributedSubstring(from: selectionRange)
            print("copy, string: ", selectionString.string)
            let pBoard = UIPasteboard.general
            pBoard.string = selectionString.string
        }
        self.clearSelection()
    }
    
    
    @objc func _lookup(_ sender: Any?) {
        print("_lookup")
        if let word = self.selectionWord, let rootViewController = getRootViewController() {
            let refCtl = UIReferenceLibraryViewController(term: word)
            rootViewController.present(refCtl, animated: true, completion: nil)
        }
        self.clearSelection()
    }
    
    func getRootViewController() -> UIViewController? {
        let app = UIApplication.shared
        var controller: UIViewController?
        if let keyWindow = app.keyWindow, let ctrl = keyWindow.rootViewController {
            controller = ctrl
        } else if let window = app.windows.first, let ctrl = window.rootViewController {
            controller = ctrl
        }
        if controller != nil {
            while controller!.view.window == nil && controller!.presentedViewController != nil {
                controller = controller!.presentedViewController
            }
        }
        return controller
    }
    
    // MARK: gesture recognizer methods
    
    @objc func viewDidLongPress(_ sender: UILongPressGestureRecognizer) {
        self.startSelection(sender)
    }
    
    @objc func viewDidDoubleTap(_ sender: UITapGestureRecognizer) {
        self.startSelection(sender)
    }
    
    @objc func viewDidTap(_ sender: UITapGestureRecognizer) {
        if sender.state == .ended {
            let position = sender.location(in: self)
            
            if let selectionPath = self.selectionPath {
                let rightPos = CGPoint(x: position.x, y: self.bounds.height - position.y)
                let inBounds = selectionPath.contains(rightPos)
                if inBounds {
                    showSelectionMenu(selectionPath.boundingBox)
                } else {
                    self.clearSelection()
                }
            }
        }
    }
    
    @objc func viewDidDrag(_ sender: UIPanGestureRecognizer) {
        if sender.state == .ended {
            if self.touchPosition2 != nil {
                setNeedsDisplay()
                if let selectionPath = self.selectionPath {
                    showSelectionMenu(selectionPath.boundingBox)
                }
            }
        } else if sender.state == .changed {
            if self.touchPosition1 != nil {
                let position = sender.location(in: self)
                
                // if selection exists, determine which is touchPosition1(start point) by comparing distance between current touch position and ouchPosition1, ouchPosition2
                if let touchPosition1 = touchPosition1, let touchPosition2 = touchPosition2 {
                    let d1 = abs(touchPosition1.x - position.x)
                    let d2 = abs(touchPosition2.x - position.x)
                    if d1 < d2 {
                        self.touchPosition1 = self.touchPosition2
                    }
                }
                self.touchPosition2 = position
                if let touchPosition1 = touchPosition1, let touchPosition2 = touchPosition2 {
                    //                print("touchPosition1", touchPosition1, "touchPosition2", touchPosition2)
                    self.prepareSelection(between: touchPosition1, and: touchPosition2)
                }
                hideSelectionMenu()
                setNeedsDisplay()
            }
        }
        
    }
    
    // MARK: handle selection
    
    func startSelection(_ sender: UIGestureRecognizer) {
        let position = sender.location(in: self)
        
        // handle double touch event
        // 1. hightlight selected line
        // 2. show context menu
        if let selectionRect = getHitPointRect(at: position) {
            self.touchPosition1 = position
            let path = CGMutablePath()
            path.addRect(selectionRect)
            self.selectionPath = path
            // show context menu
            var rect = selectionRect
            // convert rect to LLO coordinate, flip y
            rect.origin.y = self.bounds.size.height - selectionRect.origin.y
            // make the rect.y a height offset to adjust selection menu postion, in order to avoid the menu from obscuring selection text
            rect.origin.y = rect.origin.y - selectionRect.size.height
            if sender.state == .ended {
                self.showSelectionMenu(rect)
            }
        }
        
        setNeedsDisplay()
    }
    
    func showSelectionMenu(_ rect: CGRect) {
        if self.becomeFirstResponder() {
            let menu = UIMenuController.shared
            //            var rect = rect
            //            rect.origin.y = self.bounds.height - rect.origin.y
            
            menu.setTargetRect(rect, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }
    
    func hideSelectionMenu() {
        if self.isFirstResponder {
            let menu = UIMenuController.shared
            if menu.isMenuVisible {
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    
    func clearSelection() {
        self.touchPosition1 = nil
        self.touchPosition2 = nil
        self.selectionPath = nil
        hideSelectionMenu()
        setNeedsDisplay()
    }
    
    // MARK: query selection rect info
    
    func getHitPointRect(at position: CGPoint?) -> CGRect? {
        guard let frames = self.frames, let position = position else { return nil }
        
        var rightPosition = position
        if verticalLayout {
            rightPosition = CGPoint(x: position.x, y: self.bounds.size.height - position.y)
            //            print("getHitPointRect flippedPosition", rightPosition)
        }
        
        for frame in frames {
            let path = CTFrameGetPath(frame)
            let frameBounds = path.boundingBox
            //            rightPosition = CGPoint(x: position.x, y: self.bounds.size.height - position.y)
            //            print("flippedPosition", rightPosition)
            if frameBounds.contains(rightPosition) {
                //                print("frameBounds", frameBounds)
                // if position locates in this frame path, iterates lines of this frame
                let lines = CTFrameGetLines(frame) as! [CTLine]
                //                let lineCount = CFArrayGetCount(lines)
                
                
                for lineIndex in 0 ..< lines.count {
                    let line = lines[lineIndex]
                    let lineBounds = getLineBounds(forLine: line, at: lineIndex, ofFrame: frame, inFrameRect: frameBounds)
                    
                    if lineBounds.contains(rightPosition) {
                        
                        var apos = position
                        if verticalLayout {
                            apos = CGPoint(x: position.y, y: position.x)
                        }
                        // CTLineGetStringIndexForPosition only cares point.x, so it is not very reliable
                        let hitStringIndex = CTLineGetStringIndexForPosition(line, apos)
                        
                        // to be tuned...
                        let stringRange = CFRangeMake(hitStringIndex - 1, 1)
                        printRange(selectionRange: stringRange)
                        
                        let wordSelectionRange = NSRange(location: hitStringIndex - 1, length: 1)
                        self.selectionWord = textStorge.attributedSubstring(from: wordSelectionRange).string
                        
                        let offset = CTLineGetOffsetForStringIndex(line, hitStringIndex, nil)
                        
                        let fontDesc = UIFontDescriptor(name: "STHeitiSC-Light", size: 20.0)
                        let font = UIFont(descriptor: fontDesc, size: fontDesc.pointSize)
                        let rect = CTFontGetBoundingBox(font)
                        
                        var wordRect = CGRect(origin: .zero, size: rect.size)
                        wordRect.origin.x = lineBounds.origin.x + (lineBounds.size.width - rect.size.width) / 2
                        wordRect.origin.y = frameBounds.size.height - offset + frameBounds.origin.y
                        
                        self.selectionWordRect = wordRect
                        
                        let handles = getSelectionHandles(startRect: wordRect, endRect: wordRect)
                        self.startSelectionHandlePath = handles.startHandle
                        self.endSelectionHandlePath = handles.endHandle
                        
                        
                        self.selectionRange = wordSelectionRange
                        
                        return wordRect
                    }
                }
            }
        }
        return nil
    }
    
    func printLine(line: CTLine) {
        let selectionRange = CTLineGetStringRange(line)
        let selectionString = textStorge.attributedSubstring(from: NSRange(location: selectionRange.location, length: selectionRange.length))
        print("printLine, selection string: ", selectionString.string)
    }
    
    func printRange(selectionRange: CFRange) {
        let selectionString = textStorge.attributedSubstring(from: NSRange(location: selectionRange.location, length: selectionRange.length))
        print("printRange, selection string: ", selectionString.string)
    }
    
    func getLineBounds(forLine line: CTLine, at lineIndex: CFIndex, ofFrame frame: CTFrame, inFrameRect frameBounds: CGRect) -> CGRect {
        let rect = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.useOpticalBounds)
        //        print("CTLineGetBoundsWithOptions", rect)
        //        let rect2 = CTLineGetImageBounds(line, context)
        //        print("CTLineGetImageBounds", rect2)
        
        var lineOrigin: CGPoint = .zero
        CTFrameGetLineOrigins(frame, CFRangeMake(lineIndex, 1), &lineOrigin)
        let stringRange = CTLineGetStringRange(line)
        
        let offsetInLine: CGFloat = CTLineGetOffsetForStringIndex(line, stringRange.location + stringRange.length, nil)
        var selectionBounds: CGRect = .zero
        if verticalLayout {
            selectionBounds.origin.x = (frameBounds.origin.x + lineOrigin.x + rect.origin.x) - rect.height/2
            selectionBounds.origin.y = frameBounds.size.height - offsetInLine + frameBounds.origin.y// ((lineOrigin.y + rect.origin.y)) // there must be a offset
            
            selectionBounds.size.width = rect.size.height
            selectionBounds.size.height = rect.size.width
        } else {
            selectionBounds.origin.x = (frameBounds.origin.x + lineOrigin.x + rect.origin.x)
            let y = frameBounds.size.height - lineOrigin.y + frameBounds.origin.y - (rect.height)
            selectionBounds.origin.y = y
            selectionBounds.size = rect.size
        }
        
        //        print("selectionBounds", selectionBounds)
        //        printLine(line: line)
        
        return selectionBounds
    }
    
    // LLO
    func getSelectionRect(forLine line: CTLine, lineOrigin: CGPoint, stringStartIndex: Int, stringEndIndex: Int, inFrameRect frameBounds: CGRect) -> CGRect {
        
        let rect = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.useOpticalBounds)
        
        let lineStartOffset = CTLineGetOffsetForStringIndex(line, stringStartIndex, nil)
        
        let lineEndOffset: CGFloat = CTLineGetOffsetForStringIndex(line, stringEndIndex, nil)
        
        var selectionBounds: CGRect = .zero
        
        selectionBounds.origin.x = (frameBounds.origin.x + lineOrigin.x + rect.origin.x) - rect.height/2
        selectionBounds.origin.y = frameBounds.origin.y + frameBounds.size.height - lineEndOffset
        
        selectionBounds.size.width = rect.size.height
        selectionBounds.size.height = lineEndOffset - lineStartOffset
        
        return selectionBounds
    }
    
    func getSelectionHandles(startRect: CGRect, endRect: CGRect) -> (startHandle: UIBezierPath, endHandle: UIBezierPath) {
        let startHandlePath = UIBezierPath()
        
        let handleRadius: CGFloat = 4
        var startHandleRect = CGRect.zero
        var endHandleRect = CGRect.zero
        
        startHandleRect.origin.x = startRect.maxX
        startHandleRect.origin.y = startRect.maxY - handleRadius
        startHandleRect.size.width = handleRadius * 2.0
        startHandleRect.size.height = handleRadius * 2.0
        startHandlePath.addArc(withCenter: CGPoint(x: startHandleRect.midX, y: startHandleRect.midY), radius: 4.5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        
        startHandlePath.move(to: CGPoint(x: startRect.minX, y: startRect.maxY))
        startHandlePath.addLine(to: CGPoint(x: startRect.maxX, y: startRect.maxY))
        
        startHandlePath.lineWidth = 2.0
        
        let endHandlePath = UIBezierPath()
        
        endHandleRect.origin.x = endRect.minX - handleRadius * 2
        endHandleRect.origin.y = endRect.minY - handleRadius
        endHandleRect.size.width = handleRadius * 2.0
        endHandleRect.size.height = handleRadius * 2.0
        endHandlePath.addArc(withCenter: CGPoint(x: endHandleRect.midX, y: endHandleRect.midY), radius: 4.5, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        endHandlePath.move(to: CGPoint(x: endRect.minX, y: endRect.minY))
        endHandlePath.addLine(to: CGPoint(x: endRect.maxX, y: endRect.minY))
        
        endHandlePath.lineWidth = 2.0
        
        return (startHandlePath, endHandlePath)
    }
    
    struct SelectionInfo: Comparable {
        static func < (lhs: CTSelectionView.SelectionInfo, rhs: CTSelectionView.SelectionInfo) -> Bool {
            return lhs.stringIndex < rhs.stringIndex
        }
        
        let line: CTLine
        let lineIndex: Int
        let stringIndex: Int
        
    }
    
    func prepareSelection(between point1: CGPoint, and point2: CGPoint) {
        guard let frames = self.frames else {
            return
        }
        
        if point1 == point2 {
            return
        }
        
        for frame in frames {
            let path = CTFrameGetPath(frame)
            let frameBounds = path.boundingBox
            
            // assume all points are in the same frame
            if frameBounds.contains(point1) && frameBounds.contains(point2) {
                // if position locates in this frame path, iterates lines of this frame
                let lines = CTFrameGetLines(frame) as! [CTLine]
                let lineCount = lines.count
                
                var selectionEndPointInfo1, selectionEndPointInfo2: SelectionInfo?
                
                
                for lineIndex in 0 ..< lineCount {
                    let line = lines[lineIndex]
                    let lineBounds = getLineBounds(forLine: line, at: lineIndex, ofFrame: frame, inFrameRect: frameBounds)
                    
                    if selectionEndPointInfo1 == nil {
                        selectionEndPointInfo1 = getSelectionPointInfo(for: point1, line: line, lineIndex: lineIndex, lineBounds: lineBounds)
                    }
                    
                    if selectionEndPointInfo2 == nil {
                        selectionEndPointInfo2 = getSelectionPointInfo(for: point2, line: line, lineIndex: lineIndex, lineBounds: lineBounds)
                    }
                    
                }
                
                if let selectionEndPointInfo1 = selectionEndPointInfo1, let selectionEndPointInfo2 = selectionEndPointInfo2 {
                    let startStringIndex = min(selectionEndPointInfo1.stringIndex, selectionEndPointInfo2.stringIndex)
                    let endStringIndex = max(selectionEndPointInfo1.stringIndex, selectionEndPointInfo2.stringIndex)
                    if startStringIndex * endStringIndex <= 0 {
                        return
                    }
                    //                    print("startLineIndex", startStringIndex, "endLineIndex", endStringIndex)
                    
                    let selectionRange = NSRange(location: startStringIndex - 1, length: endStringIndex - startStringIndex)
                    //                    printRange(selectionRange: CFRangeMake(startStringIndex - 1, endStringIndex - startStringIndex))
                    
                    self.selectionRange = selectionRange
                    
                    let rangeStart = selectionRange.location
                    let rangeEnd = selectionRange.location + selectionRange.length
                    var selectionLines: [CTLine] = []
                    var startLineRect: CGRect = .zero
                    var endLineRect: CGRect = .zero
                    var inlineRect: CGRect = .zero
                    
                    var midLineRects = [CGRect]()
                    
                    let path = CGMutablePath()
                    
                    //                    print("range start", rangeStart)
                    //                    print("range end", rangeEnd)
                    var lineIndex = 0
                    for line in lines {
                        let range = CTLineGetStringRange(line)
                        let lineStart = range.location
                        let lineEnd = range.location + range.length
                        if lineStart >= rangeStart && lineEnd <= rangeEnd {
                            selectionLines.append(line)
                            var lineOrigin: CGPoint = .zero
                            CTFrameGetLineOrigins(frame, CFRangeMake(lineIndex, 1), &lineOrigin)
                            let rect = getSelectionRect(forLine: line, lineOrigin: lineOrigin, stringStartIndex: lineStart, stringEndIndex: lineEnd, inFrameRect: frameBounds)
                            //                            print("rect", rect)
                            if rect != .zero {
                                midLineRects.append(rect)
                            }
                        }
                            // first line
                        else if lineStart < rangeStart && lineEnd > rangeStart, lineEnd < rangeEnd {
                            selectionLines.insert(line, at: 0)
                            var lineOrigin: CGPoint = .zero
                            CTFrameGetLineOrigins(frame, CFRangeMake(lineIndex, 1), &lineOrigin)
                            
                            startLineRect = getSelectionRect(forLine: line, lineOrigin: lineOrigin, stringStartIndex: rangeStart, stringEndIndex: lineEnd, inFrameRect: frameBounds)
                            //                            print("start line rect: ", startLineRect)
                        }
                            // last line
                        else if lineStart > rangeStart, lineStart < rangeEnd && lineEnd > rangeEnd {
                            selectionLines.append(line)
                            var lineOrigin: CGPoint = .zero
                            CTFrameGetLineOrigins(frame, CFRangeMake(lineIndex, 1), &lineOrigin)
                            
                            endLineRect = getSelectionRect(forLine: line, lineOrigin: lineOrigin, stringStartIndex: lineStart, stringEndIndex: rangeEnd, inFrameRect: frameBounds)
                            
                            //                            print("end line rect: ", endLineRect)
                        }
                            // slection within one line
                        else if lineStart <= rangeStart && lineEnd >= rangeEnd {
                            selectionLines.append(line)
                            var lineOrigin: CGPoint = .zero
                            CTFrameGetLineOrigins(frame, CFRangeMake(lineIndex, 1), &lineOrigin)
                            inlineRect = getSelectionRect(forLine: line, lineOrigin: lineOrigin, stringStartIndex: rangeStart, stringEndIndex: rangeEnd, inFrameRect: frameBounds)
                            //                            print("inline bounds", inlineRect)
                        }
                        lineIndex += 1
                    }
                    
                    if inlineRect != .zero {
                        path.addRect(inlineRect)
                    }
                    if startLineRect != .zero {
                        path.addRect(startLineRect)
                    }
                    if endLineRect != .zero {
                        path.addRect(endLineRect)
                    }
                    if midLineRects.count > 0 {
                        path.addRects(midLineRects)
                    }
                    
                    if inlineRect != .zero {
                        let handles = getSelectionHandles(startRect: inlineRect, endRect: inlineRect)
                        self.startSelectionHandlePath = handles.startHandle
                        self.endSelectionHandlePath = handles.endHandle
                    } else {
                        let handles = getSelectionHandles(startRect: startLineRect, endRect: endLineRect)
                        self.startSelectionHandlePath = handles.startHandle
                        self.endSelectionHandlePath = handles.endHandle
                    }
                    
                    self.selectionPath = path
                    
                    return
                }
            }
        }
    }
    
    func getSelectionPointInfo(for point: CGPoint, line: CTLine, lineIndex: Int, lineBounds: CGRect) -> SelectionInfo? {
        
        var stringIndex: Int = -1
        
        // find the line that contains point2
        if lineBounds.contains(point) {
            var rightPosition: CGPoint = point
            // if vertical layout, should transpose point in order to get the right hit string index
            if verticalLayout {
                rightPosition = CGPoint(x: point.y, y: point.x)
            }
            stringIndex = CTLineGetStringIndexForPosition(line, rightPosition)
            //            let stringRange = CTLineGetStringRange(line)
            //            print("stringRange", stringRange)
            
            return SelectionInfo(line: line, lineIndex: lineIndex, stringIndex: stringIndex)
        }
        
        return nil
    }
}
