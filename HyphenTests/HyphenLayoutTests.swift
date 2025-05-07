//
//  HyphenLayoutTests.swift
//  CoreTextTableExample
//
//  Created by Thomas on 07.05.25.
//


import XCTest
import CoreText

@testable import CoreTextTableExample

final class HyphenLayoutTests: XCTestCase {

    /// Hilfsfunktion: erstellt alle CTLines für text + width
    private func lines(for attr: NSAttributedString,
                       width: CGFloat) -> [CTLine] {
        let fs  = CTFramesetterCreateWithAttributedString(attr as CFAttributedString)
        let path = CGMutablePath()
        path.addRect(.init(x: 0, y: 0, width: width,
                           height: .greatestFiniteMagnitude))
        let f = CTFramesetterCreateFrame(fs,
                                         CFRange(location: 0, length: attr.length),
                                         path, nil)
        return CTFrameGetLines(f) as! [CTLine]
    }

    /// Prüft, ob eine CTLine irgendwo **vor** dem letzten Zeichen
    /// einen sichtbaren Hyphen enthält.
    private func lineHasInnerHyphen(_ line: CTLine,
                                    in attr: NSAttributedString) -> Bool {
        let range = CTLineGetStringRange(line)
        guard range.length > 1 else { return false }

        let nsR = NSRange(location: range.location, length: range.length - 1) // ohne letztes Zeichen
        let sub = attr.attributedSubstring(from: nsR).string
        return sub.contains("\u{2010}")    // sichtbarer Bindestrich
    }

    // ----------------------------------------------------------------------
    func testNoHyphenInsideLines() throws {

        // 1) Ausgangstext inkl. Soft‑Hyphens
        let raw = """
        In der Nacht zu Samstag hat ein Geisterfahrer auf der Autobahn A60 \
        einen schweren Verkehrsunfall verursacht. Das Auto des jungen Mannes \
        kollidierte frontal mit einem Pkw, in dem drei junge Frauen saßen.
        """

        // 2) Soft‑Hyphens einfügen
        let withSHY = raw.stringWithHyphens()

        // 3) AttributedString mit deinem Absatz‑Style
        let baseAttr = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17)
        ]
        let attr = NSMutableAttributedString(string: withSHY, attributes: baseAttr)

        // Absatz‑Style wie im Renderer (Beispielwerte)
        let ps = NSMutableParagraphStyle()
        ps.headIndent          = 34.8
        ps.firstLineHeadIndent = 10
        ps.tailIndent          = -20
        ps.tabStops = [
            NSTextTab(textAlignment: .right, location: 19.6, options: [:]),
            NSTextTab(textAlignment: .left,  location: 34.8, options: [:])
        ]
        attr.addAttribute(.paragraphStyle, value: ps,
                          range: NSRange(location: 0, length: attr.length))

        // 4) Breiten, die du prüfen willst
        let widths: [CGFloat] = stride(from: 600, through: 200, by: -20).map(CGFloat.init)

        for w in widths {

            // a) Hyphen‑Algorithmus laufen lassen
            let laid = attr.insertingLineEndHyphens(width: w)

            // b) Alle CTLines inspizieren
            for line in lines(for: laid, width: w) {
                XCTAssertFalse(lineHasInnerHyphen(line, in: laid),
                               "Hyphen mitten in Zeile bei width \(w)")
            }
        }
    }
}
