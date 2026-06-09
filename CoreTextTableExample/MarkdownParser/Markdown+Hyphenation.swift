//
//  Markdown+Hyphenation.swift
//  CoreTextTableExample
//
//  Created by Thomas on 06.05.25.
//

import UIKit
import CoreText


//--------------------------------------------------------------------------------------------
// MARK: - Extension NSAttributedString: Den Text umbrechen und die SHY durch HYPHEN ersetzen.

extension NSAttributedString {
        
    /// Ersetzt jeden Soft‑Hyphen (`U+00AD`), der nach dem endgültigen
    /// Umbruch wirklich am Zeilenende steht, durch einen sichtbaren
    /// Bindestrich (`U+2010`).  Keine Kerning‑ oder Kompressions‑Tricks,
    /// sondern echtes Re‑Layout pro Zeile.
    ///
    /// - parameter width: maximale Zeilenbreite (Pt)
    /// - returns: AttributedString mit sichtbaren Hyphens nur am Zeilenende
    
    func insertingLineEndHyphens(width: CGFloat) -> NSAttributedString {
        guard width > 0 else { return self }

        let mutable = NSMutableAttributedString(attributedString: self)

        /// Silbentrennung komplett deaktiviert: alle Soft-Hyphens entfernen, sodass
        /// CoreText nur noch an Wortgrenzen umbricht (keine Trennung mitten im Wort).
        if !Markdown.useHyphenation {
            let softHyphen = "\u{00AD}"
            while true {
                let range = mutable.mutableString.range(of: softHyphen)
                guard range.location != NSNotFound else { break }
                mutable.deleteCharacters(in: range)
            }
            return mutable
        }

        /// UTF‑16 Codes der beiden Zeichen SHY und HYPHEN
        let softHy: UInt16 = 0x00AD
        let _     : UInt16 = 0x2010

        /// Index für die Zeilen mit dem Start der ersten Zeile
        var idx = 0
        
        while idx < mutable.length {

            /// Es wird nur der Rest des Strings ab `idx` bearbeitet
            let sliceRange = NSRange(location: idx, length: mutable.length - idx)
            let slice      = mutable.attributedSubstring(from: sliceRange)
            let ts         = CTTypesetterCreateWithAttributedString(slice as CFAttributedString)

            ///-------------------------------------------------------------------------------
            /// Einzüge und Listen berücksichtigen
            ///
            let firstIndent: CGFloat = slice.ctParagraphStyleValue(for: .firstLineHeadIndent) ?? 0
            let headIndent : CGFloat = slice.ctParagraphStyleValue(for: .headIndent) ?? 0
            let tailIndent : CGFloat = slice.ctParagraphStyleValue(for: .tailIndent) ?? 0

            var effWidth = width - max(0, -tailIndent)
            
            /// Ist es die erste Zeile im Absatz?
            if idx == 0 {
                /// Nur wenn kein Tabulator am Anfang steht (Liste), den `firstLineHeadIndent` abziehen.
                if slice.string.first != "\t" { effWidth -= firstIndent }
            }
            else {
                /// In allen Folgezeilen den `heaIndent` abziehen.
                effWidth -= headIndent
            }
            
            ///-------------------------------------------------------------------------------

            /// Zeichenanzahl, die in `width` passt
            let len = CTTypesetterSuggestLineBreak(ts, 0, Double(effWidth))
            guard len > 0 else { break }

            /// Einen Swift-String aus dem Reststring machen
            let lineStr = slice.string

            /// Letztes Zeichen der Zeile als UTF‑16‑Codeunit
            let lastUTF16 = lineStr.utf16[lineStr.utf16.index(lineStr.utf16.startIndex, offsetBy: len-1)]

            ///-------------------------------------------------------------------------------
            /// 1. P A S S :  Wenn ein  SHY steht am Ende – durch Hyphen ersetzen
            ///
            if lastUTF16 == softHy {
                
                 /// Auf den Index in `mutable` umrechnen, um direkten Zugriff auf den Attributed String zu haben.
                 let globalLastIdx = idx + len - 1

                /// Attribute vor dem SHY übernehmen
                let attrs = mutable.attributes(at: globalLastIdx, effectiveRange: nil)
                let hyph  = NSAttributedString(string: "\u{2010}", attributes: attrs)

                /// Den SHY durch den HYPEN ersetzen
                mutable.replaceCharacters(in: .init(location: globalLastIdx, length: 1), with: hyph)
                
                /// Die gleiche Zeile erneut prüfen (keine Erhöhung des Index)
                continue
            }

            ///-------------------------------------------------------------------------------
            /// 2. P A S S :  Wenn wir vorher einen Hyphen eingefügt hatten, der jetzt mitten in der Zeile steht, müssen wir
            /// den jetzt löschen. Wir suchen in der Zeile nach dem letzten eingesetzen HYPHEN.
  
            /// Range ohne den letzten Code‑Unit
            let innerRange = lineStr[..<lineStr.index(lineStr.startIndex, offsetBy: len - 1)]

            /// Suchen des ersten Auftretens eines HYPHEN
            if let relPos = innerRange.firstIndex(of: "\u{2010}") {

                /// Auf den Index in `mutable` umrechnen
                let deleteIdx = idx + lineStr.distance(from: lineStr.startIndex, to: relPos)
                
                /// Löschen des HYPEN
                mutable.deleteCharacters(in: .init(location: deleteIdx, length: 1))
                
                /// Die gleiche Zeile erneut prüfen (keine Erhöhung des Index)
                continue
            }
            ///-------------------------------------------------------------------------------
            /// Die Zeile ist stabil  →  zum Anfang der nächsten Zeile wechseln
            idx += len
        }
        
        return mutable
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Strukturbild des Codes
    //
    //    Start
    //      │
    //      ▼
    //    mutable := copy(src)          (NSMutableAttributedString)
    //    idx = 0                       (Zeilen‑Start im Gesamtstring)
    //    width = Spaltenbreite
    //    ─────────────────────────────────────────────────────────────
    //    WHILE idx < mutable.length
    //    │
    //    │  RestSlice = mutable[idx .. end]        (AttributedSubstring)
    //    │  ts        = CTTypesetter(RestSlice)    (ohne Path/Frame)
    //    │  len       = SuggestLineBreak(ts,width) (Zeichen in Zeile)
    //    │  lineStr   = RestSlice[0 .. len-1]      (Swift‑String)
    //    │  lastUTF16 = lineStr.utf16[len-1]       (UInt16)
    //    │  globIdx   = idx + len - 1              (abs. Index)
    //    │
    //    ├─┬─ Ist lastUTF16 = SOFT‑HYPHEN (0x00AD)?
    //    │ │      ┌───────────────────────────────────────────────┐
    //    │ │ Ja   │ • attrs = mutable.attributes(at:globIdx)      │
    //    │ │      │ • hy   = "‑" (2010) + attrs                   │
    //    │ │      │ • mutable.replaceCharacters(in:globIdx, hy)   │
    //    │ │      │ • continue   (gleiche Zeile neu layouten)     │
    //    │ │      └───────────────────────────────────────────────┘
    //    │ │
    //    │ └── Nein
    //    │
    //    ├─┬─ Ist lastUTF16 ≠ VISIBLE‑HYPHEN (0x2010)?
    //    │ │      ┌────────────────────────────────────────────────────┐
    //    │ │ Ja   │ • Suche "‑" in lineStr                            │
    //    │ │      │ • falls gefunden:                                 │
    //    │ │      │     delIdx = idx + relativePos                    │
    //    │ │      │     mutable.deleteCharacters(at:delIdx)           │
    //    │ │      │     continue  (Zeile neu layouten)                │
    //    │ │      └────────────────────────────────────────────────────┘
    //    │ │
    //    │ └── Nein  (Zeile endet korrekt mit sichtbarem Hyphen)
    //    │
    //    └──▶ idx += len        (nächste Zeile)
    //    ─────────────────────────────────────────────────────────────
    //    Ende, mutable mit finalen Hyphens zurückgeben
    
    
    //----------------------------------------------------------------------------------------
    // MARK: - Alte Version

    /// Ersetzt jeden Soft‑Hyphen (`U+00AD`), der nach dem endgültigen
    /// Umbruch wirklich am Zeilenende steht, durch einen sichtbaren
    /// Bindestrich (`U+2010`).  Keine Kerning‑ oder Kompressions‑Tricks,
    /// sondern echtes Re‑Layout pro Zeile.
    ///
    /// - parameters:
    ///    - src: Der AttributedString, der bearbeitet werden soll.
    ///    - width: maximale Zeilenbreite (Pt).
    /// - returns: AttributedString mit sichtbaren Hyphens nur am Zeilenende
    ///
    /// Das war die erste funktionierende Methode für den Ersatz von SHY durch HYPHEN. Das Problem liegt darin, dass
    /// der Frame Setter oft aufgerufen wird, was von der Laufzeit ineffizient ist. Oben bessere Methode von O3.
    ///
    
    func insertingLineEndHyphens1(width: CGFloat) -> NSAttributedString {
        guard width > 0 else { return self }

        ///-----------------------------------------------------------------------------------
        /// Rendert den aktuellen Text in der gegebenen Breite und liefert alle Zeilen.
        ///
        func frameLines(_ attrText: NSAttributedString) -> [CTLine] {
            let fullRange = CFRange(location: 0, length: attrText.length)
            let framesetter = CTFramesetterCreateWithAttributedString(attrText as CFAttributedString)
            let path = CGMutablePath()
            path.addRect(CGRect(x: 0, y: 0, width: width, height: .greatestFiniteMagnitude))
            let frame = CTFramesetterCreateFrame(framesetter, fullRange, path, nil)
            return CTFrameGetLines(frame) as? [CTLine] ?? []
        }
        
        ///-----------------------------------------------------------------------------------
        /// Liest das wirklich letzte Zeichen einer CTLine (im String-Index) aus.
        /// Gibt nil zurück, wenn die Zeile leer ist oder außerhalb des Strings läge.
        ///
        func lineEndCharacter(_ attrText: NSAttributedString, for line: CTLine) -> (char: Character, index: Int)? {
            let cfRange = CTLineGetStringRange(line)
            guard cfRange.length > 0 else { return nil }

            // Range in String-Indices umwandeln
            let start = cfRange.location
            let length = cfRange.length
            let lastIndex = start + length - 1
            guard lastIndex < attrText.length else { return nil }

            // Sichere Swift-Indexierung
            let str = attrText.string
            let strIndex = str.index(str.startIndex, offsetBy: lastIndex)
            return (str[strIndex], lastIndex)
        }

        ///-----------------------------------------------------------------------------------
        /// Alle Zeilen durchlaufen
        ///
        let mutable = NSMutableAttributedString(attributedString: self)
        var lineIndex = 0
        var lines = frameLines(mutable)
        
        /// Da sich der String ständig ändert, muss der Inhalt jedes Mal neu gerendert werden. Nur so bekommen wir die
        /// korrekten Zeilen.
        while lineIndex < lines.count {
            let line = lines[lineIndex]
            
            ///-------------------------------------------------------------------------------
            /// 1. P A S S  -  Zeilenende ermitteln, SHY durch HYPHEN ersetzen
            ///
            guard let (lastChar, lastIndex) = lineEndCharacter(mutable, for: line),
                  lastChar == "\u{00AD}"
            else { lineIndex += 1;   continue }

            /// Attribute an dieser Stelle ermitteln und den HYPHEN erzeugen.
            let baseAttrs = mutable.attributes(at: lastIndex, effectiveRange: nil)
            let hyphen = NSAttributedString(string: "\u{2010}", attributes: baseAttrs)
            
            /// HYPHEN an die Stelle des SHY setzen
            mutable.replaceCharacters(in: NSRange(location: lastIndex, length: 1), with: hyphen)
            
            ///-------------------------------------------------------------------------------
            /// 2. P A S S  -  Ein zweites Mal rendern
            
            let line1 = frameLines(mutable)[lineIndex]
 
            /// Wenn der HYPHEN noch am Zeilenende ist, dann Abbruch
            guard let (lastChar1, lastIndex1) = lineEndCharacter(mutable, for: line1),
                  lastChar1 != "\u{2010}"
            else { lines = frameLines(mutable); lineIndex += 1; continue }
            
            /// Zufügen des HYPHEN im 1. Pass hat die Zeile so verlängert, dass neu umgebrochen wird. HYPEN wieder löschen.
            mutable.deleteCharacters(in: NSRange(location: lastIndex, length: 1))

            /// Wenn ein SHY am neuen Zeilenende ist, ihn durch HYPEN ersetzen.
            if lastChar1 == "\u{00AD}" {
                mutable.replaceCharacters(in: NSRange(location: lastIndex1, length: 1), with: hyphen)
            }
            
            lines = frameLines(mutable)
            lineIndex += 1;
        }
        return mutable
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Strukturbild des Codes
    //
    //   insertHyphens(in:width:)
    //   │
    //   ├─ frameLines()                // Framesetter‑Helfer: aktuelle Zeilen liefern
    //   │
    //   ├─ lineEndCharacter()          // letzte Zeile‑Rune + Index zurückgeben
    //   │
    //   └─ while lineIndex < lines.count
    //        ├─ Zeile & Endzeichen holen
    //        ├─ 1. Pass: SHY? → ersetzen → continue (re‑frame)
    //        ├─ 2. Pass:  Hyphen noch am Ende?
    //        │     ├─ ja  → Zeile stabil → nächster Index
    //        │     └─ nein→ Hyphen löschen; evtl. neues SHY ersetzen
    //        └─ Zeilenliste aktualisiere
    
}


//--------------------------------------------------------------------------------------------
// MARK: - Extension MarkdownParser: Automatische Silbentrennung mit Einfügen von Soft-Hyphen

extension String {
    
    /// Einen String mit möglichen Zeilenumbrüchen versehen.
    /// An den Stellen, wo ein Umbruch erfolgen kann, wird ein Soft‑Hyphen (`U+00AD`) eingefügt, das im Text unsichtbar ist.
    ///
    /// - parameters:
    ///    - s: String, der bearbeitet werden soll.
    ///    - lang: Sprache für den Zeilenumbruch (Default: Deutsch)..
    /// - returns: String mit Soft-Hyphens an den möglichen Zeilenumbrüchen.
    ///
    func stringWithHyphens1(lang: String = "de-DE") -> String {
        
        /// Locale aus dem String für die Sprache erzeugen
        let cfLoc = CFLocaleCreate(nil, CFLocaleIdentifier(rawValue: lang as CFString))
        guard CFStringIsHyphenationAvailableForLocale(cfLoc) else { return self }
        
        /// Soft‑Hyphen
        let shy = "\u{00AD}"
        
        /// Einen NSString und dessen CFRange erzeugen
        let ns = self as NSString
        let full = CFRange(location: 0, length: ns.length)
        
        var hyphenPositions = Set<Int>()
        
        /// Alle Wörter im String auflisten
        ns.enumerateSubstrings(in: NSRange(location: 0, length: ns.length),
                               options: [.byWords, .substringNotRequired]) { _, range, _,_ in
 
            /// Index hinter dem gefundenen Wort
            var idx = range.location + range.length
            while true {
                /// Positionen der Silbentrennung ermitteln, bis keine Positionen mehr gefunden werden
                let pos = CFStringGetHyphenationLocationBeforeIndex(ns, idx, full, 0, cfLoc, nil)
                if pos == kCFNotFound || pos <= range.location { break }
                
                /// Position des SHY merken und die Position für die Suche erhöhen
                hyphenPositions.insert(pos)
                idx = pos - 1
            }
        }
        
        /// Alle Soft‑Hyphens von hinten nach vorn einfügen, damit Indizes stabil bleiben
        let sorted = hyphenPositions.sorted()
        var out = self
        for p in sorted.reversed() {
            let utf16Idx = out.utf16.index(out.utf16.startIndex, offsetBy: p)
            let strIdx   = String.Index(utf16Idx, within: out)!
            out.insert(contentsOf: shy, at: strIdx)
        }
        return out
    }
    
    /// Fügt Soft‑Hyphens (`U+00AD`) nach den deutschen Trennregeln ein,
    /// lässt jedoch alle Markdown‑Attribute in runden Klammern
    /// (z. B. `(color:'blue')`) unangetastet.
    func stringWithHyphens2(lang: String = "de-DE") -> String {
    
        // -------- 0) Locale prüfen --------
        let cfLoc = CFLocaleCreate(nil, CFLocaleIdentifier(rawValue: lang as CFString))
        guard CFStringIsHyphenationAvailableForLocale(cfLoc) else { return self }

        let shy         = "\u{00AD}"   // "😄"              // Soft‑Hyphen
        let ns          = self as NSString
        let fullCFRange = CFRange(location: 0, length: ns.length)

        // -------- 1) Attribut‑Segmente finden --------
        //    ( )‑Block mit mindestens einem ':'  → Markdown‑Attribute
        let attrRegex = try! NSRegularExpression(
            pattern: #"(\([^\)]*:[^\)]*\))"#,
            options: [])
        let attrMatches = attrRegex.matches(in: self, range: NSRange(location: 0, length: ns.length))
        let attrIndexSet = NSMutableIndexSet()
        for m in attrMatches { attrIndexSet.add(in: m.range) }

        // -------- 2) Silbentrennungs‑Positionen sammeln --------
        var hyphenPos = Set<Int>()

        ns.enumerateSubstrings(in: NSRange(location: 0, length: ns.length),
                               options: [.byWords, .substringNotRequired]) { _, r, _, _ in

            var probe = r.location + r.length // hinter dem Wort beginnen
            while true {
                let pos = CFStringGetHyphenationLocationBeforeIndex(
                            ns, probe, fullCFRange, 0, cfLoc, nil)
                if pos == kCFNotFound || pos <= r.location { break }

                // nur wenn Position NICHT in einem Attribut‑Range liegt
                if !attrIndexSet.contains(pos) {
                    hyphenPos.insert(pos)
                }
                probe = pos - 1               // weiter nach links suchen
            }
        }

        // -------- 3) Soft‑Hyphens von hinten einfügen --------
        var result = self
        for p in hyphenPos.sorted().reversed() {
            let u16 = result.utf16
            let u16Idx = u16.index(u16.startIndex, offsetBy: p)
            let strIdx = String.Index(u16Idx, within: result)!
            result.insert(contentsOf: shy, at: strIdx)
        }
        return result
    }
}


extension String {
    /// Einmalig kompilierter Regex für Markdown-Attribute
    private static let markdownAttrRegex: NSRegularExpression = {
        try! NSRegularExpression(
          pattern: #"(\([^\)]*:[^\)]*\))"#,
          options: []
        )
    }()

    /// Einmalig kompilierter Regex für HTML-Entities, bevor sie vom Markdown-Parser aufgelöst werden.
    private static let htmlEntityRegex: NSRegularExpression = {
        try! NSRegularExpression(
          pattern: #"&(?:#[0-9]+|#x[0-9A-Fa-f]+|[A-Za-z][A-Za-z0-9]+);"#,
          options: []
        )
    }()

    /// Cache für CFLocale-Objekte
    private static var cfLocaleCache = [String: CFLocale]()

    /// Fügt Soft-Hyphens gemäß deutscher Trennregeln ein, ignoriert Markdown-Attribute und HTML-Entities.
    func stringWithHyphens(lang: String = "de-DE") -> String {
        // ---- 0) Locale holen/anfertigen ----
        let cfLoc: CFLocale
        if let cached = Self.cfLocaleCache[lang] {
            cfLoc = cached
        } else {
            let newLoc = CFLocaleCreate(
              nil,
              CFLocaleIdentifier(rawValue: lang as CFString)
            )
            Self.cfLocaleCache[lang] = newLoc
            cfLoc = newLoc!
        }
        guard CFStringIsHyphenationAvailableForLocale(cfLoc) else {
            return self
        }

        let shy = "\u{00AD}"
        let ns   = self as NSString
        let fullCFRange = CFRange(location: 0, length: ns.length)

        // ---- 1) Bereiche finden, die vor Soft-Hyphens geschützt werden müssen ----
        let protectedRanges = [Self.markdownAttrRegex, Self.htmlEntityRegex].flatMap { regex in
            regex.matches(in: self,
                          range: NSRange(location: 0, length: ns.length)).map(\.range)
        }
        // Wir wandeln in ein Swift IndexSet um für O(log n)-contains.
        var indexSet = IndexSet()
        for range in protectedRanges {
            indexSet.insert(integersIn: range.location ..< (range.location + range.length))
        }

        // ---- 2) Hyphen-Positionen sammeln ----
        var hyphenPositions = Set<Int>()
        ns.enumerateSubstrings(
          in: NSRange(location: 0, length: ns.length),
          options: [.byWords, .substringNotRequired]
        ) { _, wordRange, _, _ in
            var probe = wordRange.location + wordRange.length
            while true {
                let pos = CFStringGetHyphenationLocationBeforeIndex(
                  ns, probe, fullCFRange, 0, cfLoc, nil
                )
                guard pos != kCFNotFound && pos > wordRange.location else {
                    break
                }
                if !indexSet.contains(pos) {
                    hyphenPositions.insert(pos)
                }
                probe = pos - 1
            }
        }

        // ---- 3) Neuen String in O(n) aufbauen ----
        let sortedPositions = hyphenPositions.sorted()
        // Reserve: Original-Länge + Anzahl Soft-Hyphens
        var result = String()
        result.reserveCapacity(self.count + sortedPositions.count)

        var lastUtf16Offset = 0
        for pos in sortedPositions {
            // Grenzen prüfen
            guard pos > lastUtf16Offset, pos <= ns.length else { continue }
            // Vom letzten Offset bis zur aktuellen Position kopieren
            let startIdx = index(atUtf16Offset: lastUtf16Offset)
            let endIdx   = index(atUtf16Offset: pos)
            result.append(contentsOf: self[startIdx..<endIdx])
            // Soft-Hyphen anhängen
            result.append(shy)
            lastUtf16Offset = pos
        }
        // Rest anhängen
        if lastUtf16Offset < ns.length {
            let startIdx = index(atUtf16Offset: lastUtf16Offset)
            result.append(contentsOf: self[startIdx...])
        }

        return result
    }

    /// Hilfs-Methode: konvertiert einen UTF-16-Offset in einen String.Index
    private func index(atUtf16Offset offset: Int) -> String.Index {
        let utf16View = self.utf16
        let idx = utf16View.index(utf16View.startIndex,
                                  offsetBy: offset,
                                  limitedBy: utf16View.endIndex) ?? utf16View.endIndex
        return String.Index(idx, within: self)!
    }
}
