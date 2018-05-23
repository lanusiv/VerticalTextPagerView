//
//  LYTextView.swift
//  VerticalTextPagerView
//
//  Created by Leray Lanusiv on 5/22/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

let defaultFontName: String = "STHeitiSC-Light"
let defaultFontSize: CGFloat = 20.0

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
    
    var columnCount = 2
    
    var scrollFeedbackFromOtherControl: Bool = true
    
    let fontSize: CGFloat = defaultFontSize
    var fontDesc: UIFontDescriptor!
    
    
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
        fontDesc = UIFontDescriptor(name: defaultFontName, size: fontSize)
        self.isPagingEnabled = true
        self.showsHorizontalScrollIndicator = false
        self.showsVerticalScrollIndicator = false
        
        self.pageWidth = self.bounds.width
        contentView.frame = self.bounds
        self.addSubview(contentView)
        self.delegate = self
    }
    
    
    func loadText(withAttrString attrString: NSAttributedString) {
        
        // prepare attributed string
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
        
        
        // init ctframes and page views
        var pageView: LYCoreTextView
        var textPos = 0
        var pageIndex: CGFloat = 0
        
        while textPos < attrString.length {
            
            // init paths and frames
            let columnPaths = self.createColumns(withColumnCount: columnCount)
            let pathCount = columnPaths.count
            var frames = [CTFrame]()
            var images = [(image: UIImage, frame: CGRect)]()
            
            // Create a frame for each column (path).
            for column in 0 ..< pathCount {
                // Get the path for this column.
                let path = columnPaths[column]
                
                // Create a frame for this column and draw it.
                let frame = CTFramesetterCreateFrame(
                    framesetter, CFRangeMake(textPos, 0), path,  frameAttributes as CFDictionary)
                
                frames.append(frame)
                if let imageDict = self.imageDict {
                    images = self.attachImagesWithFrame(imageDict, ctframe: frame)
                }
                // Start the next frame at the first character not visible in this frame.
                let frameRange: CFRange = CTFrameGetVisibleStringRange(frame)
                textPos += frameRange.length
            }
            
            // setup page views
            let offsetX = isVerticalLayout ? -pageIndex * pageWidth : pageIndex * pageWidth
            let pageFrame = self.bounds.offsetBy(dx: offsetX, dy: 0)
            
            pageView = LYCoreTextView(frame: pageFrame, ctframes: frames, pageNumber: Int(pageIndex), images: images)
            contentView.addSubview(pageView)
            pageView.name = "page # \(pageIndex)"
            
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
            columnRects[column] = columnRects[column].insetBy(dx: 20.0, dy: 10.0)
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
                    
                    let path = CTFrameGetPath(ctframe)
                    let frameBounds = path.boundingBox
                    let topOffset = self.bounds.maxY - frameBounds.maxY
                    let xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location + 1, nil) + topOffset
                    //                    print("xOffset", xOffset, "origins[lineIndex].y", origins[lineIndex].y)
                    imgBounds.origin.x = origins[lineIndex].x - imgBounds.width / 2 + frameBounds.origin.x
                    imgBounds.origin.y = self.bounds.height - xOffset// + frameBounds.origin.y// + origins[lineIndex].y
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
    
    var pageNumber: Int = 0
    
    var images: [(image: UIImage, frame: CGRect)] = []
    
    let fontSize: CGFloat = defaultFontSize
    var fontDesc: UIFontDescriptor!
    
    let showPinyin = true
    
    // MARK: - Initializers
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    required init(frame: CGRect, ctframes: [CTFrame], pageNumber: Int, images: [(image: UIImage, frame: CGRect)] = []) {
        super.init(frame: frame)
        backgroundColor = .white
        self.pageNumber = pageNumber
        
        self.frames = ctframes
        self.images = images
        
        fontDesc = UIFontDescriptor(name: defaultFontName, size: fontSize)
    }
    
    func addSelectionView() {
        if self.selectionView == nil {
            let selectionView = SelectionView.initSelectionView(self)
            print("self.frame", self.frame, "self.bounds", self.bounds)
//            selectionView.backgroundColor = UIColor.green.withAlphaComponent(0.1)
            self.selectionView = selectionView
        }
        if showPinyin {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Life Cycle
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        
        
        if showPinyin {
            if self.textStorage.length > 0 {
                self.drawPinyin(context)
            }
        }
        
        if let frames = self.frames {
            for frame in frames {
                let path = CTFrameGetPath(frame)
                
                // draw column path
                context.setStrokeColor(red: 0.0, green: 0.6, blue: 0.0, alpha: 1.0)
                context.addPath(path)
                context.strokePath()
                
                CTFrameDraw(frame, context)
            }
        }
        
        drawPageNumber(context)
        
        for imageData in images {
            if let image = imageData.image.cgImage {
                let imgBounds = imageData.frame
                context.draw(image, in: imgBounds)
            }
        }
    }
    
    fileprivate func drawPageNumber(_ context: CGContext) {
        // draw page number
        let font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
        let footageText = String(describing: pageNumber + 1)
        let attrString = NSAttributedString(string: footageText, attributes: [.font : font])
        
        let footageLine = CTLineCreateWithAttributedString(attrString)
        let halfTextWidth = CGFloat(CTLineGetTypographicBounds(footageLine, nil, nil, nil) / 2)
        
        context.textPosition = CGPoint(x: self.bounds.midX - halfTextWidth, y: self.bounds.minY)
        CTLineDraw(footageLine, context)
    }
    
    func drawPinyin(_ context: CGContext) {
        guard let frames = self.frames else { return }
        
        for frame in frames {
            let path = CTFrameGetPath(frame)
            let frameBounds = path.boundingBox
            let lines = CTFrameGetLines(frame) as! [CTLine]
            
            var lineIndex = 0
            for line in lines {
                var lineOrigin = CGPoint.zero
                CTFrameGetLineOrigins(frame, CFRangeMake(lineIndex, 1), &lineOrigin)
                let font = UIFont(descriptor: fontDesc, size: fontDesc.pointSize)
                let fontRect = CTFontGetBoundingBox(font)
                
                let lineRect = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
                
                let lineWidth = fontRect.height //lineRect.height
                let lineHeight = lineRect.width
                
                var vLineRect = CGRect.zero
                vLineRect.origin.x = lineOrigin.x - lineWidth / 2 + frameBounds.origin.x
                vLineRect.origin.y = frameBounds.height - lineOrigin.y + frameBounds.origin.y
                vLineRect.size.width = lineWidth
                vLineRect.size.height = frameBounds.height
                
                // debug, show line rect
                //                context.setStrokeColor(UIColor.red.cgColor)
                //                context.stroke(vLineRect)
                
                let stringRangeRef = CTLineGetStringRange(line)
                let stringRange = NSRange(location: stringRangeRef.location, length: stringRangeRef.length)
                
                
                var previousOffset: CGFloat = 0.0
                //                previousOffset = CTLineGetOffsetForStringIndex(line, 9, nil)
                for index in stringRange.lowerBound ... stringRange.upperBound {
                    print("index", index)
                    if index % 2 != 0 {
                        continue
                    }
                    
                    
                    let offset = CTLineGetOffsetForStringIndex(line, index, nil)
                    
                    // the effective way to calculate one word height
                    // we don't use fontRect.height because it only gives us the word itself's height, not inclouding space between adjacent words. For example, when kerning is set to be a large value, this way would not work as you wish
                    let wordHeight = offset - previousOffset
                    
                    //
                    if index > 0 {
                        // because next index will be (index + 2), its previous is (index + 1)
                        previousOffset = CTLineGetOffsetForStringIndex(line, index + 1, nil)
                    }
                    //                    previousOffset = offset
                    
                    print("offset", offset, "wordHeight", wordHeight, "vLineRect", vLineRect)
                    var wordRect = CGRect(origin: .zero, size: fontRect.size)
                    wordRect.origin.x = vLineRect.origin.x
                    wordRect.origin.y = frameBounds.height - offset + vLineRect.origin.y
                    wordRect.size.height = wordHeight
                    
                    // debug, show word rect
                    //                    context.setStrokeColor(UIColor.blue.cgColor)
                    //                    context.stroke(wordRect)
                    
                    print("wordRect", wordRect)
                    
                    // debug, show furigana rect
                    var pinyinRect = CGRect.zero
                    pinyinRect.origin.x = wordRect.maxX - 2
                    pinyinRect.origin.y = wordRect.minY
                    pinyinRect.size.width = 20 // linespacing
                    pinyinRect.size.height = wordRect.height
                    
                    
                    //                    context.setStrokeColor(UIColor.red.cgColor)
                    //                    context.stroke(pinyinRect)
                    
                    let wordRange = NSRange(location: index - 1, length: 1)
                    let word = textStorage.attributedSubstring(from: wordRange).string
                    let pinyin = word.pinyin()
                    print("word", word, "pinyin", pinyin)
                    //                    let str = "hàn"
                    
                    
                    let pinyinFontSize = self.fontDesc.pointSize * 0.7
                    let fontDesc = UIFontDescriptor(name: "STHeitiSC-Light", size: pinyinFontSize)
                    let font = UIFont(descriptor: fontDesc, size: fontDesc.pointSize)
                    
                    self.showGlyphs(inRect: pinyinRect, font: font, string: pinyin, context: context)
                    
                    //                    let gFont = UIFont.systemFont(ofSize: pinyinFontSize)
                    //                    drawPinyinFrames(context, pinyinString: pinyin, font: gFont, inRect: pinyinRect)
                    
                }
                //                break
                lineIndex += 1
            }
            
//            CTFrameDraw(frame, context)
        }
    }
    
    func drawPinyinFrames(_ context: CGContext, pinyinString: String, font: CTFont, inRect rect: CGRect) {
        let attrString = NSMutableAttributedString(string: pinyinString)
        let fullRange = NSRange(location: 0, length: pinyinString.count)
        attrString.addAttribute(.font, value: font, range: fullRange)
        
        var alignment = CTTextAlignment.center
        let alignmentSetting = CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout.size(ofValue: alignment), value: &alignment)
        var settings = [CTParagraphStyleSetting]()
        settings.append(alignmentSetting)
        let style = CTParagraphStyleCreate(settings, settings.count)
        attrString.addAttribute(.paragraphStyle, value: style, range: fullRange)
        
        let path = CGMutablePath()
        path.addRect(rect)
        var frameAttributes: CFDictionary?
        if isVerticalLayout {
            frameAttributes = [kCTFrameProgressionAttributeName as NSAttributedStringKey: NSNumber(value: CTFrameProgression.rightToLeft.rawValue)] as CFDictionary
        } else {
            frameAttributes = nil
        }
        
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let gframe = CTFramesetterCreateFrame(
            framesetter, CFRangeMake(0, 0), path, frameAttributes)
        
        CTFrameDraw(gframe, context)
    }
    
    func showGlyphs(inRect rect: CGRect, font: UIFont, string: String, context: CGContext) {
        // Get the string length.
        let count: CFIndex = CFStringGetLength(string as CFString)
        
        // Allocate our buffers for characters and glyphs.
        var characters = [UniChar](repeating: UniChar(), count: count)
        var glyphs = [CGGlyph](repeating: CGGlyph(), count: count)
        
        // Get the characters from the string.
        CFStringGetCharacters(string as CFString, CFRangeMake(0, count), &characters)
        
        // Get the glyphs for the characters.
        CTFontGetGlyphsForCharacters(font, &characters, &glyphs, count)
        
        //        let glyphHeight = rect.height / CGFloat(count)
        var positions = [CGPoint](repeating: CGPoint.zero, count: count)
        
        var advances = [CGSize](repeating: .zero, count: count)
        let sum = CTFontGetAdvancesForGlyphs(font, .vertical, glyphs, &advances, count)
        print("sum", sum)
        
        //        context.setFillColor(UIColor.red.withAlphaComponent(0.3).cgColor)
        //        context.fill(rect)
        let fontRect = CTFontGetBoundingBox(font)
        var tunedRect = rect
        let height = fontRect.width / 2 * CGFloat(count)//CGFloat(sum) - rect.size.height
        tunedRect.origin.y -= (height - rect.size.height) / 2
        tunedRect.size.height = height
        //        if rect.size.height < height {
        //            tunedRect.origin.y -= (height - rect.size.height) / 2
        //            tunedRect.size.height = height
        //        } else if rect.size.height > height {
        //
        //        }
        //        context.setStrokeColor(UIColor.blue.cgColor)
        //        context.stroke(tunedRect)
        
        var columnRects = [CGRect](repeating: CGRect.zero, count: count)
        // Set the first column to cover the entire view.
        columnRects[0] = tunedRect
        // Divide the columns equally across the frame's width.
        let columnHeight = tunedRect.size.height / CGFloat(count)
        
        for column in 0 ..< count - 1 {
            let (slice, remainder) = columnRects[column].divided(atDistance: columnHeight, from: .maxYEdge)
            columnRects[column] = slice
            columnRects[column + 1] = remainder
        }
        
        print("rect", tunedRect)
        for i in 0 ..< columnRects.count {
            positions[i] = columnRects[i].origin
            positions[i].y = columnRects[i].maxY
            print("position #\(i)", positions[i])
        }
        
        // recreate font for glyph rotation
        let fontDesc = font.fontDescriptor
        var matrix = CGAffineTransform(rotationAngle: -.pi/2)
        let ctFont = CTFontCreateWithFontDescriptor(fontDesc, fontDesc.pointSize, &matrix)
        //        drawGlyphPath(glyphs, &positions, ctFont, context)
        let color: UIColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        context.setFillColor(color.cgColor)
        CTFontDrawGlyphs(ctFont, glyphs, positions, count, context)
    }
    
    fileprivate func drawGlyphPath(_ glyphs: [CGGlyph], _ positions: inout [CGPoint], _ font: CTFont, _ context: CGContext) {
        var index = 0
        for glyph in glyphs {
            let position = positions[index]
            var transform = CGAffineTransform(translationX: position.x, y: position.y)
            if let glyphPath = CTFontCreatePathForGlyph(font, glyph, &transform) {
                print("glyphPath", glyphPath)
                context.setStrokeColor(UIColor.red.cgColor)
                context.addPath(glyphPath)
                //                context.fillPath()
            }
            index += 1
        }
        context.setLineWidth(1.0)
        context.strokePath()
        //        context.fillPath()
    }
    
    func getGlyphPositions(forString string: String, font: CTFont, textRect: CGRect, isVerticalLayout: Bool) -> (glyphs: [CGGlyph], positions: [CGPoint]) {
        
        let text = NSString(string: string)
        let length = text.length
        
        var chars = [UniChar](repeating: UniChar(), count: length)
        var glyphs = [CGGlyph](repeating: CGGlyph(), count: length)
        var positions = [CGPoint](repeating: .zero, count: length)
        var advances = [CGSize](repeating: .zero, count: length)
        
        text.getCharacters(&chars, range: NSRange(location: 0, length: length))
        CTFontGetGlyphsForCharacters(font, chars, &glyphs, length)
        let orientation: CTFontOrientation = isVerticalLayout ? .vertical : .default
        
        let sum = CTFontGetAdvancesForGlyphs(font, orientation, glyphs, &advances, length)
        print("CTFontGetAdvancesForGlyphs, sum", sum)
        
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.red.cgColor)
            context.stroke(textRect)
        }
        
        var position = textRect.origin
        for i in 0 ..< length {
            positions[i] = CGPoint(x: position.x, y: position.y)
            let advance = advances[i]
            print("advance", advance)
            if isVerticalLayout {
                position.x += advance.height
                position.y += advance.width
            } else {
                position.x += advance.width
                position.y += advance.height
            }
            
        }
        
        if isVerticalLayout {
            positions.reverse()
        }
        
        
        return (glyphs, positions)
    }
    
    func printRange(selectionRange: CFRange) {
        let selectionString = self.textStorage.attributedSubstring(from: NSRange(location: selectionRange.location, length: selectionRange.length))
        print("printRange, ", selectionString.string)
    }
    
    func printLine(line: CTLine) {
        let selectionRange = CTLineGetStringRange(line)
        let selectionString = self.textStorage.attributedSubstring(from: NSRange(location: selectionRange.location, length: selectionRange.length))
        print("printLine, ", selectionString.string)
    }
    
}
