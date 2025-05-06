//
//  MarkdownParser.swift
//  CoreTextTableExample
//
//  Created by Thomas on 02.05.25.
//

import UIKit


//--------------------------------------------------------------------------------------------
// MARK: - Parser für die Auswertung des Markdown-Syntax

public class MarkdownParser {

    ///---------------------------------------------------------------------------------------
    /// Main entry: parse Markdown string, build renderers, trigger layout
    ///
    static func markdown(string: String, size: CGFloat = 17, weight: UIFont.Weight = .regular,
                         textColor: UIColor = .gray) -> [BlockRenderer]
    {
        /// Automatischen Silbentrennung mit dem Einfügen von Soft-Hyphen
        let string = stringWithHyphens(string)
        
        let rawAttr: AttributedString
        do {
            rawAttr = try AttributedString(markdown: string, including: \.commonAttr)
        } catch {
            var fallback = AttributedString("Markdown‑Konvertierung fehlgeschlagen: \(error.localizedDescription)")
            fallback.foregroundColor = .systemRed
            fallback.font = .systemFont(ofSize: 20, weight: .bold)
              
            let blockContent = BlockContent(attrText: fallback)
            return [ParagraphRenderer(blockContent: blockContent)]
        }
        
        ///-----------------------------------------------------------------------------------
        /// Setzen der Defaultwerte für den Font und die Textfarbe (`.uikit` beachten!)
        var attr = rawAttr
        attr.font = .systemFont(ofSize: size, weight: weight)
        attr.uiKit.foregroundColor = textColor
         
        /// Setzen der Werte für Semi Globale Blöcke (wie Block Quote)
        /// Notwendig, damit innerhalb des Blockes (normalerweise graue Textfarbe) auch andere Farbe zulässig ist
        for (intentBlock, intentRange) in attr.runs[\.presentationIntent] {
            guard let intentKinds = intentBlock?.components.compactMap({$0.kind}),
                  intentKinds.contains(.blockQuote)
            else { continue }
            
            attr[intentRange].foregroundColor = .secondaryLabel
        }
        
        /// Die User-Atribute in die Formatierungsinformation ändern.
        attr.userAttributes(size: size, weight: weight)
        
        /// Am Ende des gesamten Textes einen Absatz ergänzen. Dadurch wird beispielsweise ein Block Quote mit einem
        /// Abstand am Ende angezeigt.
        attr += AttributedString(String.paragraphSeparator)

        //------------------------------------------------------------------------------------
        // MARK: - \n durch Line Separator ersetzen und Tabulatoren entfernen (außer Code Block)
        
        for block in attr.runs.reversed() {
            /// Den gesamten AttributedString in NSMutableAttributedString umwandeln und Range des Blockes konvertieren
            let nsAttrString = NSMutableAttributedString(attr)
            let nsRange = NSRange(block.range, in: attr)
            
            /// In allen Blöcken außer dem Code Block die TABs löschen und  \n duch .lineSeparator ersetzen.
            if block.presentationIntent?.hasCodeBlock == false {
                nsAttrString.mutableString.replaceOccurrences(of: "\t", with: "", range: nsRange)
                nsAttrString.mutableString.replaceOccurrences(of: "\n", with: .lineSeparator, range: nsRange)
            }
            attr = AttributedString(nsAttrString)
        }

        //------------------------------------------------------------------------------------
        // MARK: - Inline-Presentation bearbeiten

        attr = inlinePresentation(text: attr, size: size, weight: weight)
        
        ///-----------------------------------------------------------------------------------
        /// Debuggen der Blöcke im AttributedString
        ///
        attr.debugInfo(.none, "Vorher")
 
        return CoreTextBlockFactory.renderers(from: attr, textSize: size)
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Extension MarkdownParser

extension MarkdownParser {
    
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
        return attrText
    }
    
    
    //----------------------------------------------------------------------------------------
    // MARK: - Block‑Factory  (AttributedString → Renderer‑Liste)

    fileprivate enum CoreTextBlockFactory {

        /// Haupt‑Einstieg: komplette AttributedString in BlockRenderer aufspalten
        static func renderers(from attr: AttributedString, textSize: CGFloat) -> [BlockRenderer] {
            
            ///  Alle BlockContent‑Elemente ermitteln
            let blocks = BlockContent.allBlockContents(attrText: attr, textSize: textSize)
            
//            blocks.forEach { block in
//                print(block.attrText)
//            }
            
            /// Gruppen nach (kind, identity) zusammenfassen → je 1 Renderer
            var renderers: [BlockRenderer] = []
            var currentTableBlock: BlockContent.TableBlock? = nil

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
                    if let table = currentTableBlock, table.lastColumn > 0 {
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

        for r in renderers {
            let h = r.measure(y: y, width: pageWidth)

            if y + h > printableHeight {  // Grenze ist Printable‑Höhe
                currentPage += 1
                y = 0                     // nächstes Blatt, oben anfangen
            }

            r.pageIndex = currentPage
            r.frame     = CGRect(x: 0, y: y, width: pageWidth, height: h)

            y += h
        }
        return currentPage + 1
    }
    
        
    //----------------------------------------------------------------------------------------
    // MARK: - PDF-Export
    
    static func exportPDF(renderers: [BlockRenderer], presentSavePanel: () -> URL?) {

        // -------- PDF-Seiten-Geometrie ------------------------------------
        
        var pageRect = M.PDF.pageRect      /// Standard-Maße A4:  21 cm x 29,7 cm (Rand 2 cm)
        let printableWidth = pageRect.width - M.PDF.leftMargin - M.PDF.rightMargin

        // -------- Renderer zuerst layouten --------------------------------
        let pageCount = layoutForPDF(renderers:    renderers,
                                     pageWidth:    printableWidth,
                                     pageHeight:   pageRect.height,
                                     topMargin:    M.PDF.topMargin,
                                     bottomMargin: M.PDF.bottomMargin)

        // -------- Ziel-URL vom User holen ---------------------------------
        guard let url = presentSavePanel() else { return }

        // -------- PDF-Context anlegen -------------------------------------
        guard let ctx = CGContext(url as CFURL, mediaBox: &pageRect, nil) else { return }

        // -------- Jede Seite einzeln zeichnen -----------------------------
        for p in 0 ..< pageCount {

            ctx.beginPDFPage(nil)

            // (0) globaler Flip → UIKit-Koordinaten
            ctx.saveGState()
            ctx.translateBy(x: 0, y: pageRect.height)
            ctx.scaleBy(x: 1, y: -1)

            // (1) linke / obere Margin
            ctx.translateBy(x: M.PDF.leftMargin, y: M.PDF.topMargin)

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
            ctx.endPDFPage()
        }
        ctx.closePDF()
    }
}
