//
//  VLabel.swift
//  VerticalTextPagerView
//
//  Created by Leray Lanusiv on 6/17/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class VLabel: UIScrollView {

    var text: String? {
        didSet {
            self.attrString = NSAttributedString(string: text!)
        }
    }
    
    var attrString: NSAttributedString? {
        didSet {
            loadText()
        }
    }
    
    var framesetter: CTFramesetter?
    
    private var internalAttrString: NSMutableAttributedString {
        get {
            if let attrString = self.attrString {
                return NSMutableAttributedString(attributedString: attrString)
            } else {
                return NSMutableAttributedString(string: "")
            }
        }
    }
    
    
    var contentView: TextView!
    
    var frameSize: CGSize?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initSetup()
    }
    
    private func initSetup() {
        self.text = "天地不仁，以萬物為芻狗！"//chineseString
    }
    
    private func loadText() {
        // [.verticalGlyphForm: NSNumber(value: true)]
        let attrString = internalAttrString
        
        attrString.addAttribute(.verticalGlyphForm, value: NSNumber(value: true), range: NSRange(location: 0, length: attrString.length))
        
        var frameAttributes: [NSAttributedStringKey : Any] = [:]
        frameAttributes[kCTFrameProgressionAttributeName as NSAttributedStringKey] = NSNumber(value: CTFrameProgression.rightToLeft.rawValue)
        
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        self.framesetter = framesetter
        
        let frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), frameAttributes as CFDictionary, CGSize(width: CGFloat.greatestFiniteMagnitude, height: 200), nil)
        print("frameSize", frameSize)
        
        self.frameSize = frameSize
        
        self.contentSize = frameSize
        
        let textFrame = CGRect(origin: .zero, size: frameSize)
        
        let path = CGMutablePath()
        path.addRect(textFrame)
        
        
        let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, frameAttributes as CFDictionary)
        
        contentView = TextView(frame: textFrame, ctframe: ctframe)
        
        addSubview(contentView)
        
    }
    
}

func getTextCells(_ strings: [String]) -> [TextCell] {
    var cells = [TextCell]()
    
    let verticalStringAttr: [NSAttributedStringKey : Any] = [.verticalGlyphForm : NSNumber(value: true)]
    var frameAttributes: [NSAttributedStringKey : Any] = [:]
    frameAttributes[kCTFrameProgressionAttributeName as NSAttributedStringKey] = NSNumber(value: CTFrameProgression.rightToLeft.rawValue)
    // text and attributes
    
    for string in strings {
        let attrString = NSMutableAttributedString(string: string, attributes: verticalStringAttr)
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        
        let frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), frameAttributes as CFDictionary, CGSize(width: CGFloat.greatestFiniteMagnitude, height: 200), nil)
        print("frameSize", frameSize)
        
        let textFrame = CGRect(origin: .zero, size: frameSize)
        
        let path = CGMutablePath()
        path.addRect(textFrame)
        
        let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, frameAttributes as CFDictionary)
        
        cells.append(TextCell(frame: textFrame, ctframe: ctframe))
    }
    
    return cells
}

struct TextCell {
    var frame: CGRect
    var ctframe: CTFrame
}

//class TextView: UIView {
//    var ctframe: CTFrame!
//
//    required init(frame: CGRect, ctframe: CTFrame) {
//        self.ctframe = ctframe
//        super.init(frame: frame)
//        self.backgroundColor = .clear
//        setNeedsDisplay()
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func draw(_ rect: CGRect) {
//        guard let context = UIGraphicsGetCurrentContext() else { return }
//
//        context.translateBy(x: 0.0, y: self.bounds.height)
//        context.scaleBy(x: 1.0, y: -1.0)
//
//        CTFrameDraw(ctframe, context)
//    }
//}
