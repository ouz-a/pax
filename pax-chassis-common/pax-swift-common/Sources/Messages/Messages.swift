//
//  Messages.swift
//  interface
//
//  Created by Zachary Brown on 5/7/22.
//

import Foundation
import SwiftUI
import FlexBuffers


/// Agnostic of the type of element, this patch contains only an `id_chain` field, suitable for looking up a NativeElement (e.g. for deletion)
public class AnyCreatePatch {
    public var id_chain: [UInt64]
    /// Used for clipping -- each `[UInt64]` is an `id_chain` for an associated clipping mask (`Frame`)
    public var clipping_ids: [[UInt64]]
    
    public init(fb:FlxbReference) {
        self.id_chain = fb["id_chain"]!.asVector!.makeIterator().map({ fb in
            fb.asUInt64!
        })
        
        self.clipping_ids = fb["clipping_ids"]!.asVector!.makeIterator().map({ fb in
            fb.asVector!.makeIterator().map({ fb in
                fb.asUInt64!
            })
        })
    }
}


public class AnyDeletePatch {
    public var id_chain: [UInt64]
    
    public init(fb:FlxbReference) {
        self.id_chain = fb.asVector!.makeIterator().map({ fb in
            fb.asUInt64!
        })
        
    }
}

public class TextStyle {
    public var font: PaxFont
    public var fill: Color
    public var alignmentMultiline: TextAlignment
    public var alignment: Alignment
    public var font_size: CGFloat
    public var underline: Bool
    
    public init(font: PaxFont, fill: Color, alignmentMultiline: TextAlignment, alignment: Alignment, font_size: CGFloat, underline: Bool) {
        self.font = font
        self.fill = fill
        self.alignmentMultiline = alignmentMultiline
        self.alignment = alignment
        self.font_size = font_size
        self.underline = underline
    }
    
    public func applyPatch(from patch: TextStyleMessage) {
        
        self.font.applyPatch(fb: patch.font)

        if patch.fill != nil {
            self.fill = patch.fill!
        }
        
        if patch.align_multiline != nil {
            self.alignmentMultiline = patch.align_multiline!.toTextAlignment()
        } else if patch.align_horizontal != nil {
            self.alignmentMultiline = patch.align_horizontal!.toTextAlignment()
        }
        if patch.align_vertical != nil && patch.align_horizontal != nil {
            self.alignment = toAlignment(horizontalAlignment: patch.align_horizontal!, verticalAlignment: patch.align_vertical!)
        }
        
        if patch.font_size != nil {
            self.font_size = patch.font_size!
        }
        
        if patch.underline != nil {
            self.underline = patch.underline!
        }
    }
}

public class TextElement {
    public var id_chain: [UInt64]
    public var clipping_ids: [[UInt64]]
    public var content: String
    public var transform: [Float]
    public var size_x: Float
    public var size_y: Float
    public var textStyle: TextStyle
    public var depth: UInt?
    public var style_link: TextStyle?
    
    public init(id_chain: [UInt64], clipping_ids: [[UInt64]], content: String, transform: [Float], size_x: Float, size_y: Float, textStyle: TextStyle, depth: UInt?, style_link: TextStyle?) {
        self.id_chain = id_chain
        self.clipping_ids = clipping_ids
        self.content = content
        self.transform = transform
        self.size_x = size_x
        self.size_y = size_y
        self.textStyle = textStyle
        self.depth = depth
        self.style_link = style_link
    }
    
    public static func makeDefault(id_chain: [UInt64], clipping_ids: [[UInt64]]) -> TextElement {
        let defaultTextStyle = TextStyle(font: PaxFont.makeDefault(), fill: Color(.black), alignmentMultiline: .leading, alignment: .topLeading, font_size: 5.0, underline: false)
        return TextElement(id_chain: id_chain, clipping_ids: clipping_ids, content: "", transform: [1,0,0,1,0,0], size_x: 0.0, size_y: 0.0, textStyle: defaultTextStyle, depth: nil, style_link: nil)
    }
    
