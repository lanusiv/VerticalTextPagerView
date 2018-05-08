//
//  CTView.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/23/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class CTView: UIView {
    
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        let textRect = rect
        // Flip coordinate system vertically.
        context.saveGState();
        let rectHeight = textRect.size.height;
        context.translateBy(x: 0.0, y: rectHeight)
        context.scaleBy(x: 1.0, y: -1.0)
        
        //        let rotationTransform = CGAffineTransform(rotationAngle: .pi)
        //        context.concatenate(rotationTransform);
        
        let pointSize: CGFloat = 30.0
        
                let fontDescriptor = CTFontDescriptorCreateWithNameAndSize("楷体" as CFString, pointSize)
        
        let font = CTFontCreateUIFontForLanguage(.system, pointSize, nil)
//        let font = CTFontCreateWithFontDescriptor(fontDescriptor, pointSize, nil)
        context.textMatrix = .identity
        
        let attributes: [NSAttributedStringKey : Any] = [.font: font,
                                                         .foregroundColor: UIColor.black.cgColor,
//                                                         kCTVerticalFormsAttributeName as NSAttributedStringKey: NSNumber(value: true)
                                                ]
        
        //
        let string = """
        關關雎鳩，在河之洲。窈窕淑女，君子好逑。
        參差荇菜，左右流之。窈窕淑女，寤寐求之。
        求之不得，寤寐思服。悠哉悠哉，輾轉反側。
        參差荇菜，左右采之。窈窕淑女，琴瑟友之。
        參差荇菜，左右芼之。窈窕淑女，鐘鼓樂之。
        Hello, World!
        """

        let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
        
        var alignment: CTTextAlignment = .left
        
        var lineBreakMode: CTLineBreakMode = .byWordWrapping
        
        let leading: CGFloat = 2.0
        
        var lineHeight = pointSize + leading
        
        let paragraphStyleSettings: [CTParagraphStyleSetting] =
            [
                CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout<CTTextAlignment>.size, value: &alignment),
                //
                CTParagraphStyleSetting(spec: .lineBreakMode, valueSize: MemoryLayout<CTLineBreakMode>.size, value: &lineBreakMode),
                
                CTParagraphStyleSetting(spec: .minimumLineHeight, valueSize: MemoryLayout.size(ofValue: lineHeight), value: &lineHeight),
                
                CTParagraphStyleSetting(spec: .maximumLineHeight, valueSize: MemoryLayout.size(ofValue: lineHeight), value: &lineHeight)
                
                // Very important: Do not set kCTParagraphStyleSpecifierLineSpacing too,
                // or it will be added again!
        ];
        
        let paragraphStyle = CTParagraphStyleCreate(paragraphStyleSettings, paragraphStyleSettings.count)
        
        let stringRange = NSMakeRange(0, attributedString.length)
        
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: stringRange)
        attributedString.addAttribute(kCTVerticalFormsAttributeName as NSAttributedStringKey, value: NSNumber(value: true), range: NSMakeRange(0, 104))
//        attributedString.addAttribute(kCTVerticalFormsAttributeName as NSAttributedStringKey, value: NSNumber(value: true), range: NSMakeRange(100, 12))
        
        let path = CGMutablePath()
        path.addRect(textRect)
        
        
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        
        let frameAttrs: [NSAttributedStringKey : Any] = [kCTFrameProgressionAttributeName as NSAttributedStringKey:  NSNumber(value: Int8(CTFrameProgression.rightToLeft.rawValue))]
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, frameAttrs as CFDictionary)
        
        let lines = CTFrameGetLines(frame)
        let lineCount = CFArrayGetCount(lines)
        let range = CFRangeMake(0, 0)
        var lineOrigins = [CGPoint](repeating: CGPoint.zero, count: lineCount)
        CTFrameGetLineOrigins(frame, range, &lineOrigins)
        
        // draw vertical lines by setting 2 attributes
        // kCTFrameProgressionAttributeName: CTFrameProgression.rightToLeft for frame attribute
        // kCTVerticalFormsAttributeName: NSNumber(value: true) for string attribute
        CTFrameDraw(frame, context)
//        drawVerticalLines(context)
        
        context.setFillColor(UIColor.black.cgColor)
        context.fillPath()
        
        context.restoreGState()
    }
    
    func drawVerticalLines(_ context: CGContext) {
        let string1 = "關關雎鳩，在河之洲。窈窕淑女，君子好逑。"
        let string2 = "參差荇菜，左右流之。窈窕淑女，寤寐求之。"
        drawVerticalLine(forString: string1, withOffset: 0.0, context)
        drawVerticalLine(forString: string2, withOffset: 30.0, context)
    }
    // MARK: - draw vertical line using CTLineDraw()
    func drawVerticalLine(forString string: String, withOffset offset: Float, _ context: CGContext) {
        let attrString = NSAttributedString(string: string, attributes: [kCTVerticalFormsAttributeName as NSAttributedStringKey: NSNumber(value: true)])
        let tAttributes = [kCTFrameProgressionAttributeName as NSAttributedStringKey:  NSNumber(value: Int8(CTFrameProgression.rightToLeft.rawValue))]
        let typesetter = CTTypesetterCreateWithAttributedStringAndOptions(attrString, tAttributes as CFDictionary)
        
        let range = CFRange(location: 0, length: attrString.length)
//        let line = CTTypesetterCreateLine(typesetter, range)
        let line = CTLineCreateWithAttributedString(attrString)
        
        let rotate = CGAffineTransform(rotationAngle: -.pi/2)
        context.textMatrix = rotate
        context.textPosition = CGPoint(x: bounds.size.width - 30.0 - CGFloat(offset), y: bounds.size.height - 30.0)
        CTLineDraw(line, context)
    }
    
    // MARK: - get glyph path and rotate font matrix and draw
    /*
     let lineHeight = CTFontGetAscent(font!) + CTFontGetDescent(font!)
     print("line height: \(lineHeight)")
     for glyphIndex in 0 ..< glyphCount {
         let position = CGPoint(x: bounds.width - 30, y: 600 - lineHeight * CGFloat(glyphIndex))
         var fontMatrix = CTFontGetMatrix(font!)
         fontMatrix = fontMatrix.translatedBy(x: position.x, y: position.y)
         fontMatrix = fontMatrix.rotated(by: -.pi/2)
         print("glyph: \(glyphs[glyphIndex]), character: \(characters[glyphIndex])")
         if let glyphPath = CTFontCreatePathForGlyph(font!, glyphs[glyphIndex], &fontMatrix) {
         context.addPath(glyphPath)
         //                print("glyph path: \(glyphPath)")
         }
     }
     
     print("glyphs count: \(glyphs.count), characters count: \(characters.count)")
     
     */
    
}

