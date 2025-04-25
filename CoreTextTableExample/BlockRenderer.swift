import UIKit
import CoreText
import PDFKit
/*
// MARK: - ---------------------------------------------------------
// MARK: BlockRenderer (Protokoll)
// --------------------------------------------------------------
/// Alle konkreten Renderer erben als Klassen (Referenztyp → AnyObject).
/// Dadurch dürfen wir ihre Properties ändern, auch wenn die Referenz `let` ist.
protocol BlockRenderer: AnyObject {
    /// Zeichen‑Rechteck in **UIKit‑Koordinaten** (origin oben‑links)
    var frame: CGRect { get set }
    /// Höhe, die der Block bei einer bestimmten Breite benötigt
    func measure(width: CGFloat) -> CGFloat
    /// Inhalt in den *lokal geflippten* CGContext zeichnen
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
        super.init(frame: frame); commonInit()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder); commonInit()
    }
    private func commonInit() {
        addSubview(contentView)
        showsVerticalScrollIndicator = true
        showsHorizontalScrollIndicator = false
    }

    // MARK: Public entry point
    func markdown(string: String,
                  size: CGFloat = 13,
                  weight: UIFont.Weight = .regular,
                  textColor: UIColor = .label) {
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

    // MARK: PDF-Export
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
        let blocks = MarkdownParser.allBlockContents(attrText: attr, textSize: textSize)

        // 2) Gruppen nach (kind, identity) zusammenfassen → je 1 Renderer
        var renderers: [BlockRenderer] = []
        var currentKind: PresentationIntent.Kind? = nil
        var currentID:   Int? = nil
        var builder      = NSMutableAttributedString()
        var currentTableBlock: MarkdownParser.BlockContent.TableBlock? = nil

        func flushBuilder() {
            guard let kind = currentKind else { return }
            let ns = builder.mutableCopy() as! NSAttributedString
            switch kind {
            case .paragraph:
                // Tabelle oder normaler Absatz?
                if let table = currentTableBlock, table.lastColumn > 0 {
                    renderers.append(TableRenderer(block: table, text: ns))
                } else {
                    renderers.append(ParagraphRenderer(attributed: ns))
                }
            case .heading(let level):
                renderers.append(HeadingRenderer(level: level, attributed: ns))
            case .blockQuote:
                renderers.append(BlockquoteRenderer(attributed: ns))
            case .codeBlock:
                renderers.append(CodeBlockRenderer(attributed: ns))
            default:
                renderers.append(ParagraphRenderer(attributed: ns))
            }
            builder = NSMutableAttributedString()
            currentTableBlock = nil
        }

        for block in blocks {
            // Wechsel‑Bedingung: Kind oder Identity ändert sich
            if block.kind != currentKind || block.identity != currentID {
                flushBuilder()
                currentKind = block.kind
                currentID   = block.identity
            }
            // Text‑Slice zum Builder hinzufügen
            let slice = NSAttributedString(attr[block.range])
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
    private let block: MarkdownParser.BlockContent.TableBlock
    private let cellText: NSAttributedString

    init(block: MarkdownParser.BlockContent.TableBlock, text: NSAttributedString) {
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

// ----------------------------------------------------------------------
// Ende der Datei
*/