    public func applyPatch(patch: TextUpdatePatch) {
        //no-op to ID, as it is primary key
        
        if let content = patch.content {
            self.content = content
        }
        if let transform = patch.transform {
            self.transform = transform
        }
        if let size_x = patch.size_x {
            self.size_x = size_x
        }
        if let size_y = patch.size_y {
            self.size_y = size_y
        }
        if let depth = patch.depth {
            self.depth = depth
        }
        
        // Apply new TextStyle
        if let styleBuffer = patch.style {
            self.textStyle.applyPatch(from: styleBuffer)
        }
        
        // Apply style_link
        if let styleLinkBuffer = patch.style_link {
            self.style_link?.applyPatch(from: styleLinkBuffer)
        }
    }
}

public enum TextAlignHorizontal {
    case center
    case left
    case right
}

public extension TextAlignHorizontal {
    func toTextAlignment() -> TextAlignment {
        switch self {
        case .center:
            return .center
        case .left:
            return .leading
        case .right:
            return .trailing
        }
    }
}

public enum TextAlignVertical {
    case top
    case center
    case bottom
}


public func toAlignment(horizontalAlignment: TextAlignHorizontal, verticalAlignment: TextAlignVertical) -> Alignment {
    let horizontal: HorizontalAlignment
    let vertical: VerticalAlignment
    
    switch horizontalAlignment {
    case .center:
        horizontal = .center
    case .left:
        horizontal = .leading
    case .right:
        horizontal = .trailing
    }
    
    switch verticalAlignment {
    case .top:
        vertical = .top
    case .center:
        vertical = .center
    case .bottom:
        vertical = .bottom
    }
    return Alignment(horizontal: horizontal, vertical: vertical)
}


/// A patch representing an image load request from a given id_chain
public class ImageLoadPatch {
    public var id_chain: [UInt64]
    public var path: String?
    
    public init(fb:FlxbReference) {
        self.id_chain = fb["id_chain"]!.asVector!.makeIterator().map({ fb in
            fb.asUInt64!
        })
        self.path = fb["path"]?.asString
    }
}


public class TextStyleMessage {
    public var font: FlxbReference
    public var fill: Color?
    public var font_size: CGFloat?
    public var underline: Bool?
    public var align_multiline: TextAlignHorizontal?
    public var align_horizontal: TextAlignHorizontal?
    public var align_vertical: TextAlignVertical?
    
    public init(_ buffer: FlxbReference) {
        self.font =  buffer["font"]!
        
        self.font_size = buffer["font_size"]?.asFloat.map { CGFloat($0) }
        self.underline = buffer["underline"]?.asBool
        
        if let alignmentValue = buffer["align_multiline"]?.asString {
            switch alignmentValue {
            case "Center":
                self.align_multiline = .center
            case "Left":
                self.align_multiline = .left
            case "Right":
                self.align_multiline = .right
            default:
                self.align_multiline = nil
            }
        }
        
        if let alignmentValue = buffer["align_horizontal"]?.asString {
            switch alignmentValue {
            case "Center":
                self.align_horizontal = .center
            case "Left":
                self.align_horizontal = .left
            case "Right":
                self.align_horizontal = .right
            default:
                self.align_horizontal = nil
            }
        }
        
        if let verticalAlignmentValue = buffer["align_vertical"]?.asString {
            switch verticalAlignmentValue {
            case "Top":
                self.align_vertical = .top
            case "Center":
                self.align_vertical = .center
            case "Bottom":
                self.align_vertical = .bottom
            default:
                self.align_vertical = nil
            }
        }
        
        if let colorBuffer = buffer["fill"], !colorBuffer.isNull {
            self.fill = extractColorFromBuffer(colorBuffer)
        }
    }
}


public class TextUpdatePatch {
    public var id_chain: [UInt64]
    public var content: String?
    public var transform: [Float]?
    public var size_x: Float?
    public var size_y: Float?
    public var depth: UInt?
    public var style: TextStyleMessage?
    public var style_link: TextStyleMessage?

    public init(fb: FlxbReference) {
        self.id_chain = fb["id_chain"]!.asVector!.makeIterator().map({ fb in
            fb.asUInt64!
        })
        self.content = fb["content"]?.asString
        self.transform = fb["transform"]?.asVector?.makeIterator().map({ fb in
            fb.asFloat!
        })
        self.size_x = fb["size_x"]?.asFloat
        self.size_y = fb["size_y"]?.asFloat
        self.depth = fb["depth"]?.asUInt
        
        if let styleBuffer = fb["style"], !styleBuffer.isNull {
            self.style = TextStyleMessage(styleBuffer)
        }
        
        if let styleLinkBuffer = fb["style_link"], !styleLinkBuffer.isNull {
            self.style_link = TextStyleMessage(styleLinkBuffer)
        }
    }
}

