//
//  MarkdownParser+BlockRenderer.swift
//  CoreTextTableExample
//
//  Created by Thomas on 27.04.25.
//

import UIKit
import CoreText
import PDFKit

var debugColor: Bool = !true

//--------------------------------------------------------------------------------------------
// MARK: BlockRenderer (Protokoll)

/// Alle konkreten Renderer erben als Klassen (Referenztyp → AnyObject).
/// Dadurch dürfen wir ihre Properties ändern, auch wenn die Referenz `let` ist.
///
protocol BlockRenderer: AnyObject {
    
    /// Inhalt des Blockes
    var blockContent: BlockContent { get set }
   
    /// PDF-Seite, auf der  dieser Block ausgegeben wird (0-basiert)
    var pageIndex: Int { get set }

    /// Zeichen­rechteck relativ zum Content‑View (UIKit‑Koordinaten, (0,0) = oben links)
    var frame: CGRect { get set }
    
    /// Höhe berechnen, wenn eine bestimmte Breite vorgegeben ist
    func measure(y: CGFloat, width: CGFloat) -> CGFloat
    
    /// Inhalt in den bereits nach (0,0) verschobenen CGContext zeichnen.
    /// Erwartet, dass das Koordinatensystem **bereits** für Core Text geflippt wurde
    func draw(in context: CGContext)
}


//--------------------------------------------------------------------------------------------
// MARK: Extension BlockRenderer für die Standard-Funktionen

extension BlockRenderer {
    
    typealias M  = Markdown
    typealias MB = Markdown.BlockQuote
    typealias MR = Markdown.Ruler
    typealias MC = Markdown.CodeBlock

    ///---------------------------------------------------------------------------------------
    /// Textgröße des aktuellen Fonts
    var fontSize: CGFloat {
        let font = blockContent.attrText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        return (font?.pointSize ?? 20) //* 0.5
    }
    
