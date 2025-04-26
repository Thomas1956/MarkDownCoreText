//
//  MarkdownParser+AttributedString.swift
//  MarkdownParser
//
//  Created by Thomas on 19.10.24.
//

import UIKit


//--------------------------------------------------------------------------------------------
// MARK: - Debug Support für AttributedString

public extension AttributedSubstring {
    
    var debugStringLong: String {
        return AttributedString(self).debugStringLong
    }
    
    var debugString: String {
        return AttributedString(self).debugString
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Debug Support für AttributedString

public extension AttributedString {
    
    var maxIndentity: Int {
        self.runs[\.presentationIntent].compactMap( { (block, range) in
            if let block {
                return block.blockIdentity?.identity
            }
            return 1
        }).max() ?? 1
    }
    
    func next(_ range: Range<AttributedString.Index>) -> AttributedString.Runs.Element? {
        self.runs.first(where: { $0.range.lowerBound >= range.upperBound })
    }
    
    ///---------------------------------------------------------------------------------------
    /// Debugging
    ///
    enum DebugInfo { case none, blocks, text, presentationIntent, paragraphStyle, paragraphSpacing, lineIndent }
    
    func debugInfo(_ infotype: DebugInfo, _ title: String? = nil) {
        if infotype == .none { return }
        
        var titleText = "\n---"
        if let title { titleText += " \(title) "}
        print(titleText.padding(toLength: 60, withPad: "-", startingAt: 0) + "\n" )
        
        
        for block in self.runs {
            let paragraphStyle = block[keyPath: \.paragraphStyle]
            
            switch infotype {
            case .none: ()
                
            case .blocks:
                print("\(block)")
                
            case .text:
                let text = AttributedString(self[block.range]).debugStringLong
                print("<\(text)>")
                
            case .presentationIntent:
                let text = NSAttributedString( AttributedString(self[block.range]))
                let content = MarkdownScrollView.BlockContent(attrText: text, runsBlock: block, range: block.range)
//                if let cblock = content.block, let paragraphStyle
//                {
//                    let listString = (!cblock.hasList ? "" :
//                                      String(format: "%2d ",    cblock.listIdentity) +
//                                      String(format: "%2d ",    cblock.listHierarchie ?? 0) + "List" +
//                                      String(format: "%3d -> ", cblock.listOrdinal) +
//                                      String(format: "%2.1f, ", paragraphStyle.firstLineHeadIndent) +
//                                      String(format: "%2.1f",   paragraphStyle.headIndent)
//                    ).padding(to: 28)
//                    
//                    
//                    let debugStr = String(format: " %2d  ", content.identity) + "\(content.kind)".padding(to: 15) +
//                    listString + "\t\(cblock)".padding(to: 50)
//                    
//                    let text = AttributedString(self[block.range]).debugString
//                    print("\(text) \t\(debugStr)")
//                }
                
            case .paragraphStyle:
                let text = AttributedString(self[block.range]).debugStringLong
                print("\(text)>")
                if let paragraphStyle {
                    print("\t\t\(paragraphStyle)\n")
                }
                
            case .paragraphSpacing:
                let text = AttributedString(self[block.range]).debugStringLong
                print("\(text)>")
                if let paragraphStyle {
                    print("\t\t Spacing: \(paragraphStyle.paragraphSpacing) Before: \(paragraphStyle.paragraphSpacingBefore)\n")
                }
                
          case .lineIndent:
                let text = AttributedString(self[block.range]).debugStringLong
                if let paragraphStyle {
                    var strIndent = String(format: "Indent %4.1f, ", paragraphStyle.firstLineHeadIndent)
                    strIndent    += String(format: "%4.1f", paragraphStyle.headIndent)
                    print("\(strIndent.padding(to: 20)) \(text)")
                }
            }
        }
        print("\n".padding(toLength: 60, withPad: "-", startingAt: 0))
    }
    
    var debugStringLong: String {
        var text = NSAttributedString(self).string
        text = text.replacingOccurrences(of: String.punctuation, with: "----")
        text = text.replacingOccurrences(of: "\n", with: String.lineBreak)
        text = text.replacingOccurrences(of: String.paragraphSeparator, with: String.lineBreak)
        text = text.replacingOccurrences(of: String.mathematicSpace, with: "ⓢ")
        text = text.replacingOccurrences(of: String.nonBreakingSpace, with: "ⓢ")
        text = text.replacingOccurrences(of: String.objReplace,  with: "ⓞ")
        text = text.replacingOccurrences(of: String.lineSeparator, with: String.downwardsArrow)
        return text.replacingOccurrences(of: "\t", with: String.tabulator)
    }
    
    var debugString: String {
        let text = self.debugStringLong
        return String(text.padding(toLength: 20, withPad: ".", startingAt: 0))
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Zufügen der Userspezifische Attribute zu einen AttributedString

public extension AttributedString {

    /// User-Attribute
    ///
    mutating func userAttributes(size: CGFloat, weight: UIFont.Weight) {
        var attrString = self
        /// Segmente des AttributedString, die identische Eigenschaften haben
        for run in attrString.runs {
            
            /// Bearbeiten der StyleAttribute
            if let styleMode = run.style {
                let currentRange = run.range
                attrString[currentRange].uiKit.foregroundColor = styleMode.userstyle.color
                attrString[currentRange].font = UIFont.systemFont(ofSize: styleMode.userstyle.size,
                                                                  weight: styleMode.userstyle.weight )
            }
            
            /// Bearbeiten der ColorAttribute
            if let colorMode = run.color {
                let currentRange = run.range
                let color = DefaultColors(rawValue: colorMode)?.color ?? UIColor(hexstring: colorMode) ?? .red
                attrString[currentRange].uiKit.foregroundColor = color
            }
            
            /// Temporäre Merker für Textgröße und Schriftstärke
            var fontsize  : CGFloat? = nil
            var fontweight: UIFont.Weight? = nil
            
            /// Bearbeiten der Schriftstärke
            if let weightMode = run.weight {
                fontweight = weightMode.weight
                fontsize   = size               /// Wenn Weight gesetzt wird, muss auch die Defaultgröße übernommen werden.
            }
            
            /// Bearbeiten der Textgröße
            if let sizeMode = run.size {
                fontsize = sizeMode             /// Merken der Textgröße
            }
            
            /// Wenn die Textgröße und optional auch die Schriftstärke gesetzt ist, muss der Font eingestellt werden
            if let fontsize {
                let currentRange = run.range
                attrString[currentRange].font = UIFont.systemFont(ofSize: fontsize, weight: fontweight ?? weight)
            }
            
        }
        self = attrString
    }
    
    /// Zuweisung der vordefinierten Farben aus einem String als RawValue
    enum DefaultColors: String, Codable, Hashable {
        
        case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink, brown,
             gray, gray2, gray3, gray4, gray5, gray6, black, label
        
        var color: UIColor {
            switch self {
            case .red:      return .systemRed
            case .orange:   return .systemOrange
            case .yellow:   return .systemYellow
            case .green:    return .systemGreen
            case .mint:     return .systemMint
            case .teal:     return .systemTeal
            case .cyan:     return .systemCyan
            case .blue:     return .systemBlue
            case .indigo:   return .systemIndigo
            case .purple:   return .systemPurple
            case .pink:     return .systemPink
            case .brown:    return .systemBrown
                
            case .gray:     return .systemGray
            case .gray2:    return .systemGray2
            case .gray3:    return .systemGray3
            case .gray4:    return .systemGray4
            case .gray5:    return .systemGray5
            case .gray6:    return .systemGray6
                
            case .black,
                    .label:    return .label
            }
        }
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Userspezifische Attribute für einen AttributedString

/// Textgröße
///
public struct SizeAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    public typealias Value = CGFloat
    public static var name: String = "size"
}

/// Textfarbe
///
public struct ColorAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    public typealias Value = String
    public static var name: String = "color"
}

/// Schriftstärke
public struct WeightAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    public enum Value: String, Codable, Hashable {
        
        case black, heavy, bold, semibold, medium, regular, light, thin, ultralight
        
        var weight: UIFont.Weight {
            switch self {
            case .black:      .black            /// Dicker ist als HEAVY.
            case .heavy:      .heavy            /// Dicker ist als BOLD.
            case .bold:       .bold             /// Dicker ist als die Standardschrift.
            case .semibold:   .semibold         /// Etwas dicker als MEDIUM.
            case .medium:     .medium           /// Etwas dicker als die Standardschrift.
            case .regular:    .regular          /// Standardschrift.
            case .light:      .light            /// Etwas dünner ist als die Standardschrift.
            case .thin:       .thin             /// Dünner als die Standardschrift.
            case .ultralight: .ultraLight       /// Dünner und heller ist als die Standardschrift.
            }
        }
    }
    public static var name: String = "weight"
}

/// Kombinierter Stil des Textes
///
public struct StyleAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    public enum Value: String, Codable, Hashable {
        case plain, dark, black, marked
        
        var userstyle: (color: UIColor, size: CGFloat, weight: UIFont.Weight) {
            switch self {
            case .plain:  (UIColor.gray,       13, .regular)
            case .dark:   (UIColor.darkGray,   13, .semibold)
            case .black:  (UIColor.gray,       15, .semibold)
            case .marked: (UIColor.systemRed,  17, .semibold)
            }
        }
    }
    public static var name: String = "style"
}

/// Attribute, die eingestellt werden können
///
public extension AttributeScopes {
    struct CommonAttributes: AttributeScope {
        let size:   SizeAttribute
        let color:  ColorAttribute
        let weight: WeightAttribute
        let style:  StyleAttribute
    }
    var commonAttr: CommonAttributes.Type { CommonAttributes.self }
}

public extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.CommonAttributes, T>) -> T {
        self[T.self]
    }
}
