//
//  MarkdownContentView.swift
//  CoreTextTableExample
//
//  Created by Thomas on 29.04.25.
//
import UIKit
import CoreText
import PDFKit


// MARK: - ---------------------------------------------------------
// MARK: MarkdownContentView (zeichnet alles)
// --------------------------------------------------------------

class MarkdownContentView: UIView {

    /// Länge von 1cm in PPI
    static let _1cm = Markdown._1cm
    
    var renderers: [BlockRenderer] = []

    /// Frames zuweisen & Gesamthöhe liefern
    @discardableResult
    func layout(width: CGFloat) -> CGFloat {
        var y: CGFloat = 0
        for renderer in renderers {
            let h = renderer.measure(y: y, width: width)
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
    /// Liefert die Gesamt-Seitenzahl
    func layoutForPDF(pageWidth:    CGFloat,
                      pageHeight:   CGFloat,
                      topMargin:    CGFloat = 2 * _1cm,
                      bottomMargin: CGFloat = 2 * _1cm) -> Int {

        var y: CGFloat = topMargin
        var currentPage = 0

        for r in renderers {

            let h = r.measure(y: y, width: pageWidth)

            // Passt der Block noch auf die aktuelle Seite?
            if y + h > pageHeight - bottomMargin {

                // neue Seite
                currentPage += 1
                y = topMargin          // wieder oben anfangen
            }

            r.pageIndex = currentPage
            r.frame     = CGRect(x: 0,
                                 y: y,
                                 width: pageWidth,
                                 height: h)

            y += h
        }
        return currentPage + 1          // Seiten sind 0-basiert
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - PDF-Export
    
    func exportPDF(presentSavePanel: () -> URL?) {

        // -------- PDF-Seiten-Geometrie ------------------------------------
        
        /// Maße A4:  21 cm x 29,7 cm (Rand 2 cm)
        var pageRect = CGRect(x: 0, y: 0, width: 21 * Self._1cm, height: 29.7 * Self._1cm)
        
        let margin: CGFloat = 2 * Markdown._1cm
        let printableWidth  = pageRect.width  - 2*margin

        // -------- Renderer zuerst layouten --------------------------------
        let pageCount = layoutForPDF(pageWidth:    printableWidth,
                                     pageHeight:   pageRect.height,
                                     topMargin:    margin,
                                     bottomMargin: margin)

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
            ctx.translateBy(x: margin, y: margin)

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


// MARK: - ---------------------------------------------------------
// MARK: Block‑Factory  (AttributedString → Renderer‑Liste)
// --------------------------------------------------------------
/*
public enum CoreTextBlockFactory {

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
                renderers.append(ParagraphRenderer(blockContent: intentBlock))
//                renderers.append(HeadingRenderer(blockContent: intentBlock))
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
 
*/
