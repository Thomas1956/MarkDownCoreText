//
//  MarkdownParser+BlockRenderer.swift
//  CoreTextTableExample
//
//  Created by Thomas on 27.04.25.
//

import UIKit
import CoreText
import PDFKit


//--------------------------------------------------------------------------------------------
// MARK: BlockRenderer (Protokoll)

/// Alle konkreten Renderer erben als Klassen (Referenztyp → AnyObject).
/// Dadurch dürfen wir ihre Properties ändern, auch wenn die Referenz `let` ist.
///
protocol BlockRenderer: AnyObject {
    /// Inhalt des Blockes
    var blockContent: MarkdownScrollView.BlockContent { get set }
   
    // NEU: auf welcher PDF-Seite wird dieser Block ausgegeben?
    var pageIndex: Int { get set }                // 0-basiert

    /// Zeichen­rechteck relativ zum Content‑View (UIKit‑Koordinaten, (0,0) = oben links)
    var frame: CGRect { get set }
    /// Höhe berechnen, wenn eine bestimmte Breite vorgegeben ist
    func measure(y: CGFloat, width: CGFloat) -> CGFloat
    /// Inhalt in den bereits nach (0,0) verschobenen CGContext zeichnen.
    /// Erwartet, dass das Koordinatensystem **bereits** für Core Text geflippt wurde
    func draw(in context: CGContext)
}

extension BlockRenderer {
    
    /// Zeichnen des Hintergrundes von BlockQuote. Das Rechteck ist der gesamte Frame des Renderers.
    func drawBlockQuote(in context: CGContext, rect: CGRect) {
        
        let (before, after) = blockContent.attrText.paragraphSpacings

        /// Hintergrund füllen
        var rect = rect
        rect.origin.x    += Markdown.blockquoteHorzIndent
        rect.origin.y    += blockContent.isLastBlockQuote ? after : 0
        rect.size.width  -= Markdown.blockquoteHorzIndent * 2
        rect.size.height -= (blockContent.isLastBlockQuote ? after : 0) + (blockContent.isFirstBlockQuote ? before : 0)
        let color = Markdown.blockquoteColor
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        /// Balken am linken Rand
        var balken = rect
        balken.origin.x  += Markdown.blockquoteBarIndent
        balken.size.width = Markdown.blockquoteBarWidth
        context.setFillColor(Markdown.blockquoteBarColor.cgColor)
        context.fill(balken)
    }
    
