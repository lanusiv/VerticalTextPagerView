//
//  VerticalTextView.swift
//  VerticalTextPagerView
//
//  Created by Leray Lanusiv on 5/21/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import Foundation

protocol TextInterface {
    // for plain text to display
    var text: String? { get set }
    
    // for attributed text to display
    var attributedText: NSAttributedString? { get set }
    
    // for rtf document file to load and display
    var document: String? { get set }
    
    
}

class VerticalTextView: TextInterface {
    
    var text: String? {
        didSet {
            if text != nil {
                loadPlainText()
            }
        }
    }
    
    var attributedText: NSAttributedString? {
        didSet {
            if attributedText != nil {
                loadAttributedText()
            }
        }
    }
    
    var document: String? {
        didSet {
            if document != nil {
                loadDocument()
            }
        }
    }
    
    var textView: PagerView
    
    
    init(textView: PagerView) {
        self.textView = textView
    }
    
    private func loadDocument() {
        let asd = AttributedStringDoc(withFileNameFromBundle: document!)
        textView.reset(doc: asd)
    }
    
    private func loadPlainText() {
        let asd = AttributedStringDoc(text: text!)
        textView.reset(doc: asd)
    }
    
    private func loadAttributedText() {
        let asd = AttributedStringDoc(attributedString: attributedText!, isVerticalOrientation: true)
        textView.reset(doc: asd)
    }
    
    func loadText(_ text: NSAttributedString, withTextImages textImagesDict: [[String : Any]]) {
        let asd = AttributedStringDoc(attributedString: text, isVerticalOrientation: true)
        asd.textImagesDict = textImagesDict
        textView.reset(doc: asd)
    }
    
}
