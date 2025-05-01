//
//  NSAttributedString+Extension.swift
//  CoreTextTableExample
//
//  Created by Thomas on 28.04.25.
//


import UIKit

import CoreText
import Foundation

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

extension NSAttributedString {

    /// Liefert `(before, after)` – also paragraphSpacingBefore und paragraphSpacing.
    /// Falls keines gesetzt ist, gibt's `(0, 0)`.
    func paragraphSpacings(at idx: Int) -> (before: CGFloat, after: CGFloat) {

        // 1) UIKit / AppKit
        if let nsStyle = attribute(.paragraphStyle, at: idx, effectiveRange: nil) as? NSParagraphStyle {
            return (nsStyle.paragraphSpacingBefore, nsStyle.paragraphSpacing)
        }

        // 2) Core-Text (ohne „always succeeds“-Warnung)
        let ctKey = NSAttributedString.Key(kCTParagraphStyleAttributeName as String)

        if let any = attribute(ctKey, at: idx, effectiveRange: nil),
           CFGetTypeID(any as CFTypeRef) == CTParagraphStyleGetTypeID()
        {
            // ---------------------------------------------------------------------
            // 1) Attribut holen (Any!) und in CFTypeRef casten
            // ---------------------------------------------------------------------
            let ctKey = NSAttributedString.Key(kCTParagraphStyleAttributeName as String)
            
            if let raw = attribute(ctKey, at: idx, effectiveRange: nil) {
                
                let cf = raw as CFTypeRef            //  ← gleicher Speicher­typ wie CTParagraphStyle
                
                // -----------------------------------------------------------------
                // 2) Typ-ID vergleichen
                // -----------------------------------------------------------------
                guard CFGetTypeID(cf) == CTParagraphStyleGetTypeID() else {
                    return (0, 0)                    // irgend­ein anderes Core-Text-Objekt
                }
                
                // -----------------------------------------------------------------
                // 3) Sicher in CTParagraphStyle bit-casten
                // -----------------------------------------------------------------
                let ctStyle = unsafeBitCast(cf, to: CTParagraphStyle.self)
                
                var before: CGFloat = 0
                var after : CGFloat = 0
                CTParagraphStyleGetValueForSpecifier(
                    ctStyle, .paragraphSpacingBefore,
                    MemoryLayout<CGFloat>.size, &before)
                CTParagraphStyleGetValueForSpecifier(
                    ctStyle, .paragraphSpacing,
                    MemoryLayout<CGFloat>.size, &after)
                
                return (before, after)
            }
        }
        // 3) kein Absatz-Spacing gesetzt
        return (0, 0)
    }
}


// Bequeme Hülle für immutable Strings
extension NSAttributedString {
    func applyingCTParagraphStyle(
        _ styles: [CTParagraphStyleSpecifier: Any],
        range: NSRange? = nil
    ) -> NSAttributedString {
        let mut = NSMutableAttributedString(attributedString: self)
        mut.addCTParagraphStyle(styles, range: range)
        return mut
    }
}

// MARK: - NSMutableAttributedString helper
extension NSMutableAttributedString {
    
    func addCTParagraphStyle(
        _ styles: [CTParagraphStyleSpecifier: Any],
        range: NSRange? = nil
    ) {
        
        var floats = [CGFloat]()
        var arrays = [CFArray]()
        
        floats.reserveCapacity(styles.count)   //  ◀︎ Pointer bleibt gültig
        arrays.reserveCapacity(styles.count)
        
        var settings = [CTParagraphStyleSetting]()
        settings.reserveCapacity(styles.count)
        
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
        
        // ---- Werte einsortieren ------------------------------------------
        for (spec, raw) in styles {
            switch raw {
            case let n as CGFloat:  addFloat(spec, n)
            case let n as Double:   addFloat(spec, CGFloat(n))
            case let n as Float:    addFloat(spec, CGFloat(n))
            case let n as Int:      addFloat(spec, CGFloat(n))
            case let n as NSNumber: addFloat(spec, CGFloat(truncating: n))
                
            case let arr as CFArray:   addArray(spec, arr)
            case let arr as NSArray:   addArray(spec, arr as CFArray)
            case let arr as [Any]:     addArray(spec, arr as CFArray)
                
            default: continue          // unsupported type
            }
        }
        
        // ---- Paragraph-Style bauen & anwenden ----------------------------
        let style = CTParagraphStyleCreate(settings, settings.count)
        let key   = NSAttributedString.Key(kCTParagraphStyleAttributeName as String)
        addAttribute(key,
                     value: style,
                     range: range ?? NSRange(location: 0, length: length))
    }
}
    

// MARK: – NSAttributedString: nicht-mutierende Helfer
extension NSAttributedString {
    /// Rückgabe eines neuen AttributedString, in dem self + other verkettet sind
    func appending(_ other: NSAttributedString) -> NSAttributedString {
        let result = NSMutableAttributedString(attributedString: self)
        result.append(other)
        return result
    }

    /// Gibt den Attributed-Substring im Bereich zurück
    func attributedSubstring(in range: NSRange) -> NSAttributedString {
        return self.attributedSubstring(from: range)
    }

    /// Liest ein einzelnes Attribut T an Index i (UTF-16), oder nil
    func attribute<T>(_ key: NSAttributedString.Key, at i: Int) -> T? {
        return attribute(key, at: i, effectiveRange: nil) as? T
    }

    /// Liest alle Attribute als Dictionary an Index i (UTF-16)
    func attributes(at i: Int) -> [NSAttributedString.Key: Any] {
        return attributes(at: i, effectiveRange: nil)
    }
}

// MARK: – NSMutableAttributedString: mutierende Helfer
extension NSMutableAttributedString {
    /// Verkettet mehrere AttributedStrings in einem Rutsch
    func append(contentsOf parts: [NSAttributedString]) {
        for p in parts { self.append(p) }
    }

    /// Ersetzt **alle** Vorkommen von `plain` (String) im Text durch `attr`
    /// – sucht mit String-Find, replace von hinten nach vorn
    func replaceOccurrences(of plain: String,
                            with attr: NSAttributedString,
                            options: NSString.CompareOptions = [],
                            range searchRange: NSRange? = nil)
    {
        let full = searchRange ?? NSRange(location: 0, length: self.length)
        let string = self.string as NSString
        var matches = string.matches(for: plain, options: options, range: full)
        // ersetze von hinten nach vorn, damit Ranges gültig bleiben
        for m in matches.reversed() {
            self.replaceCharacters(in: m.range, with: attr)
        }
    }


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
    func setAttributes(_ attrs: [NSAttributedString.Key: Any], _ range: NSRange? = nil) {
        self.setAttributes(attrs, range: range ?? self.rangeAll)
    }
    
    /// Fügt Attribute zum Range hinzu (merge).
    func addAttributes(_ attrs: [NSAttributedString.Key: Any], _ range: NSRange? = nil) {
        self.addAttributes(attrs, range: range ?? self.rangeAll)
    }
}

// MARK: – NSString-Helper für Matches
private extension NSString {
    func matches(for plain: String,
                 options: NSString.CompareOptions = [],
                 range searchRange: NSRange) -> [NSTextCheckingResult]
    {
        let pattern = NSRegularExpression.escapedPattern(for: plain)
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        return regex?.matches(in: self as String,
                              options: [],
                              range: searchRange) ?? []
    }
}