    /// Berechnen der Höhe des Inhaltes
    func contentHeight(_ width: CGFloat) -> CGFloat {
        let text = blockContent.attrText
        let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: text.length), nil, constraint, nil)
        return ceil(size.height)
    }
    
    var fontSize: CGFloat {
        let font = blockContent.attrText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        return (font?.pointSize ?? 20) //* 0.5
    }
    
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        /// Eingestellte Abstände des Absatzes
        let (before, after) = blockContent.attrText.paragraphSpacings
        ///
        let paddingH: CGFloat = 0 // blockContent.block?.hasBlockQuote ?? false ? fontSize * 0.5 : 0   // 0.5em horizontal
        let paddingBefore = blockContent.isFirstBlockQuote ? fontSize * 0.3 : 0   // 0.3em vertikal
        let paddingAfter  = blockContent.isLastBlockQuote  ? fontSize * 0.3 : 0   // 0.3em vertikal

        let height = self.contentHeight(width - 2 * paddingH) + after + before + paddingBefore + paddingAfter
        self.frame = CGRect(x: 0, y: y, width: width, height: height)
        return height
    }
    
    func drawContent(in context: CGContext) {
        /// Wenn `paragraphSpacingBefore` definiert ist, muss der zu zeichnende Inhalt um diese Höhe nach unten
        /// geschoben werden.
        let (before, after) = blockContent.attrText.paragraphSpacings

        let paddingH: CGFloat = 0 // blockContent.block?.hasBlockQuote ?? false ? fontSize * 0.5 : 0   // 0.5em horizontal
        let paddingBefore = blockContent.isFirstBlockQuote ? fontSize * 0.3 : 0   // 0.3em vertikal
        let paddingAfter  = blockContent.isLastBlockQuote  ? fontSize * 0.3 : 0   // 0.3em vertikal

        /// Rechteck für das Zeichnen des Inhaltes
        let contentRect =
                CGRect(x:      paddingH,
                       y:      -before + paddingAfter,
                       width:  frame.width  - 2 * paddingH,
                       height: frame.height - paddingBefore - paddingAfter)
 
//        if blockContent.block?.hasBlockQuote ?? false {
//            context.setFillColor(UIColor.systemYellow.highlight.cgColor)
//            let colorRect = CGRect(x: 400.0, y: after + paddingAfter, width: 50.0,
//                                   height: frame.height - before - after - paddingBefore - paddingAfter)
//            context.fill(colorRect)
//        }
        
        let text = blockContent.attrText
        let path = CGMutablePath()
        path.addRect(contentRect)
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let ctFrame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: text.length), path, nil)
        CTFrameDraw(ctFrame, context)
        
        
        //------------------------------------------------------------------------------------
        // MARK: - ImageURL bearbeiten
        
        // 2) Bilder nachziehen – Attribute & Geometrie aus CTFrame ablesen
        let lines = CTFrameGetLines(ctFrame) as! [CTLine]
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(ctFrame, .init(location: 0, length: 0), &origins)
        
        for (i, line) in lines.enumerated() {
            for run in CTLineGetGlyphRuns(line) as! [CTRun] {
                
                let attrs = CTRunGetAttributes(run) as NSDictionary
                guard
                    let dict = attrs as? [NSAttributedString.Key: Any],
                    let attach = dict[.myImageAttachment] as? ImageAttachment
                else { continue }
                
                var asc: CGFloat = 0, desc: CGFloat = 0
                let width = CGFloat(CTRunGetTypographicBounds(run, .init(),
                                                              &asc, &desc, nil))
                let x = CTLineGetOffsetForStringIndex(
                    line, CTRunGetStringRange(run).location, nil)
                let base = origins[i]
                
                let r = CGRect(x: contentRect.origin.x + base.x + x,
                               y: contentRect.origin.y + base.y - desc,
                               width: width,
                               height: asc + desc)
                
                context.saveGState()

                // 1) unten-links → oben-links
                context.translateBy(x: r.minX, y: r.minY)
                context.translateBy(x: 0,      y: r.height)
                context.scaleBy(x: 1, y: -1)

                // 2) Debug-Hintergrund
//                context.setFillColor(UIColor.systemOrange.cgColor)
//                context.fill(CGRect(origin: .zero, size: r.size))

                // 3)  UIKit-Bridge: jetzt darf UIImage zeichnen
                UIGraphicsPushContext(context)                // ★ neu
                attach.image.draw(in: CGRect(origin: .zero, size: r.size))
                UIGraphicsPopContext()                        // ★ neu

                context.restoreGState()
            }
        }
    }
    
    func preprocessImages(_ src: NSAttributedString) -> NSMutableAttributedString {

        // 1) bridgen – Attribute bleiben erhalten
        let mutable = NSMutableAttributedString(attributedString: src)


        mutable.enumerateAttribute(.imageURL, in: mutable.rangeAll, options: [.reverse]) { value, nsRange, _ in
            let pointSize = CGFloat(20)
            
            /// Der `value` ist ein seltsamer objC Datentyp, der nur so in einen String gebracht werden kann.
            guard let token = (value as? AnyObject)?.description
            else { return }

            /// Den Font entweder aus dem Header, aus dem Paragraph ermitteln oder Standardfont
            /// Aus dem Font xHeight für die Berechnung der Mitte eines `-` ermitteln
            let font = mutable.attribute(.font, at: nsRange.location) ?? UIFont.systemFont(ofSize: pointSize)

            /// Image Konfiguration ermitteln
            let config = UIImage.SymbolConfiguration(font: font)
                                .applying(UIImage.SymbolConfiguration.preferringMulticolor())

          /// Die ImageURL kann mit den Parametern für Höhe und Breite ergänzt sein (getrennt mit `:`)
            let components = token.components(separatedBy: ":")
            guard let imagename = components.first,
                  let image = UIImage(named: imagename) ??
                              UIImage(systemName: imagename, withConfiguration: config)?
                                                            .withRenderingMode(.alwaysOriginal)
            else { return }
            
            ///-----------------------------------------------------------------------------------
            /// Größe des Images und das Seitenverhältnis ermitteln
            var width  = image.size.width
            var height = image.size.height
            let aspect = width / height

            /// Wenn es eine Breite und/oder eine Höhe gibt, diese ermitteln zum Beispiel `100x50`. Wenn es nur einen Wert
            /// gibt, wird dieser als Höhe verwendet und die Breite berechnet.
            if components.count > 1 {
                let imagesize = components[1].split(separator: "x")
                
                width  = (imagesize.first as? NSString)?.doubleValue ?? width
                height = (imagesize.last  as? NSString)?.doubleValue ?? height
                
                /// Wenn nur ein Wert eingetragen ist, dann diesen als Höhe verwenden und die Breite berechnen
                if imagesize.count < 2 {
                    width = height * aspect
                }
            }

            /// Attachment und Run-Delegate
            let attachment = ImageAttachment(image: image, size: .init(width: width, height: height), font: font)
            let delegate   = makeRunDelegate(for: attachment)

            /// Platzhalter-String
            let ph = NSAttributedString(string: "\u{FFFC}",
                                        attributes: [ .runDelegate       : delegate,
                                                      .myImageAttachment : attachment ])
            /// Token mit Platzhalter ersetzen
            mutable.replaceCharacters(in: nsRange, with: ph)
        }
        return mutable
    }
}