    ///---------------------------------------------------------------------------------------
    /// Umranden des Rechteckes für Paragraph Spacing (danach)
    var blockQouteSpacings: (paddingBefore: CGFloat, paddingAfter: CGFloat, paddingLeft: CGFloat, paddingRight: CGFloat) {
        guard let block = blockContent.block else { return (0, 0, 0, 0) }
        let typography = MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: fontSize))
        let blockQuote = typography.blockQuote
        let attachment = blockQuote.rectAttachment
        let paddingBefore = blockContent.isFirstBlockQuote ? attachment.rectInsetTop : 0
        let paddingAfter = blockContent.isLastBlockQuote ? attachment.rectInsetBottom : 0
        let paddingLeft = block.hasBlockQuote ? blockQuote.blockQuoteContentIndent : 0
        let paddingRight = block.hasBlockQuote ? blockQuote.blockQuoteRightIndent : 0
        return (paddingBefore, paddingAfter, paddingLeft, paddingRight)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Berechnen der Höhe des Inhaltes
    func contentHeight(_ width: CGFloat) -> CGFloat {
        let text = blockContent.attrText.insertingLineEndHyphens(width: width)
        let constraint = CGSize(width: width, height: .greatestFiniteMagnitude)
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(fs, CFRange(location: 0, length: text.length), nil, constraint, nil)
        return ceil(size.height)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Rechteck für den Inhalt des Absatzes (korrigiert um Abstände oben/unten)
    ///
    var contentRect: CGRect {
        /// Wenn `paragraphSpacingBefore` und `paragraphSpacing` definiert sind, muss der zu zeichnende Inhalt
        /// in Y-Richtung verschoben und in der Höhe verkleinert werden.
        let (before, after) = blockContent.attrText.paragraphSpacings
        
        /// Im Block Quote muss abgefragt werden, ob der Absatz der erste und/oder der letzte im Block Quote ist. Auch hier
        /// müssen die Abstände ermittelt und die Y-Position sowie die Höhe korrigiert werden.
        let (paddingBefore, paddingAfter, paddingLeft, paddingRight) = self.blockQouteSpacings

        /// Rechteck für das Zeichnen des Inhaltes
        return CGRect( x:      paddingLeft,                                /// Linker Einzug beim Block Quote
                       y:      after + paddingAfter,                       /// Y-Position nach oben verschieben
                       width:  frame.width  - paddingLeft - paddingRight,  /// Breite beim Block Quote reduzieren
                       height: frame.height - after - before -             /// Höhe beim Block Quote und/oder
                               paddingBefore - paddingAfter)               /// bem Paragraph Spacing reduzieren
    }
        
    ///---------------------------------------------------------------------------------------
    /// Größe des Inhaltes berechnen und den Frame setzen
    ///
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        /// Wenn keine Änderung erfolgt ist, dann die alte Höhe zurückgeben und den Y-Wert setzen
        if width == self.frame.width {
            self.frame.origin.y = y
            return self.frame.height
        }
        
        /// Eingestellte Abstände des Absatzes
        let (before, after) = blockContent.attrText.paragraphSpacings
        
        /// Im Block Quote muss abgefragt werden, ob der Absatz der erste und/oder der letzte im Block Quote ist. Auch hier
        /// müssen die Abstände ermittelt und die Y-Position sowie die Höhe korrigiert werden.
        let (paddingBefore, paddingAfter, paddingLeft, paddingRight) = self.blockQouteSpacings

        let height = self.contentHeight(width - paddingLeft - paddingRight) + after + before + paddingBefore + paddingAfter
        self.frame = CGRect(x: 0, y: y, width: width, height: height)
        return height
    }
    
    ///---------------------------------------------------------------------------------------
    /// Zeichnen des Hintergrundes von BlockQuote. Das Rechteck ist der gesamte Frame des Renderers.
    ///
    func drawBlockQuote(in context: CGContext, rect: CGRect) {
        
        let (before, after) = blockContent.attrText.paragraphSpacings

        /// Hintergrund füllen
        let typography = MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: fontSize))
        let blockQuote = typography.blockQuote
        let attachment = blockQuote.rectAttachment
        var rect = rect
        rect.origin.x    += attachment.rectInsetLeft
        rect.origin.y    += blockContent.isLastBlockQuote ? after : 0
        rect.size.width  -= attachment.rectInsetLeft + attachment.rectInsetRight
        rect.size.height -= (blockContent.isLastBlockQuote ? after : 0) + (blockContent.isFirstBlockQuote ? before : 0)
        
        let textColor = blockContent.attrText.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? M.textColor
        let backgroundColor = MB.useDefaultBackgroundColor ? textColor.blockQuoteBackgroundColor : MB.backgroundColor
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
        
        /// Balken am linken Rand
        var balken = rect
        balken.origin.x  += attachment.stripeGap
        balken.size.width = attachment.stripeWidth
        let barColor = MB.useDefaultBarColor ? textColor.blockQuoteBarColor : MB.barColor
        context.setFillColor(barColor.cgColor)
        context.fill(balken)
    }
    
    
    //----------------------------------------------------------------------------------------
    // MARK: - Zeichnen des Inhaltes (Text und Bilder)
    
    func drawContent(in context: CGContext) {
        
        /// Zeilenumbrüche berechnen und die HYPHEN einfügen
        let text = blockContent.attrText.insertingLineEndHyphens(width: contentRect.width)

        /// Zeichnen des Textes mit Core Text
        let path = CGMutablePath()
        path.addRect(contentRect)
        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let ctFrame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: text.length), path, nil)
        CTFrameDraw(ctFrame, context)

        /// Zeichnen der Images
        drawImages(in: context, ctFrame: ctFrame)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Zeichnen der Bilder - Erkennen der Einträge vom Preprocessing im `myImageAttachment`
    ///
    func drawImages(in context: CGContext, ctFrame: CTFrame)
    {
        /// Images  – Attribute & Geometrie aus CTFrame ablesen
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
                
                /// In den Attributen nach dem Key `myImageAttachment` suchen und ImageAttachment auslesen
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

                /// Koordinatenursprung von unten/links → oben/links
                context.translateBy(x: r.minX, y: r.minY)
                context.translateBy(x: 0,      y: r.height)
                context.scaleBy(x: 1, y: -1)

                //----------------------------------------------------------------------------
                // D E B U G
                if debugColor {
                    context.setFillColor(UIColor.systemOrange.cgColor)
                    context.fill(CGRect(origin: .zero, size: r.size))
                }
                //----------------------------------------------------------------------------

                /// UIKit-Bridge für die Ausgabe im PDF-Renderer, um UIImage zu zeichnen
                UIGraphicsPushContext(context)                // ★ neu
                attach.image.draw(in: CGRect(origin: .zero, size: r.size))
                UIGraphicsPopContext()                        // ★ neu

                context.restoreGState()
            }
        }
    }
    
    ///---------------------------------------------------------------------------------------
    /// Preprocessing der Bilder - Das Image Attachment erzeugen und in den Attributen ablegen
    ///
    func preprocessImages(_ src: NSAttributedString) -> NSMutableAttributedString {

        /// Attribute bleiben erhalten
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
    var blockContent: BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert

    init(blockContent: BlockContent) {
        self.blockContent = blockContent
        self.blockContent.attrText = preprocessImages(blockContent.attrText)
    }
    
    func draw(in context: CGContext) {
        guard let block = blockContent.block else { return }
        
        if block.hasBlockQuote {
            let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            drawBlockQuote(in: context, rect: rect)
        }
        
        //------------------------------------------------------------------------------------
        // D E B U G
        
        if debugColor {
            
            /// Zeichnen der Fläche des Inhaltes
            context.setFillColor(UIColor.systemYellow.highlight.cgColor)
            var colorRect = contentRect
            colorRect.origin.x   = 30.0
            colorRect.size.width = 500.0
            context.fill(colorRect)

            let (before, after) = blockContent.attrText.paragraphSpacings
            let indent: CGFloat = blockContent.attrText.ctParagraphStyleValue(for: .firstLineHeadIndent) ?? 0
            
            /// Zeichnen des Rechteckes für Paragraph Spacing Before
            context.setFillColor(UIColor.systemIndigo.highlight.highlight.cgColor)
            let rectBefore = CGRect(x: indent, y: frame.height - before, width: frame.width, height: before)
            context.fill(rectBefore)
            
            /// Zeichnen des Rechteckes für Paragraph Spacing (danach)
            context.setFillColor(UIColor.systemTeal.highlight.highlight.cgColor)
            let rectAfter = CGRect(x: indent, y: 0, width: frame.width, height: after)
            context.fill(rectAfter)
            
            /// Zeichnen des Rechtecks des gesamten Absatzes
            context.setLineWidth(4)
            context.addRect(CGRect(x: 0, y: 1, width: frame.width, height: frame.height).insetBy(dx: 2, dy: 2))
            context.setStrokeColor(UIColor.systemOrange.cgColor)
            context.strokePath()
            
            
            /// Umranden des Rechteckes für Paragraph Spacing (danach)
            context.move(to:    CGPoint(x: 0,           y: after))
            context.addLine(to: CGPoint(x: frame.width, y: after))
            context.setStrokeColor(UIColor.systemTeal.cgColor)
            context.strokePath()
            
            /// Umranden des Rechteckes für Paragraph Spacing Before
            context.move(to:    CGPoint(x: 0,           y: frame.height - before))
            context.addLine(to: CGPoint(x: frame.width, y: frame.height - before))
            context.setStrokeColor(UIColor.systemIndigo.cgColor)
            context.strokePath()
        }
        
        //------------------------------------------------------------------------------------

        drawContent(in: context)
    }
}


