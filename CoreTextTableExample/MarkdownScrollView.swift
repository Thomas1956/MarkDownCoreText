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
// MARK: MarkdownScrollView (Öffentliche API)
// --------------------------------------------------------------
//

class MarkdownScrollView: UIScrollView {
    
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
        showsVerticalScrollIndicator = true
        showsHorizontalScrollIndicator = false
    }

    ///---------------------------------------------------------------------------------------
    /// Main entry: parse Markdown string, build renderers, trigger layout
    ///
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
            guard let contentView = subviews.first as? MarkdownContentView else { return }

            contentView.renderers = [ParagraphRenderer(blockContent: blockContent)]
            setNeedsLayout(); return
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
        attr.debugInfo(.blocks, "Vorher")

        // ----------------------------------------------------------
        // PARSING:  AttributedString  →  [BlockRenderer]
        // ----------------------------------------------------------
        guard let contentView = subviews.first as? MarkdownContentView else { return }

        let renderers = CoreTextBlockFactory.renderers(from: attr, textSize: size)
        contentView.renderers = renderers
        setNeedsLayout()
    }

    // MARK: Layout
    override func layoutSubviews() {
        guard let contentView = subviews.first as? MarkdownContentView else { return }
        
        super.layoutSubviews()
        let width = bounds.width
        let totalHeight = contentView.layout(width: width)
        contentView.frame = CGRect(x: 0, y: 0, width: width, height: totalHeight)
        contentSize = CGSize(width: width, height: totalHeight)
        
        contentView.setNeedsDisplay()
    }

    // MARK: PDF‑Export
    func exportPDF(presentSavePanel: () -> URL?) {
        guard let contentView = subviews.first as? MarkdownContentView else { return }
        contentView.exportPDF(presentSavePanel: presentSavePanel)
    }
}


// MARK: - ---------------------------------------------------------
// MARK: Block‑Factory  (AttributedString → Renderer‑Liste)
// --------------------------------------------------------------

fileprivate enum CoreTextBlockFactory {

    /// Haupt‑Einstieg: komplette AttributedString in BlockRenderer aufspalten
    static func renderers(from attr: AttributedString, textSize: CGFloat) -> [BlockRenderer] {
        
        // 1) Alle BlockContent‑Elemente (liefert dein bestehender Code)
        let blocks = BlockContent.allBlockContents(attrText: attr, textSize: textSize)
        blocks.forEach { block in
            print(block.debugString)
        }
        
        // 2) Gruppen nach (kind, identity) zusammenfassen → je 1 Renderer
        var renderers: [BlockRenderer] = []
        var currentTableBlock: BlockContent.TableBlock? = nil

        func makeRenderer(intentBlock: BlockContent) {
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
 