// MARK: - ---------------------------------------------------------
// MARK: Konkrete Renderer (Paragraph, Heading, Tabelle, …)
// --------------------------------------------------------------

/// Baut ein CTParagraphStyleSetting, ohne dass wir ständig Unsafe-Blöcke
/// ineinander schachteln müssen.
@inline(__always)
func makeSetting<T>(_ spec: CTParagraphStyleSpecifier,
                    _ value: inout T) -> CTParagraphStyleSetting
{
    return withUnsafePointer(to: &value) {
        CTParagraphStyleSetting(
            spec:      spec,
            valueSize: MemoryLayout<T>.size,
            value:     $0)
    }
}

// TODO: CTParagraphStyleSetting muss noch verallgemeinert werden.

// -------- Paragraph ---------------------------------------------------
final class ParagraphRenderer: BlockRenderer {
    var blockContent: MarkdownScrollView.BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert

    init(blockContent: MarkdownScrollView.BlockContent) {
        self.blockContent = blockContent
        self.blockContent.attrText = preprocessImages(blockContent.attrText)
    }
    
    func draw(in context: CGContext) {
        guard let block = blockContent.block else { return }
        
        if block.hasBlockQuote {
            let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            drawBlockQuote(in: context, rect: rect)
        }

//        let (before, after) = blockContent.attrText.paragraphSpacings
//        
//        let indent: CGFloat = blockContent.attrText.ctParagraphStyleValue(for: .firstLineHeadIndent) ?? 0
//        
//        context.setFillColor(UIColor.systemIndigo.highlight.highlight.cgColor)
//        let rectBefore = CGRect(x: indent, y: frame.height - before, width: frame.width, height: before)
//        context.fill(rectBefore)
// 
//        context.setFillColor(UIColor.systemTeal.highlight.highlight.cgColor)
//        let rectAfter = CGRect(x: indent, y: 0, width: frame.width, height: after)
//        context.fill(rectAfter)
/*
        context.setLineWidth(4)
        context.addRect(CGRect(x: 0, y: 1, width: frame.width, height: frame.height).insetBy(dx: 2, dy: 2))
        context.setStrokeColor(UIColor.systemOrange.cgColor)
        context.strokePath()
        
        context.move(to:    CGPoint(x: 0,           y: after))
        context.addLine(to: CGPoint(x: frame.width, y: after))
        context.setStrokeColor(UIColor.systemTeal.cgColor)
        context.strokePath()

        context.move(to:    CGPoint(x: 0,           y: frame.height - before))
        context.addLine(to: CGPoint(x: frame.width, y: frame.height - before))
        context.setStrokeColor(UIColor.systemIndigo.cgColor)
        context.strokePath()
*/

        drawContent(in: context)
    }
}


