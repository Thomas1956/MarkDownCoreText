//
//  MarkdownScrollView.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.04.25.
//


import UIKit
import CoreText
import PDFKit


// MARK: - ---------------------------------------------------------
// MARK: BlockRenderer (Protokoll)
// --------------------------------------------------------------
/// Alle konkreten Renderer erben als Klassen (Referenztyp → AnyObject).
/// Dadurch dürfen wir ihre Properties ändern, auch wenn die Referenz `let` ist.

protocol BlockRenderer: AnyObject {
    /// Zeichen­rechteck relativ zum Content‑View (UIKit‑Koordinaten, (0,0) = oben links)
    var frame: CGRect { get set }
    /// Höhe berechnen, wenn eine bestimmte Breite vorgegeben ist
    func measure(width: CGFloat) -> CGFloat
    /// Inhalt in den bereits nach (0,0) verschobenen CGContext zeichnen.
    /// Erwartet, dass das Koordinatensystem **bereits** für Core Text geflippt wurde
    func draw(in context: CGContext)
}


// MARK: - ---------------------------------------------------------
// MARK: MarkdownScrollView (Öffentliche API)
// --------------------------------------------------------------

class MarkdownScrollView: UIScrollView {
    
    private let contentView = MarkdownContentView()
    private var textSize: CGFloat = 13.0

    // MARK: Setup
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    private func commonInit() {
        addSubview(contentView)
        showsVerticalScrollIndicator = true
        showsHorizontalScrollIndicator = false
    }

    /// Main entry: parse Markdown string, build renderers, trigger layout
    func markdown(string: String, size: CGFloat = 17, weight: UIFont.Weight = .regular, textColor: UIColor = .gray) {
        
        self.textSize = size
        let rawAttr: AttributedString
        do {
            rawAttr = try AttributedString(markdown: string, including: \.commonAttr)
        } catch {
            let fallback = NSAttributedString(string: "Markdown‑Konvertierung fehlgeschlagen: \(error.localizedDescription)")
            contentView.renderers = [ParagraphRenderer(attributed: fallback)]
            setNeedsLayout(); return
        }

        var attr = rawAttr
        attr.font = .systemFont(ofSize: size, weight: weight)
        attr.uiKit.foregroundColor = textColor

        //------------------------------------------------------------------------------------
        // MARK: - Inline-Presentation bearbeiten

        attr = inlinePresentation(text: attr, size: size, weight: weight)
        
        // ----------------------------------------------------------
        // PARSING:  AttributedString  →  [BlockRenderer]
        // ----------------------------------------------------------
        let renderers = CoreTextBlockFactory.renderers(from: attr, textSize: size)
        contentView.renderers = renderers
        setNeedsLayout()
    }

    // MARK: Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        let width = bounds.width
        let totalHeight = contentView.layout(width: width)
        contentView.frame = CGRect(x: 0, y: 0, width: width, height: totalHeight)
        contentSize = CGSize(width: width, height: totalHeight)
    }

    // MARK: PDF‑Export
    func exportPDF() -> Data? { contentView.exportPDF() }
}

// MARK: - ---------------------------------------------------------
// MARK: MarkdownContentView (zeichnet alles)
// --------------------------------------------------------------
private final class MarkdownContentView: UIView {
    var renderers: [BlockRenderer] = []

    /// Frames zuweisen & Gesamthöhe liefern
    @discardableResult
    func layout(width: CGFloat) -> CGFloat {
        var y: CGFloat = 0
        for renderer in renderers {
            let h = renderer.measure(width: width)
            renderer.frame = CGRect(x: 0, y: y, width: width, height: h)
            y += h
        }
        return y
    }

    // ----------------------------------------------------------
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        self.backgroundColor = .white
        