///// A patch containing optional fields, representing an update action for the NativeElement of the given id_chain
//public class TextUpdatePatch {
//    public var id_chain: [UInt64]
//    public var content: String?
//    public var transform: [Float]?
//    public var size_x: Float?
//    public var size_y: Float?
//    public var fontBuffer: FlxbReference
//    public var fill: Color?
//    public var align_multiline: TextAlignHorizontal?
//    public var align_vertical: TextAlignVertical?
//    public var align_horizontal: TextAlignHorizontal?
//    // New properties
//    public var size: CGFloat?
//    public var style_link: LinkStyle?
//
//    init(fb: FlxbReference) {
//        self.id_chain = fb["id_chain"]!.asVector!.makeIterator().map({ fb in
//            fb.asUInt64!
//        })
//        self.content = fb["content"]?.asString
//        self.transform = fb["transform"]?.asVector?.makeIterator().map({ fb in
//            fb.asFloat!
//        })
//        self.size_x = fb["size_x"]?.asFloat
//        self.size_y = fb["size_y"]?.asFloat
//        self.fontBuffer =  fb["font"]!
//
//        if let fillBuffer = fb["fill"], !fillBuffer.isNull {
//            self.fill = extractColorFromBuffer(fillBuffer)
//        }
//
//        if let alignmentValue = fb["align_multiline"]?.asString {
//            switch alignmentValue {
//            case "Center":
//                self.align_multiline = .center
//            case "Left":
//                self.align_multiline = .left
//            case "Right":
//                self.align_multiline = .right
//            default:
//                self.align_multiline = nil
//            }
//        }
//
//        if let verticalAlignmentValue = fb["align_vertical"]?.asString {
//            switch verticalAlignmentValue {
//            case "Top":
//                self.align_vertical = .top
//            case "Center":
//                self.align_vertical = .center
//            case "Bottom":
//                self.align_vertical = .bottom
//            default:
//                self.align_vertical = nil
//            }
//        }
//
//        if let alignmentValue = fb["align_horizontal"]?.asString {
//            switch alignmentValue {
//            case "Center":
//                self.align_horizontal = .center
//            case "Left":
//                self.align_horizontal = .left
//            case "Right":
//                self.align_horizontal = .right
//            default:
//                self.align_horizontal = nil
//            }
//        }
//
//        self.size = fb["size"]?.asFloat.map { CGFloat($0) }
//
//        if !fb["style_link"]!.isNull {
//            self.style_link = LinkStyle(fb: fb["style_link"]!)
//        }
//
//    }
//}


public func extractColorFromBuffer(_ fillBuffer: FlxbReference) -> Color {
    if let rgba = fillBuffer["Rgba"], !rgba.isNull {
        let stub = fillBuffer["Rgba"]!
        return Color(
            red: Double(stub[0]!.asFloat!),
            green: Double(stub[1]!.asFloat!),
            blue: Double(stub[2]!.asFloat!),
            opacity: Double(stub[3]!.asFloat!)
        )
    } else if let hlc = fillBuffer["Hlca"], !hlc.isNull {
        let stub = fillBuffer["Hlca"]!
        return Color(
            hue: Double(stub[0]!.asFloat!),
            saturation: Double(stub[1]!.asFloat!),
            brightness: Double(stub[2]!.asFloat!),
            opacity: Double(stub[3]!.asFloat!)
        )
    } else {
        return Color.black
    }
}

public enum TextAlignHorizontalMessage: String {
    case Left, Center, Right
}

public enum FontStyle: String {
    case normal = "Normal"
    case italic = "Italic"
    case oblique = "Oblique"
}

extension FontWeight {
    public func fontWeight() -> Font.Weight {
        switch self {
        case .thin: return .thin
        case .extraLight: return .ultraLight
        case .light: return .light
        case .normal: return .regular
        case .medium: return .medium
        case .semiBold: return .semibold
        case .bold: return .bold
        case .extraBold: return .heavy
        case .black: return .black
        }
    }
}

