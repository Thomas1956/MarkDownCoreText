//
//  NSAttributedString+Extension.swift
//  CoreTextTableExample
//
//  Created by Thomas on 28.04.25.
//


import UIKit

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
