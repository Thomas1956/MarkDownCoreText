//
//  MarkdownParser.swift
//  CoreTextTableExample
//
//  Created by Thomas on 02.05.25.
//

import UIKit
import CoreText


//--------------------------------------------------------------------------------------------
// MARK: - Parser für die Auswertung des Markdown-Syntax

public class MarkdownParser {

    /// Struktur für die Typographie
    static var typo = MarkdownTypography(bodyFont: UIFont.systemFont(ofSize: 16))
    
    /// PDF-Metadaten aus dem YAML Front Matter des aktuellen Dokumentes.
    static var pdfFooter = PDFDocumentFooter()

    ///---------------------------------------------------------------------------------------
    /// Main entry: parse Markdown string, build renderers, trigger layout
    ///
    static func markdown(string: String, size: CGFloat = 17, weight: UIFont.Weight = .regular,
                         textColor: UIColor = .gray) -> [BlockRenderer]
    {
        /// Typographie mit der Fontgröße aktualisieren
        typo.bodyFont(UIFont.systemFont(ofSize: size, weight: weight))
        
        let parsedDocument = parseDocumentMetadata(from: string)
        pdfFooter = parsedDocument.footer
        
        /// E-Mail-Autolinks `<x@y.tld>` werden von Foundations Markdown-Parser nicht als Link
        /// erkannt. Wir schreiben sie vor dem Parsen in einen klassischen Markdown-Link mit
        /// `mailto:`-Schema um – danach läuft die normale Link-Styling-/Tap-Pipeline.
        let preProcessed = rewriteEmailAutolinks(in: parsedDocument.markdown)
        
        /// Automatischen Silbentrennung mit dem Einfügen von Soft-Hyphen
        let string = preProcessed.stringWithHyphens()

        let rawAttr: AttributedString
        do {
            rawAttr = try AttributedString(markdown: string, including: \.commonAttr)
        } catch {
            var fallback = AttributedString("Markdown‑Konvertierung fehlgeschlagen: \(error.localizedDescription)")
            fallback.foregroundColor = .systemRed
            fallback.font = .systemFont(ofSize: 20, weight: .bold)
              
            let blockContent = BlockContent(attrText: NSAttributedString(fallback),
                                            block: PresentationIntent(.paragraph, identity: 1),
                                            range: fallback.startIndex..<fallback.endIndex)

            return [ParagraphRenderer(blockContent: blockContent)]
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
        // MARK: - \n durch Line Separator ersetzen und Tabulatoren entfernen (außer Code Block)
        
        /// Einmaliges Aufsetzen eines mutable Strings
        let mutable = NSMutableAttributedString(attr)

        /// Nur die relevanten Runs (in umgekehrter Reihenfolge) durchgehen
        for block in attr.runs.reversed() {
            /// Nur Non-Code-Blocks bearbeiten
            if block.presentationIntent?.hasCodeBlock == true { continue }
         
            let nsRange = NSRange(block.range, in: attr)
            /// In allen Blöcken außer dem Code Block die TABs löschen und  \n duch .lineSeparator ersetzen.
            mutable.mutableString.replaceOccurrences(of: "\n", with: .lineSeparator, range: nsRange)
            mutable.mutableString.replaceOccurrences(of: "\t", with: "", range: nsRange)
        }
        /// Am Ende wieder in AttributedString zurückwandeln
        attr = AttributedString(mutable)
        
        //------------------------------------------------------------------------------------
        // MARK: - Inline-Presentation bearbeiten

        attr = inlinePresentation(text: attr, size: size, weight: weight)
        
        ///-----------------------------------------------------------------------------------
        /// Debuggen der Blöcke im AttributedString
        ///
        attr.debugInfo(.nothing, "Vorher")
        /// Debugging nach dem Inline-Presentation
//        attr.debugInfo(.presentationIntent, "Nach Inline Presentation")

        return CoreTextBlockFactory.renderers(from: attr, typography: typo)
    }

    //----------------------------------------------------------------------------------------
    // MARK: - E-Mail-Autolinks vorverarbeiten

    /// Ersetzt CommonMark-konforme E-Mail-Autolinks `<x@y.tld>` durch einen klassischen
    /// Markdown-Link `[x@y.tld](mailto:x@y.tld)`. Foundations Markdown-Parser erkennt die
    /// `<…>`-Form nicht als Link – nach dieser Umschreibung wird der E-Mail-Autolink wie
    /// jeder andere Link gestylet und tap-bar.
    private static func rewriteEmailAutolinks(in source: String) -> String {
        let pattern = #"<([A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,})>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return source }
        let ns = source as NSString
        let fullRange = NSRange(location: 0, length: ns.length)
        return regex.stringByReplacingMatches(in: source,
                                              options: [],
                                              range: fullRange,
                                              withTemplate: "[$1](mailto:$1)")
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Extension MarkdownParser

extension MarkdownParser {
    
    //----------------------------------------------------------------------------------------
    // MARK: - PDF-Dokument-Metadaten
    
    struct PDFDocumentFooter {
        var left: String?
        var center: String? = "Seite {page}"
        var right: String?
        
        var hasVisibleText: Bool {
            left?.isEmpty == false || center?.isEmpty == false || right?.isEmpty == false
        }
    }
    
    private struct ParsedMarkdownDocument {
        let markdown: String
        let footer: PDFDocumentFooter
    }
    
    private static func parseDocumentMetadata(from source: String) -> ParsedMarkdownDocument {
        guard source.hasPrefix("---") else {
            return ParsedMarkdownDocument(markdown: source, footer: PDFDocumentFooter())
        }
        
        let normalized = source.replacingOccurrences(of: "\r\n", with: "\n")
        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) == "---" else {
            return ParsedMarkdownDocument(markdown: source, footer: PDFDocumentFooter())
        }
        
        guard let closingIndex = lines.dropFirst().firstIndex(where: {
            $0.trimmingCharacters(in: .whitespacesAndNewlines) == "---"
        }) else {
            return ParsedMarkdownDocument(markdown: source, footer: PDFDocumentFooter())
        }
        
        let metadataLines = Array(lines[1..<closingIndex])
        let markdownLines = Array(lines[(closingIndex + 1)...])
        let footer = parseFooterMetadata(from: metadataLines)
        return ParsedMarkdownDocument(markdown: markdownLines.joined(separator: "\n"), footer: footer)
    }
    
    private static func parseFooterMetadata(from lines: [String]) -> PDFDocumentFooter {
        var footer = PDFDocumentFooter()
        var inFooterSection = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }
            
            if trimmed == "pdfFooter:" || trimmed == "footer:" {
                inFooterSection = true
                continue
            }
            
            let keyValue = trimmed.split(separator: ":", maxSplits: 1).map(String.init)
            guard keyValue.count == 2 else { continue }
            
            let key = keyValue[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = cleanMetadataValue(keyValue[1])
            
            if inFooterSection {
                switch key {
                case "left":   footer.left = value
                case "center": footer.center = value
                case "right":  footer.right = value
                default: break
                }
            } else {
                switch key {
                case "pdfFooterLeft", "footerLeft":     footer.left = value
                case "pdfFooterCenter", "footerCenter": footer.center = value
                case "pdfFooterRight", "footerRight":   footer.right = value
                default: break
                }
            }
        }
        return footer
    }
    
    private static func cleanMetadataValue(_ value: String) -> String? {
        var result = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if result == "null" || result == "nil" || result == "~" { return nil }
        
        if result.count >= 2,
           let first = result.first,
           let last = result.last,
           (first == "\"" && last == "\"" || first == "'" && last == "'") {
            result.removeFirst()
            result.removeLast()
        }
        return result
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Inline-Presentation bearbeiten
    
    static func inlinePresentation(text: AttributedString, size: CGFloat, weight: UIFont.Weight) -> AttributedString {
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

        ///-----------------------------------------------------------------------------------
        /// Link-Attribute visuell hervorheben (blaue Farbe + Unterstreichung). Das `.link`-Attribut
        /// selbst bleibt erhalten, sodass der Tap-Handler im View über die String-Position die URL
        /// auslesen und öffnen kann.
        for (linkValue, range) in attrText.runs[\.link] {
            guard linkValue != nil else { continue }
            var linkAttributes = AttributeContainer()
            linkAttributes.uiKit.foregroundColor = .systemBlue
            linkAttributes.uiKit.underlineStyle  = .single
            attrText[range].mergeAttributes(linkAttributes)
        }

        return attrText
    }
    
    
    //----------------------------------------------------------------------------------------
    // MARK: - Block‑Factory  (AttributedString → Renderer‑Liste)

    fileprivate enum CoreTextBlockFactory {

        /// Haupt‑Einstieg: komplette AttributedString in BlockRenderer aufspalten
        static func renderers(from attr: AttributedString, typography: MarkdownTypography) -> [BlockRenderer] {
            
            ///  Alle BlockContent‑Elemente ermitteln
            let blocks = BlockContent.allBlockContents(attrText: attr, typography: typography)
            
//            blocks.forEach { block in
//                print(block.attrText)
//            }
            
            /// Gruppen nach (kind, identity) zusammenfassen → je 1 Renderer
            var renderers: [BlockRenderer] = []
//            var currentTableBlock: BlockContent.TableBlock? = nil

            ///-------------------------------------------------------------------------------
            /// Einen Renderer aus dem BlockContent heraus erstellen
            ///
            func makeRenderer(intentBlock: BlockContent) {
                guard let block = intentBlock.block else { return }
                
                /// Code Block
                if block.hasCodeBlock {
                    renderers.append(CodeBlockRenderer(blockContent: intentBlock))
                }
                /// Ruler
                if block.hasThematicBreak {
                    renderers.append(HorizontalRuleRenderer(blockContent: intentBlock))
                }
                /// Tabelle
                if block.hasTable {
                    // Tabelle oder normaler Absatz?
                    let table = intentBlock.tableBlock
                    if table.lastColumn > 0 {
                        renderers.append(TableRenderer(blockContent: intentBlock))
                    } else {
                        renderers.append(ParagraphRenderer(blockContent: intentBlock))
                    }
                }
                /// Header
                if block.hasHeader {
                    renderers.append(ParagraphRenderer(blockContent: intentBlock))
                }
                /// Normaler Abstatz
                if block.hasParagraph {
                    renderers.append(ParagraphRenderer(blockContent: intentBlock))
                }
//                currentTableBlock = nil
            }

            var currentTableBlocks: [BlockContent] = []
            var currentTableIdentity: Int?
            
            func flushTableRenderer() {
                guard let first = currentTableBlocks.first else { return }
                let table = first.tableBlock
                if table.lastColumn > 0 {
                    renderers.append(TableRenderer(blockContents: currentTableBlocks))
                } else {
                    currentTableBlocks.forEach { makeRenderer(intentBlock: $0) }
                }
                currentTableBlocks.removeAll()
                currentTableIdentity = nil
            }
            
            for block in blocks {
                if let presentation = block.block,
                   presentation.hasTable,
                   let tableIdentity = presentation.tableIdentity {
                    if currentTableIdentity == nil || currentTableIdentity == tableIdentity {
                        currentTableBlocks.append(block)
                        currentTableIdentity = tableIdentity
                    } else {
                        flushTableRenderer()
                        currentTableBlocks.append(block)
                        currentTableIdentity = tableIdentity
                    }
                    continue
                }
                
                flushTableRenderer()
                makeRenderer(intentBlock: block)
     
//                if block.tableBlock.lastColumn > 0 {
//                    currentTableBlock = block.tableBlock
//                }
            }
            flushTableRenderer()
            return renderers
        }
    }
}

//--------------------------------------------------------------------------------------------
// MARK: - Extension für die PDF-Ausgabe

extension MarkdownParser {
    
    typealias M = Markdown
    
    ///---------------------------------------------------------------------------------------
    /// Liefert die Gesamt-Seitenzahl
    ///
    static func layoutForPDF(renderers:    [BlockRenderer],
                             pageWidth:    CGFloat,
                             pageHeight:   CGFloat,
                             topMargin:    CGFloat,
                             bottomMargin: CGFloat) -> Int {

        let printableHeight = pageHeight - topMargin - bottomMargin

        var y: CGFloat   = 0              // ← kein Rand mehr hier!
        var currentPage  = 0

        for index in renderers.indices {
            let r = renderers[index]
            var h = r.measure(y: y, width: pageWidth)

            if y + h > printableHeight {  // Grenze ist Printable‑Höhe
                currentPage += 1
                y = 0                     // nächstes Blatt, oben anfangen
                h = r.measure(y: y, width: pageWidth)
            }
            
            if shouldKeepWithNext(renderer: r,
                                  index: index,
                                  renderers: renderers,
                                  y: y,
                                  height: h,
                                  pageWidth: pageWidth,
                                  printableHeight: printableHeight) {
                currentPage += 1
                y = 0
                h = r.measure(y: y, width: pageWidth)
            }

            r.pageIndex = currentPage
            r.frame     = CGRect(x: 0, y: y, width: pageWidth, height: h)

            y += h
        }
        return currentPage + 1
    }
    
    private static func shouldKeepWithNext(renderer: BlockRenderer,
                                           index: Int,
                                           renderers: [BlockRenderer],
                                           y: CGFloat,
                                           height: CGFloat,
                                           pageWidth: CGFloat,
                                           printableHeight: CGFloat) -> Bool {
        guard y > 0,
              renderer.blockContent.block?.hasHeader == true,
              index + 1 < renderers.count
        else { return false }
        
        let nextRenderer = renderers[index + 1]
        guard nextRenderer.blockContent.block?.hasHeader != true else { return false }
        
        let nextHeight = nextRenderer.measure(y: y + height, width: pageWidth)
        let combinedHeight = height + nextHeight
        
        return combinedHeight <= printableHeight && y + combinedHeight > printableHeight
    }
    
        
    //----------------------------------------------------------------------------------------
    // MARK: - PDF-Fußzeile
    
    private static func resolvedFooterText(_ text: String?, page: Int, pages: Int) -> String? {
        guard var result = text, !result.isEmpty else { return nil }
        result = result.replacingOccurrences(of: "{page}", with: "\(page)")
        result = result.replacingOccurrences(of: "{pages}", with: "\(pages)")
        result = result.replacingOccurrences(of: "{date}", with: Date.now.formatted(date: .numeric, time: .omitted))
        return result
    }
    
    private static func drawFooter(in ctx: CGContext,
                                   pageRect: CGRect,
                                   page: Int,
                                   pages: Int,
                                   footer: PDFDocumentFooter) {
        typealias MP = Markdown.PDF
        guard footer.hasVisibleText else { return }
        
        let font = UIFont.systemFont(ofSize: CGFloat(MP.textSize * MP.footerTextScale), weight: .regular)
        let textColor = Markdown.textColor.withAlphaComponent(0.75)
        let lineHeight = font.lineHeight
        let baselineY = max(4, (CGFloat(MP.marginBottom) - lineHeight) / 2 + font.ascender)
        let leftX = CGFloat(MP.marginLeft)
        let rightX = pageRect.width - CGFloat(MP.marginRight)
        let centerX = pageRect.midX
        
        func draw(_ text: String?, alignment: NSTextAlignment) {
            guard let text else { return }
            let attr = NSAttributedString(string: text, attributes: [
                .font: font,
                .foregroundColor: textColor
            ])
            let line = CTLineCreateWithAttributedString(attr)
            let width = CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
            
            let x: CGFloat
            switch alignment {
            case .center: x = centerX - width / 2
            case .right:  x = rightX - width
            default:      x = leftX
            }
            
            ctx.textMatrix = .identity
            ctx.textPosition = CGPoint(x: x, y: baselineY)
            CTLineDraw(line, ctx)
        }
        
        draw(resolvedFooterText(footer.left, page: page, pages: pages), alignment: .left)
        draw(resolvedFooterText(footer.center, page: page, pages: pages), alignment: .center)
        draw(resolvedFooterText(footer.right, page: page, pages: pages), alignment: .right)
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - PDF-Export
    
    static func exportPDF(renderers: [BlockRenderer], presentSavePanel: () -> URL?) throws {

        typealias MP = Markdown.PDF
        
        // -------- PDF-Seiten-Geometrie ------------------------------------
        
        var pageRect = MP.pageRect      /// Standard-Maße A4:  21 cm x 29,7 cm (Rand 2 cm)
        let printableWidth = pageRect.width - MP.marginLeft - MP.marginRight

        // -------- Renderer zuerst layouten --------------------------------
        let pageCount = layoutForPDF(renderers:    renderers,
                                     pageWidth:    printableWidth,
                                     pageHeight:   pageRect.height,
                                     topMargin:    MP.marginTop,
                                     bottomMargin: MP.marginBottom)

        // -------- Ziel-URL vom User holen ---------------------------------
        guard let url = presentSavePanel() else { return }

        // -------- PDF-Context anlegen -------------------------------------
        guard let ctx = CGContext(url as CFURL, mediaBox: &pageRect, nil) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSURLErrorKey: url])
        }

        // -------- Jede Seite einzeln zeichnen -----------------------------
        for p in 0 ..< pageCount {

            ctx.beginPDFPage(nil)

            // (0) globaler Flip → UIKit-Koordinaten
            ctx.saveGState()
            ctx.translateBy(x: 0, y: pageRect.height)
            ctx.scaleBy(x: 1, y: -1)

            // (1) linke / obere Margin
            ctx.translateBy(x: MP.marginLeft, y: MP.marginTop)

            // (2) alle Blöcke dieser Seite
            for r in renderers where r.pageIndex == p {

                ctx.saveGState()

                // 2a  zum Block-Ursprung (oben-links des Blocks!)
                ctx.translateBy(x: r.frame.minX, y: r.frame.minY)

                // 2b  **lokaler** Flip: oben-links → unten-links
                ctx.translateBy(x: 0, y: r.frame.height)
                ctx.scaleBy(x: 1, y: -1)

                // 2c  Core-Text zeichnet jetzt richtig herum
                r.draw(in: ctx)

                ctx.restoreGState()
            }

            ctx.restoreGState()   // beendet globales saveGState
            drawFooter(in: ctx,
                       pageRect: pageRect,
                       page: p + 1,
                       pages: pageCount,
                       footer: pdfFooter)
            ctx.endPDFPage()
        }
        ctx.closePDF()
    }
}
