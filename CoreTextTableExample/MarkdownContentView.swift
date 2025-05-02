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
}