// -------- CodeBlock ---------------------------------------------------

final class CodeBlockRenderer: BlockRenderer {
    var blockContent: BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert
    private let text: NSAttributedString
    private let padding: UIEdgeInsets
    private let metrics: MarkdownTypography.CodeBlockMetrics
    
    init(blockContent: BlockContent) {
        self.blockContent = blockContent
        let fontStd  = blockContent.attrText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont
        let fontSize = fontStd?.pointSize ?? CGFloat(Markdown.textSize)
        let typography = MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: fontSize))
        self.metrics = typography.codeBlock
        let attachment = metrics.rectAttachment
        self.padding = UIEdgeInsets(top: attachment.rectInsetTop,
                                    left: attachment.rectInsetLeft,
                                    bottom: attachment.rectInsetBottom,
                                    right: attachment.rectInsetRight)
        
        /// Font einstellen
        let font = metrics.font
        let size = font.pointSize

        /// Wenn der Code Block als Language Hint 'tab4' hat, als Tabulator 4 Spaces sonst 8 Spaces verwenden.
        let tabHint = blockContent.block?.languageHint ?? ""

        /// Tabulatoren einstellen (Defaultwert 4)
        let spacesPerTab = tabHint.contains("tab8") ? 8 : 4
        let tabText = String(repeating: "1", count: spacesPerTab)
        let tabWidth = tabText.size(withAttributes: [.font: font]).width
        
        /// Klasse des Syntax-Highlighters laden und aufrufen
        let syntaxHighlight = SyntaxHighlight(filename: "IdentifierPalette")
        var attrString = syntaxHighlight.makeHighlighted(code: blockContent.attrText.string,
                                                         fontSize: size)
        
        /// Den Defaultwert für die Abstände der Tabulatoren und der Einzüge setzen
        let tabs = (1...10).map { NSTextTab(textAlignment: .left, location: CGFloat($0) * tabWidth) }
        
        if let paragraphStyle = blockContent.attrText.attribute(.paragraphStyle,
                                                       at: 0,
                                                       effectiveRange: nil) as? NSMutableParagraphStyle {
            paragraphStyle.tabStops            = tabs
            paragraphStyle.defaultTabInterval  = tabWidth
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.headIndent          = 0
            paragraphStyle.tailIndent          = 0
            paragraphStyle.lineHeightMultiple  = metrics.lineHeightMultiple
            paragraphStyle.minimumLineHeight   = 0
            
            /// Den Text übernehmen und die Attribute des Absatzes zufügen.
            attrString.mergeAttributes(AttributeContainer([.paragraphStyle: paragraphStyle]))
       }
        self.text = NSAttributedString(attrString)
    }
    
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {

        let availableWidth = width - metrics.outerLeftIndent - metrics.outerRightIndent
        let innerWidth = availableWidth - padding.left - padding.right

        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let constraint = CGSize(width: innerWidth, height: .greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            fs,
            CFRange(location: 0, length: text.length),
            nil,
            constraint,
            nil
        )

        let textHeight = ceil(size.height)
        let totalHeight = textHeight + padding.top + padding.bottom

        self.frame = CGRect(x: metrics.outerLeftIndent,
                            y: y,
                            width: availableWidth,
                            height: totalHeight)

        return totalHeight + metrics.paragraphSpacing
    }

    func draw(in context: CGContext) {

        // Hintergrund
        let textColor = text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? M.textColor
        let backgroundColor = MC.useDefaultBackgroundColor ? textColor.codeBlockBackgroundColor : MC.backgroundColor
        let borderColor = MC.useDefaultBorderColor ? textColor.codeBlockBorderColor : MC.borderColor
        let borderWidth = metrics.rectAttachment.borderWidth
        context.setFillColor(backgroundColor.cgColor)
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(borderWidth)

        /// Den Rahmen um die halbe Linienbreite nach innen ziehen, damit er vollständig im Frame liegt.
        let inset = max(borderWidth / 2, 0)
        let rectBackground = CGRect(origin: .zero, size: frame.size)
        context.addPath(
            UIBezierPath(
                roundedRect: rectBackground.insetBy(dx: inset, dy: inset),
                cornerRadius: metrics.rectAttachment.rectCornerRadius
            ).cgPath
        )
        context.drawPath(using: borderWidth > 0 ? .fillStroke : .fill)

        // Text
        let textRect = rectBackground.inset(by: padding)

        let path = CGMutablePath()
        path.addRect(textRect)

        let fs = CTFramesetterCreateWithAttributedString(text as CFAttributedString)
        let ctFrame = CTFramesetterCreateFrame(fs,
                                               CFRange(location: 0, length: text.length),
                                               path,
                                               nil)
        CTFrameDraw(ctFrame, context)
    }
}


