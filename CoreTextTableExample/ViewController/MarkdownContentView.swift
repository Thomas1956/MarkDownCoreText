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
        
        let rend = self.renderers.filter({ $0.frame.maxY > visibleRect.minY && $0.frame.minY < visibleRect.maxY})
        print("Anzahl:", rend.count)
        
        for renderer in rend {            // Reihenfolge 0 → N
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

