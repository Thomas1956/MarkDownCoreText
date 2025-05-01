//
//  MarkdownParser+BlockRenderer.swift
//  CoreTextTableExample
//
//  Created by Thomas on 27.04.25.
//


import UIKit
import CoreText
import PDFKit


extension NSAttributedString.Key {
    static let myImageAttachment = NSAttributedString.Key("MyImageAttachment")
    
    /// Bridge-Name für Swift-Attribut \.imageURL
    static let imageURL = NSAttributedString.Key("NSImageURL")
    
    /// Alias für kCTRunDelegateAttributeName
    static let runDelegate = NSAttributedString.Key(kCTRunDelegateAttributeName as String)
}

// -------------------------------------------------------------------------------------------
// MARK: - Payload-Klasse, damit wir Größe + Bild parat haben

final class ImageAttachment {
    let image: UIImage
    let size : CGSize
    let font : CTFont

    init(image: UIImage, size: CGSize, font: CTFont) {
        self.image = image
        self.size  = size
        self.font  = font
    }
}

// MARK: - 1) Callbacks nur EINMAL anlegen
private var runDelegateCallbacks: CTRunDelegateCallbacks = {
    var cb = CTRunDelegateCallbacks(
        version: kCTRunDelegateVersion1,
        dealloc: { ptr in
            Unmanaged<ImageAttachment>.fromOpaque(ptr).release()
        },
        getAscent: { ptr in
            let att = Unmanaged<ImageAttachment>
                         .fromOpaque(ptr)
                         .takeUnretainedValue()
            // x-Height des Fonts
            let xh = CTFontGetXHeight(att.font)
            // Bildoberkante = Bildhalbhöhe + x-Height/Halb
            return att.size.height/2 + xh * 0.55 - 0.2
        },
        getDescent: { ptr in
            let att = Unmanaged<ImageAttachment>
                         .fromOpaque(ptr)
                         .takeUnretainedValue()
            let xh = CTFontGetXHeight(att.font)
            let ascent = att.size.height/2 + xh * 0.55 - 0.2
            return att.size.height - ascent
        },
        getWidth: { ptr in
            let att = Unmanaged<ImageAttachment>
                         .fromOpaque(ptr)
                         .takeUnretainedValue()
            return att.size.width
        }
    )
    return cb
}()

@inline(__always)
private func makeRunDelegate(for attachment: ImageAttachment) -> CTRunDelegate {
    //  payload behalten, damit Core Text es im Callback erreicht
    let payloadPtr = Unmanaged.passRetained(attachment).toOpaque()
    //  callbacks zeigt auf die oben definierte Singleton-Struct
    return CTRunDelegateCreate(&runDelegateCallbacks, payloadPtr)!
}


// MARK: - ---------------------------------------------------------
// MARK: BlockRenderer (Protokoll)
// --------------------------------------------------------------
/// Alle konkreten Renderer erben als Klassen (Referenztyp → AnyObject).
/// Dadurch dürfen wir ihre Properties ändern, auch wenn die Referenz `let` ist.

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
        
        let (before, after) = blockContent.attrText.paragraphSpacings(at: 0)

        /// Hintergrund füllen
        var rect = rect
        rect.origin.x    += Markdown.blockquoteHorzIndent
        rect.origin.y    += blockContent.isLastBlockQuote ? after/2 : 0
        rect.size.width  -= Markdown.blockquoteHorzIndent * 2
        let color = blockContent.isLastBlockQuote ? .systemYellow.highlight : Markdown.blockquoteColor
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
        
        /// Size zum Berechnen der Höhe des Inhaltes unter Berücksichtigung der Insets
        func widthConstraint(_ width: CGFloat) -> CGSize {
            CGSize(width: width, height: .greatestFiniteMagnitude)
        }

        let text = blockContent.attrText
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let constraint = widthConstraint(width)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: text.length), nil, constraint, nil)
        return ceil(size.height)
    }
     
    
    func drawContent(in context: CGContext) {
        
        /// Rechteck für das Zeichnen des Inhaltes
        var contentRect: CGRect {
            CGRect(x: 0, y:  (blockContent.isFirstBlockQuote ? -10 : 0),
                   width:  frame.width,
                   height: frame.height)
        }
        
//                context.setFillColor(UIColor.systemYellow.highlight.highlight.cgColor)
//                context.fill(contentRect)
        
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
    
    func preprocess(_ src: NSAttributedString) -> NSMutableAttributedString {

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
        self.blockContent.attrText = preprocess(blockContent.attrText)
    }
    
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        let (before, after) = blockContent.attrText.paragraphSpacings(at: 0)
        print("before: \(before), after: \(after)")

        let height = self.contentHeight(width) + after + before
        self.frame = CGRect(x: 0, y: y, width: width, height: height)
        return height
    }
    
    func draw(in context: CGContext) {
        guard let block = blockContent.block else { return }
        
        if block.hasBlockQuote {
            let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            drawBlockQuote(in: context, rect: rect)
        }
 
        drawContent(in: context)
    }
}

// -------- Heading -----------------------------------------------------
final class HeadingRenderer: BlockRenderer {
    var blockContent: MarkdownScrollView.BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert
    var insets: NSDirectionalEdgeInsets = .zero

    init(blockContent: MarkdownScrollView.BlockContent) {
        self.blockContent = blockContent
        self.blockContent.attrText = preprocess(self.blockContent.attrText)
    }
    
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        guard let block = blockContent.block else { return 0 }
        self.insets.leading  = block.hasBlockQuote ?  Markdown.blockquoteContentIndent : 0
        self.insets.top      = block.hasBlockQuote ?  Markdown.blockquoteVertOffset : 0
        self.insets.trailing = block.hasBlockQuote ?  0 : 0

        let height = self.contentHeight(width) + 12 + self.insets.top + self.insets.bottom
        self.frame = CGRect(x: 0, y: y, width: width, height: height)
        return height
    }
    
    func draw(in context: CGContext) {
        guard let block = blockContent.block else { return }
        
        if block.hasBlockQuote {
            let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            drawBlockQuote(in: context, rect: rect)
        }
        drawContent(in: context)
    }
}

// -------- CodeBlock ---------------------------------------------------

final class CodeBlockRenderer: BlockRenderer {
    var blockContent: MarkdownScrollView.BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert
    var insets: NSDirectionalEdgeInsets = .zero
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
        context.fill(CGRect(origin: .zero, size: frame.size))
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
    var insets: NSDirectionalEdgeInsets = .zero

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
    var insets: NSDirectionalEdgeInsets = .zero

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




