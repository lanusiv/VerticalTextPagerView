//
//  AttributedStringDoc.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/28/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit
import Foundation
import CoreGraphics


typealias ASDFeaturesBits = Int

enum ASDFrameType : Int {
    case empty = 0
    //Empty frame
    case textFlow = 1
    //Text for document flows into this frame
    case text = 2
    //Frame contains text specific to it (does not draw from document's "global" text)
    case picture = 3
    //Frame contains an image file CG can draw
    static let typeDefault: ASDFrameType  = .empty
}
//typealias ASDFrameType = Int

enum ASDFeatures: Int {
    case asdFeaturesDefault = 0
    static let asdFeaturesSmallCaps: Int = 1 << 0
    static let asdFeaturesLigatures: Int = 1 << 1
    static let asdFeaturesPropNumbers: Int = 1 << 2
    static let asdFeaturesStylisticVariants: Int = 1 << 3
    // we'll handle up to 16 predefined features
    case asdFeaturesFeatureMask = 0xff
}

let ASD_SMALL_CAPITALS = "Small Capitals"
let ASD_RARE_LIGATURES = "Rare Ligatures"
let ASD_PROP_NUMBERS = "Proportional Numbers"
let ASD_STYLISTIC_VARS = "Stylistic Variants"

//Document level keys

let ASD_VERSION = "ASD_VERSION"
let ASD_PAGE_LAYOUT = "ASD_PAGE_LAYOUT"
//optional
let ASD_STRING_DICT = "ASD_STRING_DICT"
//optional
let ASD_SHOW_PAGE_NUMBER = "ASD_SHOW_PAGE_NUMBER"
//optional - default is not to show page numbers
//String Dict Keys
let ASD_STRING = "ASD_STRING"
let ASD_RANGES = "ASD_RANGES"
let ASD_FONT = "ASD_FONT"
//Page layout keys
let ASD_PAGE_LAYOUT_COLUMNS = "ASD_PAGE_LAYOUT_COLUMNS"
let ASD_PAGE_LAYOUT_BACKGROUND_COLOR = "ASD_PAGE_LAYOUT_BACKGROUND_COLOR"
let ASD_PAGE_LAYOUT_VERTICAL = "ASD_PAGE_LAYOUT_VERTICAL"
// NOTE: vertical glyphs as of iOS 4 SDK are only supported on the Desktop - when they are enabled
// this sample code will display glyphs properly rotated in vertical lines
let ASD_PAGE_LAYOUT_FRAMES = "ASD_PAGE_LAYOUT_FRAMES"
let ASD_PAGE_LAYOUT_FRAME_TYPE = "ASD_PAGE_LAYOUT_FRAME_TYPE"
let ASD_PAGE_LAYOUT_FRAME_RECT = "ASD_PAGE_LAYOUT_FRAME_RECT"
let ASD_PAGE_LAYOUT_FRAME_VALUE = "ASD_PAGE_LAYOUT_FRAME_VALUE"
let ASD_PAGE_LAYOUT_ACCESSIBILITY_VALUE = "ASD_PAGE_LAYOUT_ACCESSIBILITY_VALUE"
let ASD_PAGE_LAYOUT_FRAME_HORIZONTAL = "ASD_PAGE_LAYOUT_FRAME_HORIZONTAL"
//overrides page setting
let ASD_PAGE_LAYOUT_FRAME_VERTICAL = "ASD_PAGE_LAYOUT_FRAME_VERTICAL"
//overrides page setting
let ASD_VersionNumber: Int = 1
//version indicates the structure (shema) of the file. Different versions are generally incompatible
let ASD_ContentNumber: Int = 1
//content indicates meaning of the data in the structure. at times the meaning of the data is irrelevant while processing (say dumping the contents of the file) but generally a changed value indicates an incompatibility
let ASD_ParagraphStylesSupported: Int = 9


class AttributedStringDoc: NSObject {
    
    // MARK: - Properities
    
    var fileName = ""
    // document filename
    var attributedString: NSAttributedString?
    // document text storage
    var pageLayout = [AnyHashable : Any]()//[Int : [String : Any]]()
    // page layout information
    var columnCount: Int = 0
    var verticalOrientation = false
    var showPageNumbers = false
    private var backgroundColor: CGColor?
    
