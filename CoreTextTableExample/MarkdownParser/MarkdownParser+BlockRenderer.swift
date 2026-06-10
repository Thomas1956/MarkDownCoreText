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
    /// Typographie-Metriken, die an der eingestellten Dokument-Schriftgröße hängen.
    var documentTypography: MarkdownTypography {
        MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: CGFloat(Markdown.textSize)))
    }
    
    ///---------------------------------------------------------------------------------------
    /// Umranden des Rechteckes für Paragraph Spacing (danach)
    var blockQouteSpacings: (paddingBefore: CGFloat, paddingAfter: CGFloat, paddingLeft: CGFloat, paddingRight: CGFloat) {
        guard let block = blockContent.block else { return (0, 0, 0, 0) }
        let blockQuote = documentTypography.blockQuote
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
        let blockQuote = documentTypography.blockQuote
        let attachment = blockQuote.rectAttachment

        /// Steht der BlockQuote innerhalb einer Liste, muss der Hintergrund dem Einzug der Liste folgen.
        /// `blockContent.blockQuoteIndent` enthält in diesem Fall die in `prepareBlocks` gemerkte Textposition
        /// der ersten Ebene des BlockQuote. Für alle anderen Fälle (kein BlockQuote in einer Liste — z.B.
        /// Listen-Items, die innerhalb eines top-level BlockQuote stehen) ist der Wert 0 und der Hintergrund
        /// wandert NICHT mit der inneren Hierarchie mit.
        let listOffset: CGFloat = blockContent.blockQuoteIndent

        var rect = rect
        rect.origin.x    += attachment.rectInsetLeft + listOffset
        rect.origin.y    += blockContent.isLastBlockQuote ? after : 0
        rect.size.width  -= attachment.rectInsetLeft + attachment.rectInsetRight + listOffset
        rect.size.height -= (blockContent.isLastBlockQuote ? after : 0) + (blockContent.isFirstBlockQuote ? before : 0)
        
        let textColor = blockContent.attrText.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? M.textColor
        let backgroundColor = MB.useDefaultBackgroundColor ? textColor.derivedFillColor : MB.backgroundColor
        context.setFillColor(backgroundColor.cgColor)
        context.fill(rect)
        
        /// Balken am linken Rand
        var balken = rect
        balken.origin.x  += attachment.stripeGap
        balken.size.width = attachment.stripeWidth
        let barColor = MB.useDefaultBarColor ? textColor.derivedStrokeColor : MB.barColor
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

        let pointSize = CGFloat(20)

        func makeImagePlaceholder(for token: String, at location: Int) -> NSAttributedString? {
            /// Den Font entweder aus dem Header, aus dem Paragraph ermitteln oder Standardfont
            /// Aus dem Font xHeight für die Berechnung der Mitte eines `-` ermitteln
            let font = (mutable.attribute(.font, at: location, effectiveRange: nil) as? UIFont) ?? UIFont.systemFont(ofSize: pointSize)

            /// Image Konfiguration ermitteln
            let config = UIImage.SymbolConfiguration(font: font)
                                .applying(UIImage.SymbolConfiguration.preferringMulticolor())

            func splitParameterList(_ string: String) -> [String] {
                var result: [String] = []
                var current = ""
                var quote: Character?

                for character in string {
                    if character == "'" || character == "\"" {
                        if quote == character {
                            quote = nil
                        } else if quote == nil {
                            quote = character
                        }
                    }

                    if character == "," && quote == nil {
                        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty { result.append(trimmed) }
                        current = ""
                    } else {
                        current.append(character)
                    }
                }

                let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { result.append(trimmed) }
                return result
            }

            func stripQuotes(_ string: String) -> String {
                var string = string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard string.count >= 2 else { return string }

                if (string.hasPrefix("\"") && string.hasSuffix("\"")) ||
                   (string.hasPrefix("'") && string.hasSuffix("'")) {
                    string.removeFirst()
                    string.removeLast()
                }
                return string
            }

            func parseSize(_ value: String, currentSize: CGSize) -> CGSize {
                let parts = stripQuotes(value)
                    .lowercased()
                    .split(separator: "x", maxSplits: 1)
                    .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                guard !parts.isEmpty else { return currentSize }

                let aspect = currentSize.width / currentSize.height

                if parts.count == 1,
                   let height = Double(parts[0]),
                   height > 0 {
                    return CGSize(width: CGFloat(height) * aspect, height: CGFloat(height))
                }

                guard parts.count == 2 else { return currentSize }
                let width = Double(parts[0]).map { CGFloat($0) } ?? currentSize.width
                let height = Double(parts[1]).map { CGFloat($0) } ?? currentSize.height
                return CGSize(width: width, height: height)
            }

            func parseColor(_ value: String) -> UIColor? {
                let value = stripQuotes(value)

                /// Asset-Farbe
                if let asset = UIColor(named: value) { return asset }

                /// Hex (#RRGGBB)
                if let hexColor = UIColor(hexstring: value) { return hexColor }

                /// Systemfarbnamen
                switch value {
                case "black": return .black
                case "blue": return .blue
                case "brown": return .brown
                case "clear": return .clear
                case "cyan": return .cyan
                case "darkGray": return .darkGray
                case "gray": return .gray
                case "green": return .green
                case "lightGray": return .lightGray
                case "magenta": return .magenta
                case "orange": return .orange
                case "purple": return .purple
                case "red": return .red
                case "white": return .white
                case "yellow": return .yellow
                case "label": return .label
                case "secondaryLabel": return .secondaryLabel
                case "tertiaryLabel": return .tertiaryLabel
                case "quaternaryLabel": return .quaternaryLabel
                case "systemBackground": return .systemBackground
                case "secondarySystemBackground": return .secondarySystemBackground
                case "tertiarySystemBackground": return .tertiarySystemBackground
                case "systemBlue": return .systemBlue
                case "systemBrown": return .systemBrown
                case "systemCyan": return .systemCyan
                case "systemGray": return .systemGray
                case "systemGray2": return .systemGray2
                case "systemGray3": return .systemGray3
                case "systemGray4": return .systemGray4
                case "systemGray5": return .systemGray5
                case "systemGray6": return .systemGray6
                case "systemGreen": return .systemGreen
                case "systemIndigo": return .systemIndigo
                case "systemMint": return .systemMint
                case "systemOrange": return .systemOrange
                case "systemPink": return .systemPink
                case "systemPurple": return .systemPurple
                case "systemRed": return .systemRed
                case "systemTeal": return .systemTeal
                case "systemYellow": return .systemYellow
                default: return nil
                }
            }

            let token = (token.removingPercentEncoding ?? token)
                .replacingOccurrences(of: "\u{00AD}", with: "")
                .replacingOccurrences(of: "\u{2010}", with: "")
            let parameters = splitParameterList(token)
            guard var imageToken = parameters.first else { return nil }

            var requestedSize: String?
            var requestedColor: UIColor?

            if let range = imageToken.range(of: ":") {
                requestedSize = String(imageToken[range.upperBound...])
                imageToken = String(imageToken[..<range.lowerBound])
            }

            for parameter in parameters.dropFirst() {
                guard let range = parameter.range(of: ":") else { continue }

                let key = parameter[..<range.lowerBound]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                let rawValue = String(parameter[range.upperBound...])

                switch key {
                case "color", "tint":
                    requestedColor = parseColor(rawValue)
                case "size":
                    requestedSize = rawValue
                default:
                    continue
                }
            }

            let imagename = stripQuotes(imageToken)
            guard !imagename.isEmpty,
                  let originalImage = UIImage(named: imagename) ??
                                      UIImage(systemName: imagename, withConfiguration: config)
            else { return nil }

            let image = requestedColor.map {
                originalImage.withTintColor($0, renderingMode: .alwaysOriginal)
            } ?? originalImage.withRenderingMode(.alwaysOriginal)
            
            ///-----------------------------------------------------------------------------------
            /// Größe des Images und das Seitenverhältnis ermitteln
            let imageSize = requestedSize.map { parseSize($0, currentSize: image.size) } ?? image.size
            let width  = imageSize.width
            let height = imageSize.height

            /// Attachment und Run-Delegate
            let attachment = ImageAttachment(image: image, size: .init(width: width, height: height), font: font)
            let delegate   = makeRunDelegate(for: attachment)

            /// Platzhalter-String
            return NSAttributedString(string: "\u{FFFC}",
                                      attributes: [ .runDelegate       : delegate,
                                                    .myImageAttachment : attachment ])
        }

        func imageURLToken(from value: Any?) -> String? {
            if let url = value as? URL { return url.relativeString }
            if let url = value as? NSURL { return url.relativeString }
            if let string = value as? String { return string }

            guard var token = (value as? AnyObject)?.description
            else { return nil }

            if token.hasPrefix("Optional("), token.hasSuffix(")") {
                token.removeFirst("Optional(".count)
                token.removeLast()
            }
            return token
        }

        var replacements: [(range: NSRange, placeholder: NSAttributedString)] = []

        mutable.enumerateAttribute(.imageURL, in: mutable.rangeAll, options: []) { value, nsRange, _ in
            guard let token = imageURLToken(from: value),
                  let placeholder = makeImagePlaceholder(for: token, at: nsRange.location)
            else { return }

            replacements.append((range: nsRange, placeholder: placeholder))
        }

        let originalString = mutable.string
        let pattern = #"!\[[^\]]*\]\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let fullRange = NSRange(location: 0, length: (originalString as NSString).length)
            let matches = regex.matches(in: originalString, range: fullRange)

            for match in matches {
                guard match.numberOfRanges > 1 else { continue }

                let token = (originalString as NSString).substring(with: match.range(at: 1))
                guard let placeholder = makeImagePlaceholder(for: token, at: match.range.location)
                else { continue }

                /// Nicht als Markdown geparste Images nachträglich ersetzen.
                replacements.append((range: match.range, placeholder: placeholder))
            }
        }

        for replacement in replacements.sorted(by: { $0.range.location > $1.range.location }) {
            mutable.replaceCharacters(in: replacement.range, with: replacement.placeholder)
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
            paragraphStyle.paragraphSpacing    = 0
            paragraphStyle.paragraphSpacingBefore = 0
            paragraphStyle.minimumLineHeight   = 0
            
            /// Den Text übernehmen und die Attribute des Absatzes zufügen.
            attrString.mergeAttributes(AttributeContainer([.paragraphStyle: paragraphStyle]))
       }
        self.text = NSAttributedString(attrString)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Linker und rechter Außenabstand des CodeBlock-Hintergrundes (vom Frame-Ursprung gemessen).
    /// - Innerhalb eines BlockQuote sitzt der CodeBlock im BlockQuote-Content-Bereich,
    ///   ggf. zusätzlich um den Listen-Hierarchie-Einzug verschoben.
    /// - Außerhalb wirkt der globale linke Dokument-Rand zzgl. `Markdown.CodeBlock.indentLeft`
    ///   (in `metrics.outerLeftIndent` enthalten) plus der Listen-Hierarchie-Einzug.
    private func boxOuterIndents() -> (left: CGFloat, right: CGFloat) {
        let typography = documentTypography
        guard blockContent.block?.hasBlockQuote ?? false else {
            return (metrics.outerLeftIndent + blockContent.codeBlockIndent,
                    metrics.outerRightIndent)
        }
        let bq = typography.blockQuote
        let extraLeft  = typography.scaled(CGFloat(MC.indentLeft))
        let extraRight = typography.scaled(CGFloat(MC.indentRight))
        return (bq.blockQuoteContentIndent + extraLeft + blockContent.codeBlockIndent,
                bq.blockQuoteRightIndent  + extraRight)
    }

    func measure(y: CGFloat, width: CGFloat) -> CGFloat {

        let hasBlockQuote = blockContent.block?.hasBlockQuote ?? false
        let (leftIndent, rightIndent) = boxOuterIndents()
        let availableWidth = max(0, width - leftIndent - rightIndent)
        let innerWidth = max(1, availableWidth - padding.left - padding.right)

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
        let boxHeight = textHeight + padding.top + padding.bottom
        let totalHeight = metrics.paragraphSpacingBefore + boxHeight + metrics.paragraphSpacing

        /// Innerhalb eines BlockQuote umfasst der Frame die volle Breite, damit der BlockQuote-BG
        /// (Balken + Hintergrund) auch hinter dem CodeBlock gezeichnet werden kann.
        let frameX = hasBlockQuote ? 0 : leftIndent
        let frameWidth = hasBlockQuote ? width : availableWidth
        self.frame = CGRect(x: frameX, y: y, width: frameWidth, height: totalHeight)

        return totalHeight
    }

    func draw(in context: CGContext) {

        let hasBlockQuote = blockContent.block?.hasBlockQuote ?? false

        /// CodeBlock-Hintergrund (relativ zum Frame). Bei BlockQuote wandert die linke Kante an die
        /// Content-Position des BlockQuote – sonst sitzt der Frame schon dort.
        let inset = max(metrics.rectAttachment.borderWidth / 2, 0)
        let boxLeft: CGFloat = hasBlockQuote ? boxOuterIndents().left : 0
        let boxWidth: CGFloat = hasBlockQuote ? frame.width - boxOuterIndents().left - boxOuterIndents().right
                                              : frame.width
        let rectBackground = CGRect(x: boxLeft,
                                    y: metrics.paragraphSpacing,
                                    width: boxWidth,
                                    height: frame.height - metrics.paragraphSpacingBefore - metrics.paragraphSpacing)

        /// BlockQuote-Hintergrund (Balken + BG) durchgängig hinter dem CodeBlock zeichnen,
        /// damit er optisch nicht unterbrochen wirkt. Die Breite ist die volle Frame-Breite –
        /// `drawBlockQuote` rechnet die BlockQuote-Insets (linker/rechter Rand inkl. Balken)
        /// intern auf den übergebenen Rechteck-Bereich an.
        ///
        /// Höhe: Im Inneren des BlockQuote läuft der BG über den vollen Frame (inkl. CodeBlock-
        /// `paragraphSpacingBefore`/`paragraphSpacing`), damit zwischen Nachbarn keine Lücke
        /// entsteht. An den Rändern des BlockQuote (`isFirstBlockQuote`/`isLastBlockQuote`)
        /// wird die CodeBlock-Spacing visuell oben bzw. unten ausgespart. Achtung: Der Context
        /// ist für Core Text geflippt – y wächst nach oben, also liegt das visuell obere
        /// Spacing am oberen Frame-Ende (= hohe y-Werte) und das visuell untere Spacing am
        /// unteren Frame-Ende (= y=0). Die in `drawBlockQuote` enthaltene zusätzliche
        /// Trimmung über `attrText.paragraphSpacings` wirkt hier nicht, weil diese beim
        /// CodeBlock auf 0 gesetzt sind – wir trimmen daher direkt mit den CodeBlock-Metriken.
        if hasBlockQuote {
            let topTrim    = blockContent.isFirstBlockQuote ? metrics.paragraphSpacingBefore : 0
            let bottomTrim = blockContent.isLastBlockQuote  ? metrics.paragraphSpacing       : 0
            let blockQuoteRect = CGRect(x: 0,
                                        y: bottomTrim,
                                        width: frame.width,
                                        height: frame.height - topTrim - bottomTrim)
            drawBlockQuote(in: context, rect: blockQuoteRect)
        }

        let textColor = M.textColor
        let backgroundColor = MC.useDefaultBackgroundColor ? textColor.derivedFillColor : MC.backgroundColor
        let borderColor = MC.useDefaultBorderColor ? textColor.derivedStrokeColor : MC.borderColor
        let borderWidth = metrics.rectAttachment.borderWidth
        context.setFillColor(backgroundColor.cgColor)
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(borderWidth)

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
        let typography = MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: CGFloat(Markdown.textSize)))
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
        /// Basis-Einzug links: innerhalb eines BlockQuote der bereits berechnete Content-Einzug,
        /// sonst der globale linke Dokument-Rand. Steht die Tabelle innerhalb einer Liste,
        /// wandert sie über `tableIndent` mit der Hierarchie mit. `Markdown.Table.indentLeft`
        /// und `indentRight` werden additiv darauf angewendet.
        let baseLeft = hasBlockQuote ? documentTypography.blockQuote.blockQuoteContentIndent : CGFloat(M.marginLeft)
        let leftIndent = baseLeft + blockContent.tableIndent + CGFloat(MT.indentLeft)
        let rightIndent = CGFloat(M.marginRight) + CGFloat(MT.indentRight)
        let availableWidth = max(0, width - leftIndent - rightIndent)
        columnWidths = Self.fittedColumnWidths(from: tableBlock.columns,
                                               availableWidth: availableWidth,
                                               padding: padding,
                                               minimumColumnWidth: minimumColumnWidth)
        rowHeights = measureRowHeights(columnWidths: columnWidths)
        
        let tableHeight = rowHeights.reduce(0, +)
        let bottomSpacing = documentTypography.paragraph.paragraphSpacing
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
        let textColor = Markdown.textColor
        let bodyColor = MT.useDefaultBackgroundColor ? textColor.derivedFillColor : MT.backgroundColor
        let headerColor = MT.useDefaultHeaderBackgroundColor ? textColor.derivedHeaderFillColor : MT.headerBackgroundColor

        context.setFillColor(bodyColor.cgColor)
        context.fill(tableRect)

        guard let headerHeight = rowHeights.first else { return }
        let headerRect = CGRect(x: tableRect.minX,
                                y: tableRect.maxY - headerHeight,
                                width: tableRect.width,
                                height: headerHeight)
        context.setFillColor(headerColor.cgColor)
        context.fill(headerRect)
    }

    private func drawGrid(in context: CGContext) {
        let halfLineWidth = gridLineWidth / 2
        let left = tableRect.minX + halfLineWidth
        let right = tableRect.maxX - halfLineWidth
        let bottom = tableRect.minY + halfLineWidth
        let top = tableRect.maxY - halfLineWidth

        let textColor = Markdown.textColor
        let gridColor = MT.useDefaultGridColor ? textColor.derivedStrokeColor : MT.gridColor

        context.setStrokeColor(gridColor.cgColor)
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
        let metrics = documentTypography.thematicBreak
        let h = metrics.height
        self.frame = CGRect(x: 0, y: y, width: width, height: h)
        return h
    }
    
    func draw(in context: CGContext) {
        guard let block = blockContent.block else { return }

        let metrics = documentTypography.thematicBreak

        /// Linker und rechter Rand des Absatztextes ermitteln. Innerhalb eines BlockQuote
        /// gelten die Block-internen Ränder, sonst die globalen Dokument-Ränder.
        let textLeft: CGFloat
        let textRight: CGFloat
        if block.hasBlockQuote {
            let rect = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
            drawBlockQuote(in: context, rect: rect)

            let blockQuote = documentTypography.blockQuote
            textLeft  = blockQuote.blockQuoteContentIndent
            textRight = frame.width - blockQuote.blockQuoteRightIndent
        } else {
            textLeft  = CGFloat(M.marginLeft)
            textRight = frame.width - CGFloat(M.marginRight)
        }

        let color: UIColor
        if MR.useHighlightColor {
            /// Die Standardfarbe wird aus der Textfarbe abgeleitet.
            let textColor = text.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor ?? M.textColor
            color = textColor.derivedStrokeColor
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

