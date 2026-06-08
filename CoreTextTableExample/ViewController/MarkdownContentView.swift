//
//  MarkdownContentView.swift
//  CoreTextTableExample
//
//  Created by Thomas on 29.04.25.
//

import UIKit


//--------------------------------------------------------------------------------------------
// MARK: MarkdownContentView (zeichnet alles)

class MarkdownContentView: UIView {
    
    private var renderers: [BlockRenderer] = []

    func apply(_ renderers: [BlockRenderer]) {
        self.renderers = renderers
        invalidateIntrinsicContentSize()
        setNeedsLayout()
    }

    ///---------------------------------------------------------------------------------------
    /// Berechnet Breite und Höhe, ohne direkt das Frame zu setzen.
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let width = size.width
        let height = layout(width: width) // deine existing layout-Methode
        return CGSize(width: width, height: height)
    }

    override var intrinsicContentSize: CGSize {
        // Assume a default width (z.B. superview.bounds.width minus Insets)
        let width = superview?.bounds.width ?? UIScreen.main.bounds.width
        return sizeThatFits(CGSize(width: width - 20, height: .greatestFiniteMagnitude))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Hier nur Subviews positionieren, keine Content-Size setzen.
        _ = layout(width: bounds.width)
        
        self.setNeedsDisplay()
    }
 
    ///---------------------------------------------------------------------------------------
    /// Frames zuweisen & Gesamthöhe liefern
    ///
    @discardableResult
    func layout(width: CGFloat) -> CGFloat {
        /// Feste Einzüge nur für die Live-Anzeige (greifen nicht beim PDF-Export). Die effektive
        /// Breite wird hier reduziert; die x-Verschiebung passiert in `draw(_:)` via Context-Translation,
        /// damit der Frame nicht akkumuliert.
        let leftInset      = Markdown.LiveView.extraMarginLeft
        let rightInset     = Markdown.LiveView.extraMarginRight
        let effectiveWidth = max(0, width - leftInset - rightInset)

        /// Anzahl der Renderer ermitteln und das Array für die Höhen anlegen
        let count = renderers.count
        var heights = [CGFloat](repeating: 0, count: count)

        /// Parallele Höhen-Berechnung mit dem Aufruf von y = 0 .
        DispatchQueue.concurrentPerform(iterations: count) { i in
            heights[i] = renderers[i].measure(y: 0, width: effectiveWidth)
        }

        /// Serielles Setzen der Y-Position des Frames ohne Neuberechnung
        var y: CGFloat = 0
        for i in 0..<count {
            renderers[i].frame.origin.y = y
            y += heights[i]
        }
        return y
    }
        
    ///---------------------------------------------------------------------------------------
    /// Zeichnen des Inhaltes
    ///
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }

        /// D E B U G
        let start = DispatchTime.now()

        ///-----------------------------------------------------------------------------------
        /// Ermitteln des sichtbaren Rechtecks
        ///
        var visibleRect = rect
        if let scrollView = superview as? MarkdownScrollView {
            visibleRect.origin = scrollView.contentOffset
            visibleRect.size   = scrollView.frame.size
        }
        let minY = visibleRect.minY
        let maxY = visibleRect.maxY

        ///-----------------------------------------------------------------------------------
        /// StartIndex mit Binärer Suche ist möglich, weil Renderer sortiert sind.
        ///
        var lo = 0, hi = renderers.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if renderers[mid].frame.maxY < minY  { lo = mid + 1 }
            else                                 { hi = mid     }
        }
        let startIndex = lo

        ///-----------------------------------------------------------------------------------
        /// Zeichnen bis zum ersten Renderer, dessen oberer Rand außerhalb des sichtbaren Bereiches liegt.
        /// `liveLeftInset` verschiebt den Inhalt nur beim Zeichnen nach rechts und akkumuliert nicht.
        let liveLeftInset = Markdown.LiveView.extraMarginLeft

        for i in startIndex..<renderers.count {
            let renderer = renderers[i]
            let frame = renderer.frame

            if frame.minY > maxY { break }  /// Abbruch, wenn der Renderer außerhalb liegt

            ctx.saveGState()
            ctx.translateBy(x: frame.minX + liveLeftInset, y: frame.minY)         /// Ursprung an die Block‑Ecke (+ Live-Einzug)
            ctx.clip(to: CGRect(origin: .zero, size: frame.size)) /// Clipping auf Block‑Rect
            ctx.translateBy(x: 0, y: frame.height)                /// lokal flippen → Core‑Text will (0,0) unten links
            ctx.scaleBy(x: 1, y: -1)
            renderer.draw(in: ctx)                                /// Zeichnen
            ctx.restoreGState()
        }
        
        /// D E B U G
        let end = DispatchTime.now()
        let nano = end.uptimeNanoseconds - start.uptimeNanoseconds
        let seconds = Double(nano) / 1_000_000_000
//        print("draw dauerte \(seconds) Sekunden")
    }
}

