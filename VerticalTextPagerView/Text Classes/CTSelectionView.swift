//
//  CTSelectionView.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/25/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class CTSelectionView: UIView, TextViewSelection {

    // MARK: - Properties
    
    let textStorge = NSMutableAttributedString(string: "")
    
    var attrString: NSAttributedString?
    
    var imageDict: [[String : Any]]?
    
    var stringAttributes: [NSAttributedStringKey : Any] = [:]
    
    var frames: [CTFrame]?
    
    var images: [(image: UIImage, frame: CGRect)] = []
    
    let isVerticalLayout = true
    
    let columnCount = 1
    
    // MARK: - initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // add selection view, to handle selction logic
        let selectionView = SelectionView(view: self)
        print("selectionView.frame", selectionView.frame)
        selectionView.backgroundColor = .clear
        addSubview(selectionView)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.translateBy(x: 0.0, y: self.bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.textMatrix = .identity
        
        self.drawColumnFrames(context)
    }
    
    // MARK: - draw frames into columns
    func drawColumnFrames(_ context: CGContext) {
        let string = chineseString
        let font = CTFontCreateUIFontForLanguage(.system, 20.0, nil)
        self.stringAttributes[.font] = font
        if isVerticalLayout {
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
        if isVerticalLayout {
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
