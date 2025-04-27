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
    /// Inhalt des Blockes
    var blockContent: MarkdownScrollView.BlockContent { get set }
    /// Zeichen­rechteck relativ zum Content‑View (UIKit‑Koordinaten, (0,0) = oben links)
    var frame: CGRect { get set }
    /// Ränder des Inhaltes
    var insets: NSDirectionalEdgeInsets { get set }
    /// Höhe berechnen, wenn eine bestimmte Breite vorgegeben ist
    func measure(y: CGFloat, width: CGFloat) -> CGFloat
    /// Inhalt in den bereits nach (0,0) verschobenen CGContext zeichnen.
    /// Erwartet, dass das Koordinatensystem **bereits** für Core Text geflippt wurde
    func draw(in context: CGContext)
}

extension BlockRenderer {
    
    /// Zeichnen des Hintergrundes von BlockQuote. Das Rechteck ist der gesamte Frame des Renderers.
    func drawBlockQuote(in context: CGContext, rect: CGRect) {
//        var rect = rect
//        rect.origin.y += 5
        
        /// Hintergrund füllen
        context.setFillColor(UIColor.label.withAlphaComponent(0.1).cgColor)
        context.fill(rect)
        /// Balken am linken Rand
       context.setFillColor(UIColor.label.withAlphaComponent(0.3).cgColor)
        var balken = rect
        balken.size.width = 5
        context.fill(balken)
    }
    
    /// Berechnen der Höhe des Inhaltes
    func contentHeight(_ width: CGFloat) -> CGFloat {
        
        /// Size zum Berechnen der Höhe des Inhaltes unter Berücksichtigung der Insets
        func widthConstraint(_ width: CGFloat) -> CGSize {
            CGSize(width: width - self.insets.leading - self.insets.trailing, height: .greatestFiniteMagnitude)
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
            CGRect(x: self.insets.leading, y: 0,
                   width:  frame.width  - insets.leading - insets.trailing,
                   height: frame.height - insets.top     - insets.bottom)
        }
        
//        context.setFillColor(UIColor.systemYellow.highlight.highlight.cgColor)
//        context.fill(contentRect)
    
        let text = blockContent.attrText
        let path = CGMutablePath()
        path.addRect(contentRect)
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let ctFrame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: text.length), path, nil)
        CTFrameDraw(ctFrame, context)
    }
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
            var fallback = AttributedString("Markdown‑Konvertierung fehlgeschlagen: \(error.localizedDescription)")
            fallback.foregroundColor = .systemRed
            fallback.font = .systemFont(ofSize: 20, weight: .bold)
              
            let blockContent = BlockContent(attrText: fallback)
            contentView.renderers = [ParagraphRenderer(blockContent: blockContent)]
            setNeedsLayout(); return
        }
        
        ///-----------------------------------------------------------------------------------
        /// Setzen der Defaultwerte für den Font und die Textfarbe (`.uikit` beachten!)
        var attr = rawAttr
        attr.font = .systemFont(ofSize: size, weight: weight)
        attr.uiKit.foregroundColor = textColor
         
        /// Die User-Atribute in die Formatierungsinformation ändern.
        attr.userAttributes(size: size, weight: weight)
        
        /// Am Ende des gesamten Textes einen Absatz ergänzen. Dadurch wird beispielsweise ein Block Quote mit einem
        /// Abstand am Ende angezeigt.
        attr += AttributedString(String.paragraphSeparator)

        //------------------------------------------------------------------------------------
        // MARK: - Inline-Presentation bearbeiten

        attr = inlinePresentation(text: attr, size: size, weight: weight)
        
        ///-----------------------------------------------------------------------------------
        /// Debuggen der Blöcke im AttributedString
        ///
//        attr.debugInfo(.blocks, "Vorher")

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
        
        contentView.setNeedsDisplay()
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
            let h = renderer.measure(y: y, width: width)