    // Static helper function to add/validate a font feature to a given feature array
//    private func AddFeature(featureArray: inout [[String : Any]]?, featureSelectorArr: [[String : Any]], featureTypeIdentifierKey: String, matchSelectorName: String, matchSelectorNameAlt: String, value: Bool) -> Bool {
//        for selectorDict in featureSelectorArr {
//            // most of the time the features we are testing for are going to be off, so test that case first
//            if !value && selectorDict[kCTFontFeatureSelectorDefaultKey as String] != nil {
//                // if the setting was off (value is NO) and this is the default value for this feature, then use it
//                let aKey = featureTypeIdentifierKey
//                let aKey1 = selectorDict[kCTFontFeatureSelectorIdentifierKey as String]
////                    featureArray.append([
////                        kCTFontFeatureTypeIdentifierKey as String : aKey,
////                        kCTFontFeatureSelectorIdentifierKey as String : aKey1
////                        ])
//                    featureArray += [[
//                        kCTFontFeatureTypeIdentifierKey as String : aKey,
//                        kCTFontFeatureSelectorIdentifierKey as String : aKey1
//                    ]]
//                if value {
//                    let featureSelectorName = selectorDict?[kCTFontFeatureSelectorNameKey as String] as? String
//                    if featureSelectorName == matchSelectorName || (matchSelectorNameAlt != nil && featureSelectorName == matchSelectorNameAlt) {
//                        // Feature is on and supported, so add it
//                        if let aKey = featureTypeIdentifierKey, let aKey1 = selectorDict?[kCTFontFeatureSelectorIdentifierKey] {
//                            featureArray?.append([
//                                kCTFontFeatureTypeIdentifierKey as String : aKey,
//                                kCTFontFeatureSelectorIdentifierKey as String : aKey1
//                                ])
//                        }
//                        return true
//                    }
//                }
//                return false
//            }
//        }
//        return false
//    }
    
    
    func CreateColorFromRGBComponentsArray(_ components: [CGFloat]) -> CGColor {
        if let color = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: components) {
            return color
        }
        return UIColor.gray.cgColor
    }
    
    // MARK: - Initializers
    override init() {
        super.init()
    }
    
    convenience init(withFileNameFromBundle fileName: String) {
        self.init()
        self.setFileName(fileName)
    }
    
    private func setFileName(_ fileName: String) {
        if self.fileName != fileName {
            self.fileName = fileName
            self.loadWithFileName()
        }
    }
    
    func hasContent() -> Bool {
        return self.attributedString != nil || self.pageLayout.count > 0
    }
    
    func framesForPage(page: Int) -> [Any]? {
        if let pageDesc = self.pageLayout[String(describing: page)] as? [AnyHashable : Any] {
//            print("pageDesc", pageDesc)
            return pageDesc[ASD_PAGE_LAYOUT_FRAMES] as? [Any]
        }
        return nil
    }
    
    func boundsForFrame(frameDesc: Any) -> CGRect? {
        if let frameDesc = frameDesc as? [String : Any] {
            if let frameRectValues = frameDesc[ASD_PAGE_LAYOUT_FRAME_RECT] as? [CGFloat] {
                let frameRect = CGRect(x: frameRectValues[0], y: frameRectValues[1], width: frameRectValues[2], height: frameRectValues[3])
                return frameRect
            }
        }
        return nil
    }
    
    func typeForFrame(frameDesc: Any) -> ASDFrameType {
        if let frameDesc = frameDesc as? [String : Any], let rawType = frameDesc[ASD_PAGE_LAYOUT_FRAME_TYPE] as? Int {
            return ASDFrameType(rawValue: rawType)!
        }
        return ASDFrameType.typeDefault
    }
    
    func objectForFrame(_ frame: Any) -> Any? {
//        NSDictionary* frameDict = frameDesc;
        guard let frameDict = frame as? [String : Any] else {
            return nil
        }
        var result = frameDict[ASD_PAGE_LAYOUT_FRAME_VALUE]

        let type = self.typeForFrame(frameDesc: frame)
        
        if let dict = result as? [String : Any], type == .text {
            result = self.attributedStringForASXMLDict(dict, withStringWideAttributes: nil)
        } else if type == .picture, let pictureName = result as? String {
            result = filePathForFileName(pictureName)
        }
        
        return result
    }
    
    func columnsForPage(_ pageNumber: Int) -> Int {
        if let pageDesc = self.pageLayout[String(describing: pageNumber)] as? [AnyHashable : Any] {
            return pageDesc[ASD_PAGE_LAYOUT_COLUMNS] as! Int
        }
        return self.columnCount
    }
    
    func copyColorForPage(page: Int) -> CGColor {
        if let pageDesc = self.pageLayout[String(describing: page)] as? [AnyHashable : Any] {
            if let calibratedRGB = pageDesc[ASD_PAGE_LAYOUT_BACKGROUND_COLOR] as? [CGFloat] {
                return CreateColorFromRGBComponentsArray(calibratedRGB)
//                return UIColor.clear.cgColor
            }
        }
        return UIColor.clear.cgColor
    }
    
    private func filePathForFileName(_ fileName: String) -> String? {
//        print("filePathForFileName fileName: ", fileName)
        var components = fileName.components(separatedBy: ".")
        if components.count == 2 {
            let name = components[0]
            let suffix = components[1]
            return Bundle.main.path(forResource: name, ofType: suffix)
        }
        
        return nil
    }
    
    private func loadWithFileName() {
//        self.pageLayout = nil
        self.attributedString = nil
        self.columnCount = 1
//        self.setColor(ClearColor())
        guard let filePath = self.filePathForFileName(fileName) else {
            print("\(fileName) could not be opened/found")
            return
        }
//        guard let filePath = Bundle.main.path(forResource: "Splash", ofType: "xml") else { return }
//        print("filePath", filePath)
        guard let docDict = NSDictionary(contentsOfFile: filePath) else {
            print("\(filePath) contents cannot be processed")
            return
        }
        
        // Check that document version info is supported
//        let versionArr = docDict[ASD_VERSION]
        
        // Vertical orientation
        if let verticalOrientation = docDict[ASD_PAGE_LAYOUT_VERTICAL] as? Int {
            self.verticalOrientation = verticalOrientation != 0
        }
        
        // Show page numbers on/off
        if let showPageNumbers = docDict[ASD_SHOW_PAGE_NUMBER] as? Int {
            self.showPageNumbers = showPageNumbers != 0
        }
        
        // Number of text columns
        if let columnCount = docDict[ASD_PAGE_LAYOUT_COLUMNS] as? Int {
            self.columnCount = columnCount
        }
        
        // Background color info
//        if let bkgColor =
        
        // Page layout info
        if let pageLayout = docDict[ASD_PAGE_LAYOUT] as? [AnyHashable : Any] {
            self.pageLayout = pageLayout
        }
        
        // actual string data
        if let attrStrDict = docDict[ASD_STRING_DICT] as? [String : Any] {
            self.attributedString = self.attributedStringForASXMLDict(attrStrDict, withStringWideAttributes: nil)
        }
    }
    
    let ParagraphSpecs: [CTParagraphStyleSpecifier] = [ .lineSpacingAdjustment, .paragraphSpacing, .maximumLineHeight, .minimumLineHeight, .headIndent, .tailIndent, .firstLineHeadIndent, .defaultTabInterval ]
    
    private func attributedStringForASXMLDict(_ dict: [String : Any], withStringWideAttributes stringWideAttributes: [NSAttributedStringKey : Any]?) -> NSMutableAttributedString {
        var strBase: NSAttributedString
        let attrString = NSMutableAttributedString()
        if let string = dict[ASD_STRING] as? String {
            strBase = NSAttributedString(string: string)
            attrString.setAttributedString(strBase)
        }
        
        if let ranges = dict[ASD_RANGES] as? [[Any]] {
            for rangeElements in ranges {
                // 0, 1 for range
                guard let loc = rangeElements[0] as? Int, let len = rangeElements[1] as? Int else {
                    break
                }
                let range = NSRange(location: loc, length: len)
                // 2 for dict
                if let rangeDict = rangeElements[2] as? [String : Any] {
                    for (key, value) in rangeDict {
                        if ASD_FONT == key, let fontArray = value as? [Any], let fontName = fontArray[0] as? String, let fontSize = fontArray[1] as? CGFloat/*, let font = UIFont(name: fontName, size: fontSize)*/ {
                            
//                            let font1 = CTFontCreateWithName((CFStringRef)[(NSArray*)obj objectAtIndex:0], [(NSNumber*)[(NSArray*)obj objectAtIndex:1] floatValue], NULL)
                            let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
                            
                            attrString.addAttribute(.font, value: font, range: range)
                        } else if kCTForegroundColorAttributeName as String == key, let colorArray = value as? [CGFloat] {
                            let color = CreateColorFromRGBComponentsArray(colorArray)
                            attrString.addAttribute(.foregroundColor, value: color, range: range)
                        } else if kCTUnderlineStyleAttributeName as String == key {
                            attrString.addAttribute(.underlineStyle, value: value, range: range)
                        } else if kCTVerticalFormsAttributeName as String == key {
                            attrString.addAttribute(.verticalGlyphForm, value: value, range: range)
                        } else if kCTParagraphStyleAttributeName as String == key , let paragStyles = value as? [CGFloat] {
                            assert(paragStyles.count >= ASD_ParagraphStylesSupported, "Wrong number of paragraph styles")
                            var settings = [CTParagraphStyleSetting]()
                            var alignment: CTTextAlignment
                            var floatValues = [CGFloat](repeating: 0.0, count: ASD_ParagraphStylesSupported)
                            
                            
                            alignment = CTTextAlignment(rawValue: UInt8(paragStyles[0]))!
                            settings.append(CTParagraphStyleSetting(spec: .alignment, valueSize: MemoryLayout.size(ofValue: alignment), value: &alignment))
                           
                            
                            var index = 1
                            for styleSpec in ParagraphSpecs {
                                settings.append(CTParagraphStyleSetting(spec: styleSpec, valueSize: MemoryLayout<CGFloat>.size, value: &floatValues[index]))
                                index += 1
                            }
                            let style = CTParagraphStyleCreate(settings, settings.count)
                            attrString.addAttribute(.paragraphStyle, value: style, range: range)
                            
                        } else {
                            print("Unrecognized key: \(key), value: \(value)")
                        }
                    }
                }
            }
        }
        
        if let attr = stringWideAttributes {
            let range = NSRange(location: 0, length: attrString.length)
            attrString.addAttributes(attr, range: range)
        }
        
        return attrString
    }
    
}

