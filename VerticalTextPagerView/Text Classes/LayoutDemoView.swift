//
//  LayoutDemoView.swift
//  VerticalTextDemo2
//
//  Created by Leray Lanusiv on 4/24/18.
//  Copyright © 2018 Leray Lanusiv. All rights reserved.
//

import UIKit

class LayoutDemoView: UIView {

    var attributedString: NSAttributedString?
    let chineseString = """
孝武皇帝，景帝子也。未生之時，景帝夢一赤彘從雲中下，直入崇芳閣。景帝覺而坐閣下，果有赤龍如霧，來蔽戶牖。宮內嬪禦，望閣上有丹霞蓊蔚而起，霞滅，見赤龍盤回棟間。景帝召占者姚翁以問之。翁曰：「吉祥也。此閣必生命世之人，攘夷狄而獲嘉瑞，為劉宗盛主也。然亦大妖。」景帝使王夫人移居崇芳閣，欲以順姚翁之言也。乃改崇芳閣為猗蘭殿。旬餘，景帝夢神女捧日以授王夫人，夫人吞之，十四月而生武帝。景帝曰：「吾夢赤氣化為赤龍，占者以為吉，可名之吉。」至三歲，景帝抱於膝上，撫念之，知其心藏洞徹。試問：「兒樂為天子否？」對曰：「由天不由兒。願每日居宮垣，在陛下前戲弄，亦不敢逸豫，以失子道。」景帝聞而愕然，加敬而訓之。他日，復抱置几前，試問：「兒悅習何書？為朕言之。」乃誦伏羲以來群聖所錄陰陽診候，及龍圖龜策數萬言，無一字遺落。至七歲，聖徹過人，景帝令改名徹。
2     及即位，自景帝子也至此，藏本並脫去，依《廣記》補。好長生之術，《廣記》：好神仙之道。常祭名山大澤，《廣記》：常禱祈名山大川五嶽。按五嶽即名山也，今依藏本。以求神仙。元封元年正月二字依《廣記》補。甲子，祭《廣記》：登。嵩山，起神《廣記》：道。宮。帝齋七日，祠訖乃還。至四月戊辰，帝夜閒居承華殿，東方朔、董仲舒侍。《廣記》侍作在側二字。忽見一女子，著青衣，美麗非常。帝愕然問之，女對曰：「我墉宮玉女王子登也，向為王母所使，從崑山來。」昆山，崑崙山也。《廣記》改昆山為崑崙山而刪注。語帝曰：「聞子輕四海之祿，藏本：尊。依《廣記》改。尋道求生，降帝王之位，而屢禱山嶽。勤哉！有似可教者也。從今百日清齋，不閑人事，不治也。至七月七日，王母暫來也。」帝下席，跪諾。言訖，玉此字依《廣記》補。女忽然不知所在。帝問東方朔：「此何人？」朔曰：「是西王母紫蘭室《廣記》宮。玉女，常傳使命，往來扶桑，出入靈州，交關常陽，傳言玄都。阿母昔以出配北燭仙人，近又召還，使領命祿，真靈官也。」
3     帝於是登延靈之臺，盛齋存道，其四方之事，權委於冢宰焉。至七月七日，乃修除宮掖之內，設座殿上，《廣記》：設坐大殿。以紫?薦地，燔百和之香，張雲錦之帳，《廣記》：幃。然九光之燈，設《廣記》：列。玉門之棗，酌此字依《廣記》補。蒲萄之酒，《廣記》：醴。躬監肴物，《廣記》：宮監香果。為天官之饌。帝乃盛服立於陛《廣記》：階。下，敕端門之內，不得妄有二字《廣記》倒。窺者。內外寂謐。靜肅也。以俟《廣記》：候。雲駕。
4     至二唱之後，即二更也。《廣記》改二唱為二更而刪注。忽天《廣記》：見。西南如白雲起，鬱然直來，徑藏本：遙。依《廣記》改。趨宮庭間。須臾轉近，聞五字依《廣記》補。雲中有簫鼓之聲，人馬之響。復半食頃，王母至也。縣投殿前，有似鳥集。或駕龍虎，或乘獅子，或御白虎，《廣記》無此二句。或騎白麟，或控白鶴，或乘軒藏本：科。依《廣記》改。車，或乘天馬，此句依《廣記》補。群仙數萬，《廣記》：千。光耀庭宇。既至，從官不復知此字依《廣記》補。所在。唯見王母乘紫雲之輦，駕九色斑龍，別有五十天仙，側近鸞輿，皆身長一丈，《廣記》：皆長丈餘。同執彩毛之節，佩此字依《廣記》補。金剛靈璽，戴天真之冠，藏本：帶天策，無之冠二字，依《廣記》補正。咸住殿前。《廣記》：下。王母唯扶二侍女上殿，年可十六七，服青綾之褂，古兮切，裾也，上服。容眸流眄，莫見切，邪視也，作盻非。神姿清發，真美人也。王母上殿，東向坐，著黃錦《廣記》：金。袷（上夾下蜀），上夾下蜀，無絮長襦也。文採鮮明，光儀淑穆。帶靈飛大綬，腰《廣記》有佩字，乃淺人增也。後文云腰流黃揮精之劍。分頭《廣記》：景。之劍。頭上大華結，上花下髻。戴太真晨嬰之冠，履元瓊鳳文之舄。俗刻有映朗云棟神光暐曄二句。檢《廣記》亦無之，未知所本。視之可年卅許，修短得中，天姿掩藹，容藏本：雲。依《廣記》改。顏絕世，真靈人也。下車登床，帝拜跪，二字《廣記》倒。問寒溫《廣記》：暄。畢，立如也。《廣記》無此二字。
"""
    
    
    override func draw(_ rect: CGRect) {
        // Initialize a graphics context in iOS.
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        // Flip the context coordinates, in iOS only.
        context.translateBy(x: 0, y: self.bounds.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Set the text matrix.
        context.textMatrix = .identity
        
        // demos begin
//        demo1(context)
//        demo2(context)
//        demo3(context)
//        demo4(context)
//        demo5(context)
        demo6(context)
        
//        let font = CTFontCreateWithName("宋体" as CFString, 20.0, nil)
//        let string = "😄"
//        getGlyphsForCharacters(font: font, string: string, context: context)
    }
    
    // MARK: demo1
    func demo1(_ context: CGContext) {
        // Create a path which bounds the area where you will be drawing text.
        // The path need not be rectangular.
        let path = CGMutablePath()
        
        // In this simple example, initialize a rectangular path.
        let bounds: CGRect = CGRect(x: 10.0, y: 10.0, width: 200.0, height: 200.0)
        path.addRect(bounds)
        
        // Initialize a string.
        let textString = String("Hello, World! I know nothing in the world that has as much power as a word. Sometimes I write one, and I look at it, until it begins to shine.")
        
        // Create a mutable attributed string with a max length of 0.
        // The max length is a hint as to how much internal storage to reserve.
        // 0 means no hint.
        let attrString = NSMutableAttributedString(string: textString)
        
        // Create a color that will be added as an attribute to the attrString.
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let components: [CGFloat] = [ 1.0, 0.0, 0.0, 0.8 ]
        let red = CGColor(colorSpace: rgbColorSpace, components: components)
        
        // Set the color of the first 12 chars to red.
        attrString.setAttributes([kCTForegroundColorAttributeName as NSAttributedStringKey: red!], range: NSRange(location: 0, length: 12))
        
        // Create the framesetter with the attributed string.
        let framesetter =
            CTFramesetterCreateWithAttributedString(attrString)
        
        // Create a frame.
        let frame = CTFramesetterCreateFrame(framesetter,
                                             CFRange(location: 0, length: 0), path, nil)
        
        // Draw the specified frame in the given context.
        CTFrameDraw(frame, context)
    }
    
    // MARK: - demo2 draw frames into columns
    func demo2(_ context: CGContext) {
        let string = chineseString
        let stringAttributes = [kCTVerticalFormsAttributeName as NSAttributedStringKey: NSNumber(value: true)]
        self.attributedString = NSAttributedString(string: string, attributes: stringAttributes)
        
        // Create the framesetter with the attributed string.
        let framesetter = CTFramesetterCreateWithAttributedString(self.attributedString!)
        let frameAttributes = [kCTFrameProgressionAttributeName as NSAttributedStringKey: NSNumber(value: CTFrameProgression.rightToLeft.rawValue)]
        
        
        let columnPaths = self.createColumns(withColumnCount: 3)
        
        //        let pathCount: CFIndex = CFArrayGetCount(columnPaths)
        let pathCount = columnPaths.count
        var startIndex: CFIndex = 0
        
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
                framesetter, CFRangeMake(startIndex, 0), path, frameAttributes as CFDictionary);
            CTFrameDraw(frame, context)
            
            // Start the next frame at the first character not visible in this frame.
            let frameRange: CFRange = CTFrameGetVisibleStringRange(frame)
            startIndex += frameRange.length
            
            print("start index", startIndex)
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
            let (slice, remainder) = columnRects[column].divided(atDistance: columnWidth, from: .minXEdge)
            columnRects[column] = slice
            columnRects[column + 1] = remainder
        }
        