// -------- Table -------------------------------------------------------
final class TableRenderer: BlockRenderer {
    var blockContent: BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert

    private typealias MT = Markdown.Table
    
    private let tableBlock: BlockContent.TableBlock
    private let cells: [[NSAttributedString?]]
    private let padding: UIEdgeInsets
    private let gridLineWidth: CGFloat
    private let minimumColumnWidth: CGFloat
    private let minimumRowHeight: CGFloat
    private var columnWidths: [CGFloat]
    private var rowHeights: [CGFloat] = []
    private var tableRect: CGRect = .zero
    
    init(blockContents: [BlockContent]) {
        let firstBlock = blockContents.first ?? BlockContent(attrText: NSAttributedString(), block: nil, range: AttributedString().startIndex..<AttributedString().endIndex)
        self.blockContent = firstBlock
        self.tableBlock = firstBlock.tableBlock
        let font = firstBlock.attrText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont ?? UIFont.systemFont(ofSize: CGFloat(Markdown.textSize))
        let typography = MarkdownTypography(bodyFont: font)
        let inset = max(4, typography.scaled(Markdown.Block.contentIndent * 0.5))
        self.padding = UIEdgeInsets(top: inset * 0.75, left: inset, bottom: inset * 0.75, right: inset)
        self.gridLineWidth = max(0.5, typography.thematicBreak.lineHeight * 0.5)
        self.minimumColumnWidth = max(36, typography.scaled(44))
        self.minimumRowHeight = max(typography.scaled(24), firstBlock.attrText.size().height + padding.top + padding.bottom)
        self.columnWidths = Self.preferredColumnWidths(from: tableBlock.columns,
                                                       padding: padding,
                                                       minimumColumnWidth: minimumColumnWidth)
        
        let rowCount = max(1, tableBlock.lastRow + 1)
        let columnCount = max(1, tableBlock.lastColumn + 1)
        var cells = Array(repeating: Array<NSAttributedString?>(repeating: nil, count: columnCount), count: rowCount)
        
        for content in blockContents {
            guard let block = content.block,
                  let row = block.tableRow,
                  let column = block.tableColumn,
                  row < rowCount,
                  column < columnCount
            else { continue }
            
            cells[row][column] = Self.cellText(from: content.attrText,
                                               row: row,
                                               column: column,
                                               tableBlock: tableBlock)
        }
        
        self.cells = cells
    }
    