        for renderer in renderers {            // Reihenfolge 0 → N
            let f = renderer.frame
            ctx.saveGState()
            // 1) Ursprung an die Block‑Ecke
            ctx.translateBy(x: f.minX, y: f.minY)
            // 2) Clipping auf Block‑Rect
            ctx.clip(to: CGRect(origin: .zero, size: f.size))
            // 3) lokal flippen → Core‑Text will (0,0) unten links
            ctx.translateBy(x: 0, y: f.height)
            ctx.scaleBy(x: 1, y: -1)
            renderer.draw(in: ctx)
            ctx.restoreGState()
        }
    }

    // ----------------------------------------------------------
    func exportPDF() -> Data? {
        let data = NSMutableData()
        UIGraphicsBeginPDFContextToData(data, bounds, nil)
        UIGraphicsBeginPDFPage()
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: ctx)
        UIGraphicsEndPDFContext()
        return data as Data
    }
}


// MARK: - ---------------------------------------------------------
// MARK: Block‑Factory  (AttributedString → Renderer‑Liste)
// --------------------------------------------------------------
fileprivate enum CoreTextBlockFactory {

    /// Haupt‑Einstieg: komplette AttributedString in BlockRenderer aufspalten
    static func renderers(from attr: AttributedString, textSize: CGFloat) -> [BlockRenderer] {
        // 1) Alle BlockContent‑Elemente (liefert dein bestehender Code)
        let blocks = MarkdownScrollView.allBlockContents(attrText: attr, textSize: textSize)
        
        blocks.forEach { block in
            print(block.debugString)
        }
        
        // 2) Gruppen nach (kind, identity) zusammenfassen → je 1 Renderer
        var renderers: [BlockRenderer] = []
        var currentBlock: MarkdownScrollView.BlockContent? = nil
        var currentID:   Int? = nil
        var builder      = NSMutableAttributedString()
        var currentTableBlock: MarkdownScrollView.BlockContent.TableBlock? = nil

        func flushBuilder() {
            guard let block = currentBlock?.block else { return }
            
            let ns = builder.mutableCopy() as! NSAttributedString
            
            if block.hasBlockQuote {
                renderers.append(BlockquoteRenderer(attributed: ns))
            }
            else if block.hasCodeBlock {
                renderers.append(CodeBlockRenderer(attributed: ns))
            }
            else if block.hasThematicBreak {
                renderers.append(HorizontalRuleRenderer())
            }
            else if block.hasTable {
                // Tabelle oder normaler Absatz?
                if let table = currentTableBlock, table.lastColumn > 0 {
                    renderers.append(TableRenderer(block: table, text: ns))
                } else {
                    renderers.append(ParagraphRenderer(attributed: ns))
                }
            }
            else if block.hasHeader {
                renderers.append(HeadingRenderer(level: block.headerLevel ?? 1, attributed: ns))
            }
            else {
                renderers.append(ParagraphRenderer(attributed: ns))
            }
            
            builder = NSMutableAttributedString()
            currentTableBlock = nil
        }

        for block in blocks {
            // Wechsel‑Bedingung: Identity ändert sich
            if block.identity != currentID {
                flushBuilder()
                currentID = block.identity
                currentBlock = block
            }
            // Text‑Slice zum Builder hinzufügen
            let s = AttributedString(attr[block.range])
            let slice = NSAttributedString(s)
            builder.append(slice)
            // Tabelle → letztes TableBlock merken (wird beim Flush ausgewertet)
            if block.tableBlock.lastColumn > 0 {
                currentTableBlock = block.tableBlock
            }
        }
        flushBuilder() // letzter Block
        return renderers
    }
}


// MARK: - ---------------------------------------------------------
// MARK: Konkrete Renderer (Paragraph, Heading, Tabelle, …)
// --------------------------------------------------------------

