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
            self.attributedText = nil
            self.document = nil
            loadText()
        }
    }
    
    var attributedText: NSAttributedString? {
        didSet {
            self.text = nil
            self.document = nil
            loadText()
        }
    }
    
    var document: String? {
        didSet {
            self.text = nil
            self.attributedText = nil
            loadText()
        }
    }
    
    var textView: PagerView
    
    
    init(textView: PagerView) {
        self.textView = textView
    }
    
    private func loadText() {
        if let text = self.text {
            
        } else if let attributedText = self.attributedText {
            
        } else if let document = self.document {
            let asd = AttributedStringDoc(withFileNameFromBundle: document)
            textView.reset(doc: asd)
        }
        
    }
    
}
