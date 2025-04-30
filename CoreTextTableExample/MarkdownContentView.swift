// MARK: - ---------------------------------------------------------
// MARK: MarkdownContentView (zeichnet alles)
// --------------------------------------------------------------
class MarkdownContentView: UIView {
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
 