    convenience init(blockContent: BlockContent) {
        self.init(blockContents: [blockContent])
    }
    
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        let hasBlockQuote = blockContent.block?.hasBlockQuote ?? false
        let typography = MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: fontSize))
        let leftIndent = hasBlockQuote ? typography.blockQuote.blockQuoteContentIndent : CGFloat(M.marginLeft)
        let availableWidth = max(0, width - leftIndent - CGFloat(M.marginRight))
        columnWidths = Self.fittedColumnWidths(from: tableBlock.columns,
                                               availableWidth: availableWidth,
                                               padding: padding,
                                               minimumColumnWidth: minimumColumnWidth)
        rowHeights = measureRowHeights(columnWidths: columnWidths)
        
        let tableHeight = rowHeights.reduce(0, +)
        let bottomSpacing = MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: fontSize)).paragraph.paragraphSpacing
        tableRect = CGRect(x: leftIndent, y: bottomSpacing, width: columnWidths.reduce(0, +), height: tableHeight)
        let totalHeight = tableHeight + bottomSpacing
        frame = CGRect(x: 0, y: y, width: width, height: totalHeight)
        return totalHeight
    }
    
    func draw(in context: CGContext) {
        guard !columnWidths.isEmpty, !rowHeights.isEmpty else { return }
        
        drawBackgrounds(in: context)
        drawCellTexts(in: context)
        drawGrid(in: context)
    }
    
    private static func cellText(from source: NSAttributedString,
                                 row: Int,
                                 column: Int,
                                 tableBlock: BlockContent.TableBlock) -> NSAttributedString {
        let text = NSMutableAttributedString(attributedString: source)
        let trimCharacters = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: String.paragraphSeparator))
        while text.length > 0,
              let lastScalar = text.string.unicodeScalars.last,
              trimCharacters.contains(lastScalar) {
            text.deleteCharacters(in: NSRange(location: text.length - 1, length: 1))
        }
        
        let sourceFont = source.length > 0 ? source.attribute(.font, at: 0, effectiveRange: nil) as? UIFont : nil
        let fontSize = sourceFont?.pointSize ?? CGFloat(Markdown.textSize)
        let weight = row == 0 ? MT.weightHeader : MT.weightText
        let font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        paragraph.alignment = column < tableBlock.columns.count ? tableBlock.columns[column].alignment : .left
        paragraph.lineHeightMultiple = CGFloat(Markdown.lineHeightMultiple)
        
        let range = NSRange(location: 0, length: text.length)
        text.addAttributes([.font: font, .paragraphStyle: paragraph], range: range)
        return text
    }
    
    private static func preferredColumnWidths(from columns: [BlockContent.TableColumn],
                                              padding: UIEdgeInsets,
                                              minimumColumnWidth: CGFloat) -> [CGFloat] {
        columns.map { column in
            max(minimumColumnWidth, column.lineWidth + padding.left + padding.right)
        }
    }
    
    private static func fittedColumnWidths(from columns: [BlockContent.TableColumn],
                                           availableWidth: CGFloat,
                                           padding: UIEdgeInsets,
                                           minimumColumnWidth: CGFloat) -> [CGFloat] {
        let preferredWidths = preferredColumnWidths(from: columns,
                                                    padding: padding,
                                                    minimumColumnWidth: minimumColumnWidth)
        guard !preferredWidths.isEmpty, availableWidth > 0 else { return preferredWidths }
        
        let preferredTotal = preferredWidths.reduce(0, +)
        guard preferredTotal > availableWidth else { return preferredWidths }
        
        let minimumTotal = minimumColumnWidth * CGFloat(preferredWidths.count)
        guard availableWidth > minimumTotal else {
            return Array(repeating: minimumColumnWidth, count: preferredWidths.count)
        }
        
        let shrinkableTotal = preferredWidths.reduce(0) { $0 + max(0, $1 - minimumColumnWidth) }
        let targetShrink = preferredTotal - availableWidth
        guard shrinkableTotal > 0 else { return preferredWidths }
        
        return preferredWidths.map { width in
            let shrinkableWidth = max(0, width - minimumColumnWidth)
            let shrink = targetShrink * shrinkableWidth / shrinkableTotal
            return floor(max(minimumColumnWidth, width - shrink))
        }
    }
    
    private func measureRowHeights(columnWidths: [CGFloat]) -> [CGFloat] {
        cells.map { rowCells in
            let heights = rowCells.enumerated().map { column, text -> CGFloat in
                guard let text else { return minimumRowHeight }
                let textWidth = max(1, columnWidths[column] - padding.left - padding.right)
                let hyphenatedText = text.insertingLineEndHyphens(width: textWidth)
                let framesetter = CTFramesetterCreateWithAttributedString(hyphenatedText as CFAttributedString)
                let constraint = CGSize(width: textWidth, height: .greatestFiniteMagnitude)
                let size = CTFramesetterSuggestFrameSizeWithConstraints(framesetter,
                                                                        CFRange(location: 0, length: hyphenatedText.length),
                                                                        nil,
                                                                        constraint,
                                                                        nil)
                return ceil(size.height) + padding.top + padding.bottom
            }
            return max(minimumRowHeight, heights.max() ?? minimumRowHeight)
        }
    }
    
    private func drawBackgrounds(in context: CGContext) {
        context.setFillColor(UIColor.secondarySystemBackground.cgColor)
        context.fill(tableRect)
        
        guard let headerHeight = rowHeights.first else { return }
        let headerRect = CGRect(x: tableRect.minX,
                                y: tableRect.maxY - headerHeight,
                                width: tableRect.width,
                                height: headerHeight)
        context.setFillColor(UIColor.tertiarySystemFill.cgColor)
        context.fill(headerRect)
    }
    
    private func drawGrid(in context: CGContext) {
        let halfLineWidth = gridLineWidth / 2
        let left = tableRect.minX + halfLineWidth
        let right = tableRect.maxX - halfLineWidth
        let bottom = tableRect.minY + halfLineWidth
        let top = tableRect.maxY - halfLineWidth
        
        context.setStrokeColor(UIColor.separator.cgColor)
        context.setLineWidth(gridLineWidth)
        context.setLineCap(.butt)
        
        context.move(to: CGPoint(x: left, y: bottom))
        context.addLine(to: CGPoint(x: left, y: top))
        
        var x = tableRect.minX
        for (index, width) in columnWidths.enumerated() {
            x += width
            let lineX = index == columnWidths.count - 1 ? right : x
            context.move(to: CGPoint(x: lineX, y: bottom))
            context.addLine(to: CGPoint(x: lineX, y: top))
        }
        
        context.move(to: CGPoint(x: left, y: top))
        context.addLine(to: CGPoint(x: right, y: top))
        
        var y = tableRect.maxY
        for (index, height) in rowHeights.enumerated() {
            y -= height
            let lineY = index == rowHeights.count - 1 ? bottom : y
            context.move(to: CGPoint(x: left, y: lineY))
            context.addLine(to: CGPoint(x: right, y: lineY))
        }
        context.strokePath()
    }
    
    private func drawCellTexts(in context: CGContext) {
        var rowTop = tableRect.maxY
        for (rowIndex, rowCells) in cells.enumerated() {
            let rowHeight = rowHeights[rowIndex]
            var x = tableRect.minX
            
            for (columnIndex, text) in rowCells.enumerated() {
                defer { x += columnWidths[columnIndex] }
                guard let text else { continue }
                
                let textRect = CGRect(x: x + padding.left,
                                      y: rowTop - rowHeight + padding.bottom,
                                      width: max(1, columnWidths[columnIndex] - padding.left - padding.right),
                                      height: max(1, rowHeight - padding.top - padding.bottom))
                let hyphenatedText = text.insertingLineEndHyphens(width: textRect.width)
                let path = CGMutablePath()
                path.addRect(textRect)
                let framesetter = CTFramesetterCreateWithAttributedString(hyphenatedText as CFAttributedString)
                let frame = CTFramesetterCreateFrame(framesetter,
                                                     CFRange(location: 0, length: hyphenatedText.length),
                                                     path,
                                                     nil)
                CTFrameDraw(frame, context)
            }
            rowTop -= rowHeight
        }
    }
}

