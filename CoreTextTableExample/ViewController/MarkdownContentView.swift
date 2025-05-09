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
        setNeedsDisplay()
    }

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
        let start = DispatchTime.now()

        var y: CGFloat = 0
        for renderer in renderers {
            let h = renderer.measure(y: y, width: width)
            y += h
        }
        
        let end = DispatchTime.now()
        let nano = end.uptimeNanoseconds - start.uptimeNanoseconds
        let seconds = Double(nano) / 1_000_000_000
        print("layout dauerte \(seconds) Sekunden")

        return y
    }

    ///---------------------------------------------------------------------------------------
    /// Zeichnen des Inhaltes
    ///
    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
       
        let start = DispatchTime.now()

        self.backgroundColor = .white
        
        var visibleRect = rect
        if let scrollView = superview as? MarkdownScrollView {
            visibleRect.origin = scrollView.contentOffset;
            visibleRect.size = scrollView.frame.size;
         }
        
        // Annahme: renderers ist nach frame.origin.y aufsteigend sortiert
        let minY = visibleRect.minY
        let maxY = visibleRect.maxY

        // 1) Binary Search: erstes Element, dessen maxY > minY
        var lo = 0, hi = renderers.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if renderers[mid].frame.maxY < minY {
                lo = mid + 1
            } else {
                hi = mid
            }
        }
        let startIndex = lo

        // 2) Durchlaufen bis zum ersten, dessen minY > maxY
        for i in startIndex..<renderers.count {
            let renderer = renderers[i]
            if renderer.frame.minY > maxY { break }

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
        
        let end = DispatchTime.now()
        let nano = end.uptimeNanoseconds - start.uptimeNanoseconds
        let seconds = Double(nano) / 1_000_000_000
        print("draw dauerte \(seconds) Sekunden")
    }
}

