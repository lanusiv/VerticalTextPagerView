//
//  CTSelectionView.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/25/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class CTSelectionView: UIView {

    let textStorge = NSMutableAttributedString(string: "")
    
    var attrString: NSAttributedString?
    
    var imageDict: [[String : Any]]?
    
    var stringAttributes: [NSAttributedStringKey : Any] = [:]
    
    var selectionRange: NSRange?
    
    var frames: [CTFrame]?
    
    var images: [(image: UIImage, frame: CGRect)] = []
    
    var tapPosition: CGPoint?
    
    var touchPosition1: CGPoint?
    var touchPosition2: CGPoint?
    
    let verticalLayout = true
    
    let columnCount = 1
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let taps = touches.first?.tapCount
        if let taps = taps, taps >= 1 {
            let position = touches.first?.location(in: self)
//            selectionLine(at: position!)
            self.tapPosition = position
//            if self.touchPosition1 != nil && self.touchPosition2 != nil {
//                touchPosition1 = nil
//                touchPosition2 = nil
//            } else if self.touchPosition1 == nil {
//                self.touchPosition1 = position
//            } else if self.touchPosition2 == nil {
//                self.touchPosition2 = position
//            }
            setNeedsDisplay()
            self.touchPosition1 = position
        }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let position = touches.first?.location(in: self)
        self.touchPosition2 = position