//            renderer.frame = CGRect(x: 0, y: y, width: width, height: h)
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
        var currentTableBlock: MarkdownScrollView.BlockContent.TableBlock? = nil

        func makeRenderer(intentBlock: MarkdownScrollView.BlockContent) {
            guard let block = intentBlock.block else { return }
            
            if block.hasCodeBlock {
                renderers.append(CodeBlockRenderer(blockContent: intentBlock))
            }
            if block.hasThematicBreak {
                renderers.append(HorizontalRuleRenderer(blockContent: intentBlock))
            }
            if block.hasTable {
                // Tabelle oder normaler Absatz?
                if let table = currentTableBlock, table.lastColumn > 0 {
                    renderers.append(TableRenderer(blockContent: intentBlock))
                } else {
                    renderers.append(ParagraphRenderer(blockContent: intentBlock))
                }
            }
            if block.hasHeader {
                renderers.append(HeadingRenderer(blockContent: intentBlock))
            }
            if block.hasParagraph {
                renderers.append(ParagraphRenderer(blockContent: intentBlock))
            }
            currentTableBlock = nil
        }

        for block in blocks {
            makeRenderer(intentBlock: block)
 
//            if block.tableBlock.lastColumn > 0 {
//                currentTableBlock = block.tableBlock
//            }
        }
        return renderers
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
    var insets: NSDirectionalEdgeInsets = .zero
    var frame: CGRect = .zero
    
    init(blockContent: MarkdownScrollView.BlockContent) {
        self.blockContent = blockContent
    }
    
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        guard let block = blockContent.block else { return 0 }
        self.insets.leading  = block.hasBlockQuote ?  15 : 0
        self.insets.top      = block.hasBlockQuote ?   4 : 0
        self.insets.trailing = block.hasBlockQuote ?  20 : 0

        let height = self.contentHeight(width) + 8 + self.insets.top + self.insets.bottom
        self.frame = CGRect(x: 0, y: y, width: width, height: height)
        return height
    }
    
    func draw(in context: CGContext) {
        guard let block = blockContent.block else { return }
        
        if block.hasBlockQuote {
            let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            drawBlockQuote(in: context, rect: rect)
        }
        
        if block.hasList {
            let w = 3 * blockContent.widthDefault
            
            // 1) Einen Tab-Stop anlegen
            let tabs: [CTTextTab] =
                        [CTTextTabCreate(.right, blockContent.headIndent - w, nil),
                        CTTextTabCreate(.left,  blockContent.headIndent, nil ) ]

            // 2) Variablen, die bis zum CTParagraphStyle-Call leben
            
            // ---- Werte, die garantiert bis zur Style-Erzeugung leben -------------
            var tabArray           : CFArray = tabs as CFArray
            var defInterval        : CGFloat = 100
            var paragraphSpacing   : CGFloat = 10.0
            var lineHeightMultiple : CGFloat = 1.1
            
            var headIndent: CGFloat = blockContent.headIndent
            var firstLineHeadIndent: CGFloat = blockContent.firstLineHeadIndent
            
            print("HeadIndent \(headIndent) \(firstLineHeadIndent), w: \(w)")
                   
            // ---- Settings-Array ---------------------------------------------------
            var settings: [CTParagraphStyleSetting] = [
                makeSetting(.tabStops,            &tabArray),
                makeSetting(.defaultTabInterval,  &defInterval),
                makeSetting(.headIndent,          &headIndent),
                makeSetting(.firstLineHeadIndent, &firstLineHeadIndent),
                makeSetting(.paragraphSpacing,    &paragraphSpacing),
                makeSetting(.lineHeightMultiple,  &lineHeightMultiple),
            ]
            
            // ---- Paragraph-Style erzeugen und weiterverwenden ---------------------
            let ctStyle = CTParagraphStyleCreate(&settings, settings.count)

            let nsAttr = NSMutableAttributedString(attributedString: blockContent.attrText)
            nsAttr.addAttribute(
                kCTParagraphStyleAttributeName as NSAttributedString.Key,
                value: ctStyle,
                range: NSRange(location: 0, length: nsAttr.length)
            )
            blockContent.attrText = nsAttr
        }

        drawContent(in: context)
    }
}

// -------- Heading -----------------------------------------------------
final class HeadingRenderer: BlockRenderer {
    var blockContent: MarkdownScrollView.BlockContent
    var frame: CGRect = .zero
    var insets: NSDirectionalEdgeInsets = .zero

    init(blockContent: MarkdownScrollView.BlockContent) {
        self.blockContent = blockContent
        
        guard let block = blockContent.block else { return }
        var attrText = AttributedString(blockContent.attrText)
        attrText.font = block.headerFont
        self.blockContent.attrText = NSAttributedString(attrText)
    }
    
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        guard let block = blockContent.block else { return 0 }
        self.insets.leading  = block.hasBlockQuote ?  15 : 0
        self.insets.top      = block.hasBlockQuote ?   5 : 0
        self.insets.trailing = block.hasBlockQuote ?   0 : 0

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
    var insets: NSDirectionalEdgeInsets = .zero
    private let text: NSAttributedString

    init(blockContent: MarkdownScrollView.BlockContent) {
        self.blockContent = blockContent

        let mut = NSMutableAttributedString(attributedString: blockContent.attrText)
        mut.addAttribute(.font, value: UIFont.monospacedSystemFont(ofSize: 13, weight: .regular), range: NSRange(location: 0, length: mut.length))
        self.text = mut
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
    var insets: NSDirectionalEdgeInsets = .zero

    private let text: NSAttributedString
   
    init(blockContent: MarkdownScrollView.BlockContent) {
        self.blockContent = blockContent
        self.text = blockContent.attrText
    }
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        let h = 3.0 + 16 /*rule+padding*/
        self.frame = CGRect(x: 0, y: y, width: width, height: h)
        return h
    }
    
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


