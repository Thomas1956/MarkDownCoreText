//
//  ScrollView+Extension.swift
//  CoreTextTableExample
//
//  Created by Thomas on 29.04.25.
//

import UIKit
import CoreGraphics

private let a4Size = CGSize(width: 595.2, height: 841.8)   // A-4 in pt
private let margin : CGFloat = 36                          // 0,5″

//--------------------------------------------------------------------------------------------
// MARK: - Extension für die PDF-Aufbereitung

extension UIScrollView {

    /// Erstellt ein A-4-PDF (mehrseitig) mit 0,5″ Rand.
    func exportPDF_A4() -> Data? {

        guard contentSize.height > 0 else { return nil }

        // ---------- Printable-Bereich -------------------------------
        let printable = CGRect(x: margin,
                               y: margin,
                               width : a4Size.width  - 2*margin,
                               height: a4Size.height - 2*margin)

        // ---------- View ggf. schmaler / Skalierungsfaktor ----------
        let scale = printable.width / bounds.width
        let needsScale = scale < 1.0

        // ---------- Seitenhöhe im Scroll-Koordinatenraum ------------
        let pageHeight = printable.height / (needsScale ? scale : 1.0)
        let totalPages = Int(ceil(contentSize.height / pageHeight))

        // ---------- Original-Zustand sichern ------------------------
        let savedOffset = contentOffset

        // ---------- PDF-Renderer -----------------------------------
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero,
                                                            size: a4Size))

        let data = renderer.pdfData { ctx in
            for page in 0..<totalPages {

                ctx.beginPage()

                // 1. Margins
                ctx.cgContext.translateBy(x: printable.minX, y: printable.minY)

                // 2. Optionale Breiten-Skalierung
                if needsScale {
                    ctx.cgContext.scaleBy(x: scale, y: scale)
                }

                // 3. Clip auf Printable-Fenster
                ctx.cgContext.saveGState()
                ctx.cgContext.clip(to: CGRect(origin: .zero,
                                              size: CGSize(width: bounds.width,
                                                           height: pageHeight)))

                // 4. Sichtbereich scrollen  ⚑
                contentOffset = CGPoint(x: 0,
                                        y: CGFloat(page) * pageHeight)
                setNeedsLayout()          // wichtig bei Auto-Layout
                layoutIfNeeded()

                // 5. Rendern
                layer.render(in: ctx.cgContext)
                ctx.cgContext.restoreGState()
            }
        }

        // ---------- Zustand zurücksetzen ----------------------------
        contentOffset = savedOffset
        return data
    }
}