// -------- CodeBlock ---------------------------------------------------

final class CodeBlockRenderer: BlockRenderer {
    var blockContent: MarkdownScrollView.BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert
    private let text: NSAttributedString

    init(blockContent: MarkdownScrollView.BlockContent) {
        self.blockContent = blockContent
        self.text = blockContent.attrText
    }
    
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        let innerWidth = width - 16
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let constraint = CGSize(width: innerWidth, height: .greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: text.length), nil, constraint, nil)
        let h = ceil(size.height) + 16
        self.frame = CGRect(x: 0, y: y, width: width, height: h)
        return h
    }
    
    func draw(in context: CGContext) {
        // Hintergrund
        context.setFillColor(UIColor.systemGray6.cgColor)
        context.setStrokeColor(Markdown.blockquoteColor.lowlight.cgColor)
        context.setLineWidth(1)
        
        let rectBackground = CGRect(origin: .zero, size: frame.size)
        context.addPath( UIBezierPath(roundedRect: rectBackground.insetBy(dx: 2, dy: 2), cornerRadius: 8).cgPath)
        context.strokePath()
        
        // Text
        let path = CGMutablePath()
        path.addRect(CGRect(x: 8, y: 8, width: frame.width - 16, height: frame.height - 16))
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let ctFrame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: text.length), path, nil)
        CTFrameDraw(ctFrame, context)
    }
}


// -------- Table -------------------------------------------------------
/// Noch sehr einfach: fixed‑width Spalten, automatische Zeilenhöhe pro Zelle
final class TableRenderer: BlockRenderer {
    var blockContent: MarkdownScrollView.BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert

    private let text: NSAttributedString
    private let block: MarkdownScrollView.BlockContent.TableBlock
    private let cellText: NSAttributedString

    init(blockContent: MarkdownScrollView.BlockContent) {
        self.blockContent = blockContent
        self.text = blockContent.attrText

        self.block = blockContent.tableBlock
        self.cellText = text
    }
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        // Prototyp: Gesamtbreite = width, Höhe = Anzahl Zeilen × 24
        let rowHeight: CGFloat = 24
        let h = rowHeight * CGFloat(block.lastRow + 1) + 8
        self.frame = CGRect(x: 0, y: y, width: width, height: h)
        return h
    }
    func draw(in context: CGContext) {
        // Placeholder: zeichne einfach Texte – echte Tabellen‑Logik wäre hier
        let path = CGMutablePath(); path.addRect(CGRect(origin: .zero, size: frame.size))
        let fs = CTFramesetterCreateWithAttributedString(cellText as CFAttributedString)
        let ctFrame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: cellText.length), path, nil)
        CTFrameDraw(ctFrame, context)
    }
}

final class HorizontalRuleRenderer: BlockRenderer {
    var blockContent: MarkdownScrollView.BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert

    private let text: NSAttributedString
   
    init(blockContent: MarkdownScrollView.BlockContent) {
        self.blockContent = blockContent
        self.text = blockContent.attrText
    }
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        let h = Markdown.rulerHeight
        self.frame = CGRect(x: 0, y: y, width: width, height: h)
        return h
    }
    
    func draw(in context: CGContext) {
        guard let block = blockContent.block else { return }
        
        var leftIndent = CGFloat.zero
        if block.hasBlockQuote {
            let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            drawBlockQuote(in: context, rect: rect)
            
            leftIndent = Markdown.blockquoteContentIndent
        }

        let y = CGFloat(frame.height/2)
        context.move(to: CGPoint(x: leftIndent, y: y))
        context.addLine(to: CGPoint(x: self.frame.width - Markdown.rulerRightIndent, y: y))
        context.setLineWidth(Markdown.rulerLineHeight)
        context.setStrokeColor(UIColor.systemGray4.cgColor)
        context.strokePath()
    }
}