public enum FontWeight: String {
    case thin = "Thin"
    case extraLight = "ExtraLight"
    case light = "Light"
    case normal = "Normal"
    case medium = "Medium"
    case semiBold = "SemiBold"
    case bold = "Bold"
    case extraBold = "ExtraBold"
    case black = "Black"
}

public class PaxFont {
    public enum PaxFontType {
        case system(SystemFont)
        case web(WebFont)
        case local(LocalFont)
    }

    public struct SystemFont {
        let family: String
        let style: FontStyle
        let weight: FontWeight
    }

    public struct WebFont {
        let family: String
        let url: URL
        let style: FontStyle
        let weight: FontWeight
    }

    public struct LocalFont {
        let family: String
        let path: URL
        let style: FontStyle
        let weight: FontWeight
    }

    public var type: PaxFontType
    public var cachedFont: Font?
    public var currentSize: CGFloat

    public init(type: PaxFontType) {
        self.type = type
        self.currentSize = 12
    }
    
    public static func makeDefault() -> PaxFont {
        let defaultSystemFont = SystemFont(family: "Helvetica", style: .normal, weight: .normal)
        return PaxFont(type: .system(defaultSystemFont))
    }
    
    public func getFont(size: CGFloat) -> Font {
        if let cachedFont = cachedFont, currentSize == size {
            return cachedFont
        }
        
        var fontFamily: String?
        var fontStyle: FontStyle?
        var fontWeight: FontWeight?

        switch type {
        case .system(let systemFont):
            fontFamily = systemFont.family
            fontStyle = systemFont.style
            fontWeight = systemFont.weight
        case .web(let webFont):
            fontFamily = webFont.family
            fontStyle = webFont.style
            fontWeight = webFont.weight
        case .local(let localFont):
            fontFamily = localFont.family
            fontStyle = localFont.style
            fontWeight = localFont.weight
        }
        
        let isFontRegistered = PaxFont.isFontRegistered(fontFamily: fontFamily!)
        
        let baseFont: Font
        if isFontRegistered {
            baseFont = Font.custom(fontFamily!, size: size).weight(fontWeight!.fontWeight())
        } else {
            baseFont = .system(size: size).weight(fontWeight!.fontWeight())
        }

        let finalFont: Font
        switch fontStyle! {
        case .normal:
            finalFont = baseFont
        case .italic:
            finalFont = baseFont.italic()
        case .oblique:
            finalFont = baseFont
        }

        cachedFont = finalFont
        currentSize = size

        return finalFont
    }



    public func applyPatch(fb: FlxbReference) {
        if let systemFontMessage = fb["System"] {
            if let family = systemFontMessage["family"]?.asString {
                let styleMessage = FontStyle(rawValue: systemFontMessage["style"]?.asString ?? "normal") ?? .normal
                let weightMessage = FontWeight(rawValue: systemFontMessage["weight"]?.asString ?? "normal") ?? .normal
                self.type = .system(SystemFont(family: family, style: styleMessage, weight: weightMessage))
            }
        } else if let webFontMessage = fb["Web"] {
            if let family = webFontMessage["family"]?.asString,
               let urlString = webFontMessage["url"]?.asString,
               let url = URL(string: urlString) {
                let style = FontStyle(rawValue: webFontMessage["style"]?.asString ?? "normal") ?? .normal
                let weight = FontWeight(rawValue: webFontMessage["weight"]?.asString ?? "normal") ?? .normal

                self.type = .web(WebFont(family: family, url: url, style: style, weight: weight))
            }
        } else if let localFontMessage = fb["Local"] {
            if let family = localFontMessage["family"]?.asString,
               let pathString = localFontMessage["path"]?.asString,
               let path = URL(string: pathString) {
                let style = FontStyle(rawValue: localFontMessage["style"]?.asString ?? "normal") ?? .normal
                let weight = FontWeight(rawValue: localFontMessage["weight"]?.asString ?? "normal") ?? .normal

                self.type = .local(LocalFont(family: family, path: path, style: style, weight: weight))
            }
        }
    }