// -------- Paragraph ---------------------------------------------------
final class ParagraphRenderer: BlockRenderer {
    var frame: CGRect = .zero
    private let text: NSAttributedString
    init(attributed: NSAttributedString) { self.text = attributed }
    func measure(width: CGFloat) -> CGFloat {
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: text.length), nil, constraint, nil)
        return ceil(size.height) + 8
    }
    func draw(in context: CGContext) {
        let path = CGMutablePath()
        path.addRect(CGRect(origin: .zero, size: frame.size))
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let ctFrame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: text.length), path, nil)
        CTFrameDraw(ctFrame, context)
    }
}

// -------- Heading -----------------------------------------------------
final class HeadingRenderer: BlockRenderer {
    var frame: CGRect = .zero
    private let text: NSAttributedString
    init(level: Int, attributed: NSAttributedString) {
        let size = max(22 - CGFloat(level) * 2, 14)
        let mut = NSMutableAttributedString(attributedString: attributed)
        mut.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: size), range: NSRange(location: 0, length: mut.length))
        self.text = mut
    }
    func measure(width: CGFloat) -> CGFloat {
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: text.length), nil, constraint, nil)
        return ceil(size.height) + 12
    }
    func draw(in context: CGContext) {
        let path = CGMutablePath()
        path.addRect(CGRect(origin: .zero, size: frame.size))
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let ctFrame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: text.length), path, nil)
        CTFrameDraw(ctFrame, context)
    }
}

// -------- Blockquote --------------------------------------------------
final class BlockquoteRenderer: BlockRenderer {
    var frame: CGRect = .zero
    private let text: NSAttributedString
    init(attributed: NSAttributedString) { self.text = attributed }
    func measure(width: CGFloat) -> CGFloat {
        let innerWidth = width - 6  // Platz für Quote‑Linie
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let constraint = CGSize(width: innerWidth, height: .greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: text.length), nil, constraint, nil)
        return ceil(size.height) + 8
    }
    func draw(in context: CGContext) {
        // Quote‑Linie links
        context.setFillColor(UIColor.label.withAlphaComponent(0.3).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 4, height: frame.height))
        // Text innen
        let path = CGMutablePath()
        path.addRect(CGRect(x: 8, y: 0, width: frame.width - 8, height: frame.height))
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let ctFrame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: text.length), path, nil)
        CTFrameDraw(ctFrame, context)
    }
}