//        setNeedsDisplay()
        super.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesMoved(touches, with: event)
        super.touchesEnded(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touchesMoved(touches, with: event)
        super.touchesCancelled(touches, with: event)
    }
    
    func selectionLine(at position: CGPoint?, in context: CGContext) {
        guard let frames = self.frames, let position = position else { return }
        print("===position===", self.bounds)
        print("===position===", position)
        var rightPosition = position
        if verticalLayout {
            rightPosition = CGPoint(x: position.x, y: self.bounds.size.height - position.y)
            print("flippedPosition", rightPosition)
        }
        
        for frame in frames {
            let path = CTFrameGetPath(frame)
            let frameBounds = path.boundingBox
//            rightPosition = CGPoint(x: position.x, y: self.bounds.size.height - position.y)
            print("flippedPosition", rightPosition)
            if frameBounds.contains(rightPosition) {
                print("frameBounds", frameBounds)
                // if position locates in this frame path, iterates lines of this frame
                let lines = CTFrameGetLines(frame)
                let lineCount = CFArrayGetCount(lines)
                
                
                for lineIndex in 0 ..< lineCount {
                    let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, lineIndex), to: CTLine.self)
                    let lineBounds = getLineBounds(forLine: line, at: lineIndex, ofFrame: frame, inFrameRect: frameBounds, in: context)
                    
                    if lineBounds.contains(rightPosition) {
                        print("lineBounds", lineBounds)
                        printLine(line: line)
                        var apos = position
                        if verticalLayout {
                            apos = CGPoint(x: position.y, y: position.x)
                        }
                        // CTLineGetStringIndexForPosition only cares point.x, so it is not very reliable
                        let hitStringIndex = CTLineGetStringIndexForPosition(line, apos)
                        print("string index for position: ", hitStringIndex)
                        // to be tuned...
                        let stringRange = CFRangeMake(hitStringIndex - 1, 1)
                        printRange(selectionRange: stringRange)

                       
                        var selRect = CGRect(origin: lineBounds.origin, size: lineBounds.size)
//                        selRect.origin.y = self.bounds.size.height - lineBounds.origin.y
//                        selRect.origin.x = lineBounds.origin.x
//                        print("selRect", selRect)
                        context.setFillColor(UIColor.blue.withAlphaComponent(0.5).cgColor)
                        context.fill(selRect)
                        break
                    }
                }
            }
        }
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
    
    func getLineBounds(forLine line: CTLine, at lineIndex: CFIndex, ofFrame frame: CTFrame, inFrameRect frameBounds: CGRect, in context: CGContext) -> CGRect {
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        
        let lineWidth = CTLineGetTypographicBounds(line, &ascent, &descent, &leading)
//        print("line width: ", lineWidth)
        let rect = CTLineGetBoundsWithOptions(line, CTLineBoundsOptions.useOpticalBounds)
        print("CTLineGetBoundsWithOptions", rect)
//        let rect2 = CTLineGetImageBounds(line, context)
//        print("CTLineGetImageBounds", rect2)
        
        var lineOrigin: CGPoint = .zero
        CTFrameGetLineOrigins(frame, CFRangeMake(lineIndex, 1), &lineOrigin)
        let stringRange = CTLineGetStringRange(line)
        let offsetInLine: CGFloat = CTLineGetOffsetForStringIndex(line, stringRange.location + stringRange.length, nil)
        print("offsetInLine", offsetInLine, "frameBounds.origin.x", frameBounds.origin.x, "frameBounds.origin.y", frameBounds.origin.y)
        
//        print("lineOrigin", lineOrigin)
        var selectionBounds: CGRect = .zero
        if verticalLayout {
            selectionBounds.origin.x = (frameBounds.origin.x + lineOrigin.x + rect.origin.x) - rect.height/2
            selectionBounds.origin.y = frameBounds.size.height - offsetInLine + frameBounds.origin.y// ((lineOrigin.y + rect.origin.y)) // there must be a offset
            print("lineOrigin.y", lineOrigin.y, "rect.origin.y", rect.origin.y)
            let y = (lineOrigin.y + frameBounds.origin.y) - (descent + leading)
//            print("(lineOrigin.y + frameBounds.origin.y) - (descent + leading)", y, "selectionBounds.origin.y", selectionBounds.origin.y)
            
            selectionBounds.size.width = rect.size.height
            selectionBounds.size.height = rect.size.width
        } else {
            selectionBounds.origin.x = (frameBounds.origin.x + lineOrigin.x + rect.origin.x)
            var y = frameBounds.size.height - lineOrigin.y + frameBounds.origin.y - (rect.height)
            print("ascent", ascent, "descent", descent, "leading", leading)
//            if y < 0 {
//                y = 0
//            }
//            y = self.bounds.size.height - y
            selectionBounds.origin.y = y
            print("lineOrigin.y", lineOrigin.y, "rect.origin.y", rect.origin.y)
            selectionBounds.size = rect.size
        }
        
        print("selectionBounds", selectionBounds)
        printLine(line: line)
//        print("lineOrigin", lineOrigin, "frameBounds.origin", frameBounds.origin, "ascent", ascent, "descent", descent, "leading", leading)
        
        return selectionBounds
    }
    
    struct SelectionInfo: Comparable {
        static func < (lhs: CTSelectionView.SelectionInfo, rhs: CTSelectionView.SelectionInfo) -> Bool {
            return lhs.stringIndex < rhs.stringIndex
        }
        
        let line: CTLine
        let lineIndex: Int
        let stringIndex: Int
        
    }
    
    func prepareSelection(between point1: CGPoint, and point2: CGPoint, in frame: CTFrame, in context: CGContext) {
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
                print("frameBounds", frameBounds)
                // if position locates in this frame path, iterates lines of this frame
                let lines = CTFrameGetLines(frame)
                let lineCount = CFArrayGetCount(lines)
                
                var selectionEndPointInfo1, selectionEndPointInfo2: SelectionInfo?
                
                for lineIndex in 0 ..< lineCount {
                    let line = unsafeBitCast(CFArrayGetValueAtIndex(lines, lineIndex), to: CTLine.self)
                    let lineBounds = getLineBounds(forLine: line, at: lineIndex, ofFrame: frame, inFrameRect: frameBounds, in: context)
                    
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
                    print("startLineIndex", startStringIndex, "endLineIndex", endStringIndex)
                    
                    let selectionRange = NSRange(location: startStringIndex - 1, length: endStringIndex - startStringIndex)
                    printRange(selectionRange: CFRangeMake(startStringIndex - 1, endStringIndex - startStringIndex))
                    
                    self.selectionRange = selectionRange
                    
                    return
                }
            }
        }
    }
    
    
    func getSelectionPointInfo(for point: CGPoint, line: CTLine, lineIndex: Int, lineBounds: CGRect) -> SelectionInfo? {
        
        var stringIndex: Int = -1
        
        // find the line that contains point2
        if lineBounds.contains(point) {
            print("lineBounds", lineBounds)
            //            printLine(line: line)
            var rightPosition: CGPoint = point
            // if vertical layout, should transpose point in order to get the right hit string index
            if verticalLayout {
                rightPosition = CGPoint(x: point.y, y: point.x)
            }
            stringIndex = CTLineGetStringIndexForPosition(line, rightPosition)
            print("stringIndex", stringIndex)
            //            let stringRange = CTLineGetStringRange(line)
            //            print("stringRange", stringRange)
            
            return SelectionInfo(line: line, lineIndex: lineIndex, stringIndex: stringIndex)
        }
        
        return nil
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.translateBy(x: 0.0, y: self.bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.textMatrix = .identity
        
//        print("touchPosition1", touchPosition1, "touchPosition2", touchPosition2)
//        if let touchPosition1 = touchPosition1, let touchPosition2 = touchPosition2 {
//            self.prepareSelection(between: touchPosition1, and: touchPosition2, in: frames![0], in: context)
//        }
        
        context.setStrokeColor(UIColor.red.cgColor)
        context.stroke(self.bounds)
        
        selectionLine(at: self.tapPosition, in: context)
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
        if let selectionRange = self.selectionRange {
            var selectionAttributes = [NSAttributedStringKey.backgroundColor : UIColor.init(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.9).cgColor]
            selectionAttributes[.foregroundColor] = UIColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0).cgColor
            self.textStorge.addAttributes(selectionAttributes, range: selectionRange)
            self.selectionRange = nil
        }
        
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

