//
//  LYLabel.swift
//  VerticalTextPagerView
//
//  Created by Leray Lanusiv on 6/16/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class LYLabel: UIScrollView {

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
        self.text = chineseString
    }
    
    private func loadText() {
        let framesetter = CTFramesetterCreateWithAttributedString(internalAttrString)
        self.framesetter = framesetter
        let frameSize = CTFramesetterSuggestFrameSizeWithConstraints(framesetter, CFRangeMake(0, 0), nil, CGSize(width: self.bounds.width, height: CGFloat.greatestFiniteMagnitude), nil)
        print("frameSize", frameSize)
        self.frameSize = frameSize
        
        self.contentSize = frameSize
        
        let textFrame = CGRect(origin: .zero, size: frameSize)
        
        let path = CGMutablePath()
        path.addRect(textFrame)
        
        let ctframe = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        contentView = TextView(frame: textFrame, ctframe: ctframe)
        
        addSubview(contentView)
        
    }
    
}

class TextView: UIView {
    var ctframe: CTFrame!
    
    required init(frame: CGRect, ctframe: CTFrame) {
        self.ctframe = ctframe
        super.init(frame: frame)
        self.backgroundColor = .clear
        setNeedsDisplay()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.translateBy(x: 0.0, y: self.bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        CTFrameDraw(ctframe, context)
    }
}