// -------- CodeBlock ---------------------------------------------------
final class CodeBlockRenderer: BlockRenderer {
    var frame: CGRect = .zero
    private let text: NSAttributedString
    init(attributed: NSAttributedString) {
        let mut = NSMutableAttributedString(attributedString: attributed)
        mut.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: NSRange(location: 0, length: mut.length))
        self.text = mut
    }
    func measure(width: CGFloat) -> CGFloat {
        let innerWidth = width - 16
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let constraint = CGSize(width: innerWidth, height: .greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: text.length), nil, constraint, nil)
        return ceil(size.height) + 16
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
    var frame: CGRect = .zero
    private let block: MarkdownScrollView.BlockContent.TableBlock
    private let cellText: NSAttributedString

    init(block: MarkdownScrollView.BlockContent.TableBlock, text: NSAttributedString) {
        self.block = block; self.cellText = text
    }
    func measure(width: CGFloat) -> CGFloat {
        // Prototyp: Gesamtbreite = width, Höhe = Anzahl Zeilen × 24
        let rowHeight: CGFloat = 24
        return rowHeight * CGFloat(block.lastRow + 1) + 8
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
    var attrString = AttributedString()
    var frame: CGRect = .zero
    init() {}
    func measure(width: CGFloat) -> CGFloat { return 3 + 16 /*rule+padding*/ }
    
    func draw(in context: CGContext) {
        let y = CGFloat(8)
        context.move(to: CGPoint(x: 8, y: y))
        context.addLine(to: CGPoint(x: self.frame.width - 8, y: y))
        context.setLineWidth(2)
        context.setStrokeColor(UIColor.label.cgColor)
        context.strokePath()
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Extension MarkdownScrollView

extension MarkdownScrollView {
    
    // MARK: - Inline-Presentation bearbeiten

    func inlinePresentation(text: AttributedString, size: CGFloat, weight: UIFont.Weight) -> AttributedString {
        var attrText = text
        
        /// Den Standard-Absatzstil zuweisen
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacing  = 0.0
        paragraphStyle.minimumLineHeight = 20.0
        paragraphStyle.tabStops = []
        
        attrText.mergeAttributes(AttributeContainer([.paragraphStyle: paragraphStyle]))

        for (block, range) in attrText.runs[\.inlinePresentationIntent].reversed() {
            guard let block = block else { continue }
            
            /// Ermitteln von Size und Weight aus dem aktuellen Font (sonst Parameter aus der Funktion)
            var pointSize  = size
            var fontweight = weight
            
            if let font = attrText[range].uiKit.font {
                pointSize  = font.pointSize
                fontweight = font.weight
            }
            
            /// Ersetzungen für die Inline-Presentation ermitteln
            var destination = AttributeContainer()
            
            /// Für Italic, Bold und Code die entsprechenden Traits setzen
            var traits = [UIFontDescriptor.SymbolicTraits]()
            if block.rawValue & 1 == 1 { traits.append(.traitItalic)    }
            if block.rawValue & 2 == 2 { traits.append(.traitBold)      }
            if block.rawValue & 4 == 4 { traits.append(.traitMonoSpace) }
            
            /// StrikeThrough
            if block.rawValue & 32 == 32 {
                destination.uiKit.strikethroughStyle = .single
            }
            
            /// SoftBreak - Einfügen eines LINE SEPARATORS, mit dem kein neuer Absatz erzeugt wird.
            if Markdown.useSoftBreaks, block.rawValue & 64 == 64 {
                attrText.characters.removeSubrange(range)
                attrText.characters.insert(contentsOf: /*"😄" + */ String.lineSeparator, at: range.lowerBound)
            }
   
            /// Line Break - Einfügen eines NEUEN ABSATZES (entpricht typischerweise einer Leerzeile)
            if block.rawValue & 128 == 128, let rn = attrText.next(range)?.range,
                                            var components = attrText[rn].presentationIntent?.components
            {
                /// Im Block NACH dem Line Break muss die Identity des Absatzes auf einen neuen Wert gesetzt werden
                for (idx, comp) in components.enumerated() {
                    if case comp.kind = .paragraph {
                        components[idx].identity = attrText.maxIndentity + 1
                    }
                }
                /// Geänderte Attribute zurückschreiben
                let attrContainer = AttributeContainer([.presentationIntentAttributeName: PresentationIntent(types: components)])
                attrText[rn].mergeAttributes(attrContainer)
                
                /// Testweise einen Range mit anderer BackgroundColor
                // let firstIndex = attrText.index(rn.lowerBound, offsetByCharacters: 0)
                // let lastIndex  = attrText.index(rn.lowerBound, offsetByCharacters: 4)
                // let newRange = firstIndex..<lastIndex
                // self.attrText[newRange].mergeAttributes(AttributeContainer([.backgroundColor: UIColor.yellow] ))
                
                /// Zusätzlich muss der Line Break gelöscht werden, da er sonst doppelt vorkommen wird.
                attrText.characters.removeSubrange(range)
            }

            /// Wenn Traits definiert sind, den Font entsprechend setzen
            if traits.count > 0 {
                let pointSize = traits.contains(.traitMonoSpace) ? 0.85 * pointSize : pointSize
                var font = UIFont.systemFont(ofSize: pointSize, weight: fontweight)
                let descriptor = font.fontDescriptor.withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
                font = UIFont(descriptor: descriptor!, size: pointSize)
                destination.font = font
            }
            
            /// Ersetzungen ausführen
            let source = AttributeContainer([.inlinePresentationIntent: block.rawValue])
            attrText[range].replaceAttributes(source, with: destination)
        }
        return attrText
    }
}


