//
//  TextParser.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/27/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import Foundation
import UIKit

func loadText() -> (attributedString: NSAttributedString, images: [[String : Any]])? {
    guard let file = Bundle.main.path(forResource: "demo", ofType: "txt") else { return nil }
    
    do {
        let text = try String(contentsOfFile: file, encoding: .utf8)
        
        var images: [[String : Any]] = []
        
        let attributedString = NSMutableAttributedString(string: "")
        // stringAttributes[.verticalGlyphForm] = NSNumber(value: true)
//        let pattern = "(\\[image:).*?\\w+\\]"
        
        let regex = try NSRegularExpression(pattern: "(.*?)(<[^>]+>|\\Z)",
                                            options: [.caseInsensitive,
                                                      .dotMatchesLineSeparators])
        //3
        let chunks = regex.matches(in: text,
                                   options: NSRegularExpression.MatchingOptions(rawValue: 0),
                                   range: NSRange(location: 0,
                                                  length: text.characters.count))
//        print(chunks)
        
        for chunk in chunks {
            guard let markupRange = text.range(from: chunk.range) else { continue }
            
            let parts = text[markupRange].components(separatedBy: "<")
            
            let font = UIFont.systemFont(ofSize: 20.0)
            
            let attrs = [.foregroundColor: UIColor.black, .font: font, .verticalGlyphForm: NSNumber(value: true)] as [NSAttributedStringKey : Any]
            let str = NSMutableAttributedString(string: parts[0], attributes: attrs)
            attributedString.append(str)
            
            if parts.count <= 1 {
                continue
            }
            let tag = parts[1]
//            print("tag", tag)
            var tmp = tag.components(separatedBy: " ")[1]
//            print("tmp", tmp)
            tmp.remove(at: tmp.index(before: tmp.endIndex))
            let imageName = tmp
//            print("imageName", imageName)
            
            var width: CGFloat = 0
            var height: CGFloat = 0
            if let image = UIImage(named: imageName) {
                height = font.lineHeight
                width = height * (image.size.width / image.size.height)
            }
            
            images += [["width": NSNumber(value: Float(width)),
                        "height": NSNumber(value: Float(height)),
                        "filename": imageName,
                        "location": NSNumber(value: attributedString.length)]]
            //2
            struct RunStruct {
                let ascent: CGFloat
                let descent: CGFloat
                let width: CGFloat
            }
            
            let extentBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
            extentBuffer.initialize(to: RunStruct(ascent: height, descent: 0, width: width))
            
            var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (pointer) in
            }, getAscent: { (pointer) -> CGFloat in
                let d = pointer.assumingMemoryBound(to: RunStruct.self)
                return d.pointee.ascent
            }, getDescent: { (pointer) -> CGFloat in
                let d = pointer.assumingMemoryBound(to: RunStruct.self)
                return d.pointee.descent
            }, getWidth: { (pointer) -> CGFloat in
                let d = pointer.assumingMemoryBound(to: RunStruct.self)
                return d.pointee.width
            })
            //4
            let delegate = CTRunDelegateCreate(&callbacks, extentBuffer)
            //5
            let attrDictionaryDelegate = [(kCTRunDelegateAttributeName as NSAttributedStringKey): (delegate as Any)]
            attributedString.append(NSAttributedString(string: " ", attributes: attrDictionaryDelegate))
            
        }
        
        return (attributedString, images)
    } catch _ {
    }
    
    return nil
}


// MARK: - String
extension String {
    func range(from range: NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex,
                                       offsetBy: range.location,
                                       limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: range.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) else {
                return nil
        }
        
        return from ..< to
    }
}
