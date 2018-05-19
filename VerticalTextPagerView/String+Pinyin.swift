//
//  String+Pinyin.swift
//  VerticalTextPagerView
//
//  Created by Leray Lanusiv on 5/19/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import Foundation

extension String {
    
    func isIncludeChinese() -> Bool {
        for ch in self.unicodeScalars {
            // 中文字符范围：0x4e00 ~ 0x9fff
            if 0x4e00 < ch.value && ch.value < 0x9fff {
                return true
            }
        }
        return false
    }
    
    func pinyin() -> String {
        if !isIncludeChinese() {
            return self
        }
        let stringToTransform = NSMutableString(string: self)//self
        var transformRange = CFRangeMake(0, self.count)
        if CFStringTransform(stringToTransform as CFMutableString, &transformRange, kCFStringTransformToLatin, false) {
            return stringToTransform as String
        }
        return self
    }
}
