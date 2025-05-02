//
//  NSAttributedString+Extension.swift
//  CoreTextTableExample
//
//  Created by Thomas on 28.04.25.
//


import UIKit

import CoreText
import Foundation



//--------------------------------------------------------------------------------------------
// MARK: - Extension zum Auslesen von CTParagraphStyle

extension NSAttributedString {
    
    /// Liest einen beliebigen CTParagraphStyle-Specifier (z. B. .firstLineHeadIndent,
    /// .alignment, .lineBreakMode etc.) aus dem Attribut an einer bestimmten Position aus.
    ///
    /// - Parameters:
    ///   - specifier: Das gewünschte CTParagraphStyleSpecifier
    ///   - location:  Die Zeichen-Index­position (default: 0)
    /// - Returns:     Den Wert als T (z. B. CGFloat, CTTextAlignment.RawValue, CTLineBreakMode.RawValue)
    /// oder nil, wenn kein ParagraphStyle-Attribut gefunden wurde.
    ///
    func ctParagraphStyleValue<T>(for specifier: CTParagraphStyleSpecifier,
                                  at location: Int = 0) -> T?
    {
        let ctKey = NSAttributedString.Key(kCTParagraphStyleAttributeName as String)
        
        // 1) Auf nil prüfen
        guard let raw = self.attribute(ctKey, at: location, effectiveRange: nil) else {
            return nil
        }
        // 2) Unbedingter Cast, weil CF-Bridging hier immer klappt
        let style = raw as! CTParagraphStyle
        
        // 3) Puffer anlegen und auslesen
        let byteCount = MemoryLayout<T>.size
        var buffer = [UInt8](repeating: 0, count: byteCount)
        _ = buffer.withUnsafeMutableBytes { ptr in
            CTParagraphStyleGetValueForSpecifier(
                style,
                specifier,
                byteCount,
                ptr.baseAddress!
            )
        }
        // 4) In Swift-Typ umwandeln
        return buffer.withUnsafeBytes { $0.load(as: T.self) }
    }
    