        // Inset all columns by a few pixels of margin.
        for column in 0 ..< columnCount {
            columnRects[column] = columnRects[column].insetBy(dx: 8.0, dy: 15.0)
        }
        
        // Create an array of layout paths, one for each column.
        var array = [CGMutablePath]()
        
        for column in 0 ..< columnCount {
            let path = CGMutablePath()
            path.addRect(columnRects[column])
            array.append(path)
        }
        // get column paths, reverse paths because we layout vertical text
        return array.reversed()
    }
    
    // MARK: - demo3 Performing manual line breaking
    func demo3(_ context: CGContext) {
//        double width; CGPoint textPosition; CFAttributedStringRef attrString;
        // Initialize those variables.
        let width: Double = Double(self.bounds.size.width)
        let textPosition: CGPoint = CGPoint(x: 10.0, y: self.bounds.size.height - 30.0)
        let string = "Applying a Paragraph Style Listing 2-6 implements a function that applies a paragraph style to an attributed string. The function accepts as parameters the font name, point size, and a line spacing which increases or decreases the amount of space between lines of text. This function is called by the code in Listing 2-7, which creates a plain text string, uses the applyParaStyle function to make an attributed string with the given paragraph attributes, then creates a framesetter and frame, and draws the frame."
        let attrString = NSAttributedString(string: string)
        
        // Create a typesetter using the attributed string.
        let typesetter = CTTypesetterCreateWithAttributedString(attrString)
        
        // Find a break for line from the beginning of the string to the given width.
        var start: CFIndex = 0
        let count: CFIndex = CTTypesetterSuggestLineBreak(typesetter, start, width)
        
        // Use the returned character count (to the break) to create the line.
        let line = CTTypesetterCreateLine(typesetter, CFRangeMake(start, count))
        
        // Get the offset needed to center the line.
        let flush = 0.5 // centered
        let penOffset = CTLineGetPenOffsetForFlush(line, CGFloat(flush), width)
        
        // Move the given text drawing position by the calculated offset and draw the line.
        context.textPosition = CGPoint(x: textPosition.x + CGFloat(penOffset), y: textPosition.y)
        CTLineDraw(line, context)
        
        // Move the index beyond the line break.
        start += count
    }
    
    // MARK: - demo4 Drawing the styled paragraph
    func demo4(_ context: CGContext) {
        let fontName = "Didot Italic"
        let pointSize: CGFloat = 24.0
        
        let string = chineseString
        
        // Apply the paragraph style.
        let attrString = self.applyParaStyle(fontName: fontName, pointSize: pointSize, plainText: string, lineSpaceInc: 5.0)
        
        // Put the attributed string with applied paragraph style into a framesetter.
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        
        // Create a path to fill the View.
        let path = CGPath(rect: self.bounds, transform: nil)
        
        // Create a frame in which to draw.
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        // Draw the frame.
        CTFrameDraw(frame, context)
    }
    
    // MARK: Applying a paragraph style
    func applyParaStyle(fontName: String, pointSize: CGFloat, plainText: String, lineSpaceInc: CGFloat) -> NSAttributedString {
        // Create the font so we can determine its height.
        let font = CTFontCreateWithName(fontName as CFString, pointSize, nil)
        
        // Set the lineSpacing.
        var lineSpacing: CGFloat = (CTFontGetLeading(font) + lineSpaceInc) * 2
        
        // Create the paragraph style settings.
        var setting = CTParagraphStyleSetting(spec: .lineSpacingAdjustment, valueSize: MemoryLayout<CGFloat>.size, value: &lineSpacing)
        
        let paragraphStyle = CTParagraphStyleCreate(&setting, 1)
        
        // Add the paragraph style to the dictionary.
        let attributes: [NSAttributedStringKey: Any] = [kCTFontNameAttribute as NSAttributedStringKey: font, kCTParagraphStyleAttributeName as NSAttributedStringKey: paragraphStyle]
        
        // Apply the paragraph style to the string to created the attributed string.
        let attrString = NSAttributedString(string: plainText, attributes: attributes)
        
        return attrString
    }
    
    // MARK: - demo5 Displaying text in a nonrectangular path
    func demo5(_ context: CGContext) {
        // Initialize an attributed string.
        let textString = chineseString
        
        // Create a mutable attributed string.
        let attrString = NSMutableAttributedString(string: textString)
        
        // Create a color that will be added as an attribute to the attrString.
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let components: [CGFloat] = [ 1.0, 0.0, 0.0, 0.8 ]
        let red = CGColor(colorSpace: rgbColorSpace, components: components)
        
        // Set the color of the first 13 chars to red.
        attrString.setAttributes([kCTForegroundColorAttributeName as NSAttributedStringKey: red!], range: NSRange(location: 0, length: 13))
        
        // vertical text layout attributes set up
        let frameAttributes = [kCTFrameProgressionAttributeName as NSAttributedStringKey: NSNumber(value: CTFrameProgression.rightToLeft.rawValue)]
        attrString.addAttribute(kCTVerticalFormsAttributeName as NSAttributedStringKey, value: NSNumber(value: true), range: NSMakeRange(0, attrString.length))
        
        // Create the framesetter with the attributed string.
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        
        // Create the array of paths in which to draw the text.
        let paths = self.paths()
        var startIndex: CFIndex = 0
        
        // For each path in the array of paths...
        for path in paths {
            // Set the background of the path to yellow.
            context.setFillColor(UIColor.yellow.cgColor)
            context.addPath(path)
            context.fillPath()
            context.strokePath()
            
            // Create a frame for this path and draw the text.
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(startIndex, 0), path, frameAttributes as CFDictionary)
            CTFrameDraw(frame, context)
            
            // Start the next frame at the first character not visible in this frame.
            let frameRange = CTFrameGetVisibleStringRange(frame)
            startIndex += frameRange.length
        }
    }
    
    // MARK: Create a path in the shape of a donut.
    static func AddSquashedDonutPath(path: CGMutablePath, m:  CGAffineTransform, rect: CGRect) {
        let width: CGFloat = rect.width
        let height: CGFloat = rect.height
        
        let radiusH: CGFloat = width / 3.0
        let radiusV: CGFloat = height / 3.0
        
        path.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y + height - radiusV), transform: m)
        
        path.addQuadCurve(to: CGPoint(x: rect.origin.x + radiusH, y: rect.origin.y + height), control: CGPoint(x: rect.origin.x, y: rect.origin.y + height), transform: m)
        
        path.addLine(to: CGPoint(x: rect.origin.x + width - radiusH, y: rect.origin.y + height), transform: m)
        
        path.addQuadCurve(to: CGPoint(x: rect.origin.x + width, y: rect.origin.y + height - radiusV), control: CGPoint(x: rect.origin.x + width, y: rect.origin.y + height), transform: m)
        
        path.addLine(to: CGPoint(x: rect.origin.x + width, y: rect.origin.y + radiusV), transform: m)
        
        path.addQuadCurve(to: CGPoint(x: rect.origin.x + width - radiusH, y: rect.origin.y), control: CGPoint(x: rect.origin.x + width, y: rect.origin.y), transform: m)
        
        path.addLine(to: CGPoint(x: rect.origin.x + radiusH, y: rect.origin.y), transform: m)
        
        path.addQuadCurve(to: CGPoint(x: rect.origin.x, y: rect.origin.y + radiusV), control: CGPoint(x: rect.origin.x, y: rect.origin.y), transform: m)
        path.closeSubpath()
        
        path.addEllipse(in: CGRect(x: rect.origin.x + width / 2.0 - width / 5.0, y: rect.origin.y + height / 2.0 - height / 5.0, width: width / 5.0 * 2.0, height: height / 5.0 * 2.0), transform: m)
    }
    
    // MARK: Generate the path outside of the drawRect call so the path is calculated only once.
    func paths() -> [CGPath] {
        let path = CGMutablePath()
        var bounds: CGRect = self.bounds
        bounds = CGRect(origin: bounds.origin, size: CGSize(width: bounds.size.width, height: bounds.size.width))
        bounds = bounds.insetBy(dx: 10.0, dy: 10.0)
        
        LayoutDemoView.AddSquashedDonutPath(path: path, m: CGAffineTransform.identity, rect: bounds)
        return [path]
    }
 
    
    // MARK: - font demo
    func getGlyphsForCharacters(font: CTFont, string: String, context: CGContext) {
        // Get the string length.
        let count: CFIndex = CFStringGetLength(string as CFString)
        
        // Allocate our buffers for characters and glyphs.
        var characters = [UniChar](repeating: UniChar(), count: count)
        var glyphs = [CGGlyph](repeating: CGGlyph(), count: count)
        
        // Get the characters from the string.
        CFStringGetCharacters(string as CFString, CFRangeMake(0, count), &characters)
        
        // Get the glyphs for the characters.
        CTFontGetGlyphsForCharacters(font, &characters, &glyphs, count)
        
        var positions = [CGPoint](repeating: CGPoint.zero, count: count)
        for i in 0 ..< count {
            print("character:", characters[i], "glyph:", glyphs[i])
            positions[i] = CGPoint(x: 30 + 30 * i, y: 30)
        }
        
        CTFontDrawGlyphs(font, glyphs, positions, count, context)
        
    }
    
    // MARK: - demo6, draw glyph paths
    
    func demo6(_ context: CGContext) {
        
        let text = "Hello, 中國！"
        let length = text.count
        let fontDesc = UIFontDescriptor(name: "STHeitiSC-Light", size: 20.0)
        var matrix = CGAffineTransform.identity
        var font = CTFontCreateWithFontDescriptor(fontDesc, fontDesc.pointSize, &matrix)
        
        UIColor.black.set()
        context.fill(self.bounds)
        
        context.saveGState()
        
        let textRect = CGRect(x: 120, y: 200, width: 30, height: 200)
        
        let (glyphs, positions) = getGlyphPositions(forString: text, font: font, textRect: textRect, isVerticalLayout: true)
        
        context.saveGState()
        
//        context.translateBy(x: 0.0, y: textRect.origin.y)
//        context.translateBy(x: 0.0, y: boundingBox.size.height)
//        context.scaleBy(x: 1.0, y: -1.0)
//        context.translateBy(x: 0.0, y: -textRect.origin.y)
        
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1.0)
        
        // make rotation
        matrix = CGAffineTransform(rotationAngle: -.pi/2)
        font = CTFontCreateWithFontDescriptor(fontDesc, fontDesc.pointSize, &matrix)
        
        for i in 0 ..< length {
            let position = positions[i]
            var transform = CGAffineTransform(translationX: position.x, y: position.y)
            if let path = CTFontCreatePathForGlyph(font, glyphs[i], &transform) {
                context.addPath(path)
            }
        }
        
        context.strokePath()
        context.setFillColor(UIColor.red.cgColor)
        
        CTFontDrawGlyphs(font, glyphs, positions, length, context)
        
        context.restoreGState()
        
        context.restoreGState()
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
}
