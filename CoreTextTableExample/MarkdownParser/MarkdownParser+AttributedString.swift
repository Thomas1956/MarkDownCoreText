//
//  MarkdownParser+AttributedString.swift
//  MarkdownParser
//
//  Created by Thomas on 19.10.24.
//

import UIKit

//--------------------------------------------------------------------------------------------
// MARK: - Alle Fonts um einen Faktor verkleinern/vergrößern

extension AttributedString {

    /// Gibt eine Kopie zurück, in der **alle** Fonts mit `factor`
    /// (z. B. 0.8 = –20 %) skaliert sind.
    func scalingFonts(by factor: CGFloat) -> AttributedString {
        guard factor != 1 else { return self }

        var out = self                      // kopierbare Variante
        for run in out.runs {               // über alle Attribute-Runs
            if let f = run.uiKit.font {     // UIKit / AppKit-Font erwischt?
                let scaled = UIFont(descriptor: f.fontDescriptor,
                                     size: max(1, f.pointSize * factor))
                out[run.range].uiKit.font = scaled
            }
        }
        return out
    }
}


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
    enum DebugInfo { case nothing, blocks, text, presentationIntent, paragraphStyle, paragraphSpacing, lineIndent }
    
    func debugInfo(_ infotype: DebugInfo, _ title: String? = nil) {
        if infotype == .nothing { return }
        
        var titleText = "\n---"
        if let title { titleText += " \(title) "}
        print(titleText.padding(toLength: 60, withPad: "-", startingAt: 0) + "\n" )
        
        
        for block in self.runs {
            let paragraphStyle = block[keyPath: \.paragraphStyle]
            
            switch infotype {
            case .nothing: ()
                
            case .blocks:
                print("\(block)")
                
            case .text:
                let text = AttributedString(self[block.range]).debugStringLong
                print("<\(text)>")
                
            case .presentationIntent: ()
//                let text = NSAttributedString( AttributedString(self[block.range]))
//                let content = BlockContent(attrText: text, runsBlock: block, range: block.range)
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