    #if os(macOS)
    public static func isFontRegistered(fontFamily: String) -> Bool {
        let fontFamilies = CTFontManagerCopyAvailableFontFamilyNames() as! [String]

        if fontFamilies.contains(fontFamily) {
            return true
        }

        // Check if the font is installed on the system using CTFontManager
        let installedFontURLs = CTFontManagerCopyAvailableFontURLs() as? [URL] ?? []

        for url in installedFontURLs {
            if let fontDescriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor] {
                for descriptor in fontDescriptors {
                    if let fontFamilyName = CTFontDescriptorCopyAttribute(descriptor, kCTFontFamilyNameAttribute) as? String {
                        if fontFamilyName == fontFamily {
                            return true
                        }
                    }
                }
            }
        }
        return false

    }
    #elseif  os(iOS) || os(tvOS) || os(watchOS)
    public static func isFontRegistered(fontFamily: String) -> Bool {
        let availableFontFamilies = UIFont.familyNames
        
        return availableFontFamilies.contains(fontFamily)
    }
    #endif
}
//
//public class FontFactory {
////    public var family: String
////    public var public variant: String
////    public var size: Float
//
//    func applyPatch(fb: FlxbReference) -> Font {
//        print("MAKING FONT")
//        print(fb.debugDescription)
//
//
//
//        var suffix = ""
//        if fb["variant"] != nil && !fb["variant"]!.isNull { && fb["variant"]!.asString! != "Regular" {
//            suffix = " " + fb["variant"]!.asString!
//        }
//        return Font.custom(String(fb["family"]!.asString! + suffix), size: CGFloat(fb["size"]!.asFloat!))
//    }
//
//
//    static func makeDefault() -> Font {
//        return Font.custom("Courier New", size: 14)
////        Font()
////        return Font(family: "Courier New", variant: "Regular", size: 14)
//    }
//}

//func registerWebFont() {
//       if case let .web(webFont) = type, !Self.isFontRegistered(fontFamily: webFont.family) {
//           URLSession.shared.dataTask(with: webFont.url) { data, response, error in
//               guard let data = data, error == nil else {
//                   print("Error downloading font: \(String(describing: error))")
//                   return
//               }
//               guard let provider = CGDataProvider(data: data as CFData) else {
//                   print("Error creating font provider")
//                   return
//               }
//               guard let font = CGFont(provider) else {
//                   print("Error creating font from data")
//                   return
//               }
//               print(font.fullName)
//               var errorRef: Unmanaged<CFError>?
//               if !CTFontManagerRegisterGraphicsFont(font, &errorRef) {
//                   print("Error registering font: \(webFont.family) - \(String(describing: errorRef))")
//               }
//           }.resume()
//       }
//   }



public class FrameElement {
    public var id_chain: [UInt64]
    public var transform: [Float]
    public var size_x: Float
    public var size_y: Float
    
    public init(id_chain: [UInt64], transform: [Float], size_x: Float, size_y: Float) {
        self.id_chain = id_chain
        self.transform = transform
        self.size_x = size_x
        self.size_y = size_y
    }
    
    public static func makeDefault(id_chain: [UInt64]) -> FrameElement {
        FrameElement(id_chain: id_chain, transform: [1,0,0,1,0,0], size_x: 0.0, size_y: 0.0)
    }
    
    public func applyPatch(patch: FrameUpdatePatch) {
        //no-op to ID, as it is primary key
        
        if patch.transform != nil {
            self.transform = patch.transform!
        }
        if patch.size_x != nil {
            self.size_x = patch.size_x!
        }
        if patch.size_y != nil {
            self.size_y = patch.size_y!
        }
    }
}



/// A patch containing optional fields, representing an update action for the NativeElement of the given id_chain
public class FrameUpdatePatch {
    public var id_chain: [UInt64]
    public var transform: [Float]?
    public var size_x: Float?
    public var size_y: Float?
    
    public init(fb: FlxbReference) {
        self.id_chain = fb["id_chain"]!.asVector!.makeIterator().map({ fb in
            fb.asUInt64!
        })
        self.transform = fb["transform"]?.asVector?.makeIterator().map({ fb in
            fb.asFloat!
        })
        self.size_x = fb["size_x"]?.asFloat
        self.size_y = fb["size_y"]?.asFloat
    }
}