final class HorizontalRuleRenderer: BlockRenderer {
    var blockContent: BlockContent
    var frame: CGRect = .zero
    var pageIndex: Int = 0                 // 0-basiert

    private let text: NSAttributedString
   
    init(blockContent: BlockContent) {
        self.blockContent = blockContent
        self.text = blockContent.attrText
    }
    func measure(y: CGFloat, width: CGFloat) -> CGFloat {
        let metrics = MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: fontSize)).thematicBreak
        let h = metrics.height
        self.frame = CGRect(x: 0, y: y, width: width, height: h)
        return h
    }
    
    func draw(in context: CGContext) {
        guard let block = blockContent.block else { return }

        let typography = MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: fontSize))
        let metrics = typography.thematicBreak

        /// Linker und rechter Rand des Absatztextes ermitteln. Innerhalb eines BlockQuote
        /// gelten die Block-internen Ränder, sonst die globalen Dokument-Ränder.
        let textLeft: CGFloat
        let textRight: CGFloat
        if block.hasBlockQuote {
            let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            drawBlockQuote(in: context, rect: rect)

            let bq = typography.blockQuote
            textLeft  = bq.blockQuoteContentIndent
            textRight = frame.width - bq.blockQuoteRightIndent
        } else {
            textLeft  = CGFloat(M.marginLeft)
            textRight = frame.width - CGFloat(M.marginRight)
        }

        let color: UIColor
        if MR.useHighlightColor {
            /// Die Standardfarbe wird aus der Textfarbe abgeleitet.
            let textColor = text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? M.textColor
            color = textColor.highlight
        } else {
            color = MR.color
        }

        let y  = CGFloat(frame.height/2)
        let x1 = textLeft  + metrics.paddingLeft
        let x2 = textRight - metrics.paddingRight
        context.move(to: CGPoint(x: x1, y: y))
        context.addLine(to: CGPoint(x: x2, y: y))
        context.setLineWidth(metrics.lineHeight)
        context.setStrokeColor(color.cgColor)
        context.strokePath()
    }
}