    /// Liefert `(before, after)` – also paragraphSpacingBefore und paragraphSpacing.
    /// Falls keines gesetzt ist, gibt's `(0, 0)`.
    ///
    var paragraphSpacings: (before: CGFloat, after: CGFloat) {
        let before: CGFloat = self.ctParagraphStyleValue(for: .paragraphSpacingBefore) ?? 0
        let after:  CGFloat = self.ctParagraphStyleValue(for: .paragraphSpacing) ?? 0
        return (before, after)
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Extension zum Skalieren aller Fonts im String

extension NSMutableAttributedString {

    /// Skaliert alle `.font`-Attribute (UIKit/AppKit) im gegebenen Range
    /// (default = kompletter String).
    func scaleFonts(by factor: CGFloat, in range: NSRange? = nil) {
        guard factor != 1 else { return }

        let full = range ?? NSRange(location: 0, length: length)
        enumerateAttribute(.font,           // nur Font-Runs
                           in: full,
                           options: []) { value, r, _ in
            guard let old = value as? UIFont else { return }
            let scaled = UIFont(descriptor: old.fontDescriptor,
                                size: max(1, old.pointSize * factor))
            addAttribute(.font, value: scaled, range: r)
        }
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Einfügen von CTParagraphStyle (NSAttributedString, NSMutableAttributedString)

/// Bequeme Hülle für immutable Strings
extension NSAttributedString {
    func applyingCTParagraphStyle(_ styles: [CTParagraphStyleSpecifier: Any],
                                  range: NSRange? = nil) -> NSAttributedString
    {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.addCTParagraphStyle(styles, range: range)
        return mutable
    }
}

///-------------------------------------------------------------------------------------------
/// NSMutableAttributedString - Helper
///
extension NSMutableAttributedString {
    
    func addCTParagraphStyle(_ styles: [CTParagraphStyleSpecifier: Any],
                             range: NSRange? = nil)
    {
        var floats = [CGFloat]()
        var arrays = [CFArray]()
        
        floats.reserveCapacity(styles.count)   //  ◀︎ Pointer bleibt gültig
        arrays.reserveCapacity(styles.count)
        
        var settings = [CTParagraphStyleSetting]()
        settings.reserveCapacity(styles.count)
        
        ///-----------------------------------------------------------------------------------
        /// Lokale Funktionen
        ///
        func addFloat(_ spec: CTParagraphStyleSpecifier, _ v: CGFloat) {
            floats.append(v)
            withUnsafePointer(to: &floats[floats.count - 1]) { p in
                settings.append(.init(spec: spec,
                                      valueSize: MemoryLayout<CGFloat>.size,
                                      value: p))
            }
        }
        func addArray(_ spec: CTParagraphStyleSpecifier, _ v: CFArray) {
            arrays.append(v)
            withUnsafePointer(to: &arrays[arrays.count - 1]) { p in
                settings.append(.init(spec: spec,
                                      valueSize: MemoryLayout<CFArray>.size,
                                      value: p))
            }
        }
        
        ///-----------------------------------------------------------------------------------
        /// Werte einsortieren
        ///
        for (spec, raw) in styles {
            switch raw {
            case let n as CGFloat:   addFloat(spec, n)
            case let n as Double:    addFloat(spec, CGFloat(n))
            case let n as Float:     addFloat(spec, CGFloat(n))
            case let n as Int:       addFloat(spec, CGFloat(n))
            case let n as NSNumber:  addFloat(spec, CGFloat(truncating: n))
    
            case let arr as CFArray: addArray(spec, arr)
            case let arr as NSArray: addArray(spec, arr as CFArray)
            case let arr as [Any]:   addArray(spec, arr as CFArray)
    
            default: continue          // unsupported type
            }
        }
        
        ///-----------------------------------------------------------------------------------
        /// Paragraph-Style bauen & anwenden
        ///
        let style = CTParagraphStyleCreate(settings, settings.count)
        let key   = NSAttributedString.Key(kCTParagraphStyleAttributeName as String)
        addAttribute(key,
                     value: style,
                     range: range ?? NSRange(location: 0, length: length))
    }
}
    
//--------------------------------------------------------------------------------------------

// MARK: – NSAttributedString: nicht-mutierende Helfer
extension NSAttributedString {
    /// Rückgabe eines neuen AttributedString, in dem self + other verkettet sind
//    func appending(_ other: NSAttributedString) -> NSAttributedString {
//        let result = NSMutableAttributedString(attributedString: self)
//        result.append(other)
//        return result
//    }

    /// Gibt den Attributed-Substring im Bereich zurück
//    func attributedSubstring(in range: NSRange) -> NSAttributedString {
//        return self.attributedSubstring(from: range)
//    }

    /// Liest ein einzelnes Attribut T an Index i (UTF-16), oder nil
    func attribute<T>(_ key: NSAttributedString.Key, at i: Int) -> T? {
        return attribute(key, at: i, effectiveRange: nil) as? T
    }

    /// Liest alle Attribute als Dictionary an Index i (UTF-16)
//    func attributes(at i: Int) -> [NSAttributedString.Key: Any] {
//        return attributes(at: i, effectiveRange: nil)
//    }
}

// MARK: – NSMutableAttributedString: mutierende Helfer
extension NSMutableAttributedString {
    /// Verkettet mehrere AttributedStrings in einem Rutsch
//    func append(contentsOf parts: [NSAttributedString]) {
//        for p in parts { self.append(p) }
//    }

    /// Ersetzt **alle** Vorkommen von `plain` (String) im Text durch `attr`
    /// – sucht mit String-Find, replace von hinten nach vorn
//    func replaceOccurrences(of plain: String,
//                            with attr: NSAttributedString,
//                            options: NSString.CompareOptions = [],
//                            range searchRange: NSRange? = nil)
//    {
//        let full = searchRange ?? NSRange(location: 0, length: self.length)
//        let string = self.string as NSString
//        var matches = string.matches(for: plain, options: options, range: full)
//        // ersetze von hinten nach vorn, damit Ranges gültig bleiben
//        for m in matches.reversed() {
//            self.replaceCharacters(in: m.range, with: attr)
//        }
//    }


    /// Fügt Attribute zum Range hinzu (merge)
//    func addAttributes(_ attrs: [NSAttributedString.Key: Any], range: NSRange) {
//        self.addAttributes(attrs, range: range)
//    }

    /// Liest ein einzelnes Attribut T an Index i (UTF-16), oder nil
//    func attribute<T>(_ key: NSAttributedString.Key, at i: Int) -> T? {
//        return attribute(key, at: i, effectiveRange: nil) as? T
//    }

    /// Liest alle Attribute als Dictionary an Index i (UTF-16)
//    func attributes(at i: Int) -> [NSAttributedString.Key: Any] {
//        return attributes(at: i, effectiveRange: nil)
//    }
    
    ///---------------------------------------------------------------------------------------
    /// Meine Extensions
    
    /// Range für den **gesamten** Bereich des Strings.
    var rangeAll: NSRange { NSRange(location: 0, length: self.length) }
    
    /// Setzt Attribute im gesamten Range und  **löscht** vorher alle bestehenden Attribute in dem Bereich.
//    func setAttributes(_ attrs: [NSAttributedString.Key: Any], _ range: NSRange? = nil) {
//        self.setAttributes(attrs, range: range ?? self.rangeAll)
//    }
    
    /// Fügt Attribute zum Range hinzu (merge).
    func addAttributes(_ attrs: [NSAttributedString.Key: Any], _ range: NSRange? = nil) {
        self.addAttributes(attrs, range: range ?? self.rangeAll)
    }
}

// MARK: – NSString-Helper für Matches
private extension NSString {
//    func matches(for plain: String,
//                 options: NSString.CompareOptions = [],
//                 range searchRange: NSRange) -> [NSTextCheckingResult]
//    {
//        let pattern = NSRegularExpression.escapedPattern(for: plain)
//        let regex = try? NSRegularExpression(pattern: pattern, options: [])
//        return regex?.matches(in: self as String,
//                              options: [],
//                              range: searchRange) ?? []
//    }
}
