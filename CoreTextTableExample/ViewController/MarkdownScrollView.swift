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
    /// Queue für das Berechnen / Rendern des Attributed-Strings
    private let renderQueue = DispatchQueue(
        label: "app.markdown.render",
        qos: .userInitiated
    )
    /// Aktueller, noch nicht abgeschlossener Render-Task
    private var pendingRender: DispatchWorkItem?

    ///---------------------------------------------------------------------------------------
    /// Main entry: parse Markdown string, build renderers, trigger layout
    ///
    func markdown(string: String, size: CGFloat, weight: UIFont.Weight, textColor: UIColor) {
        print("markdown \(string.count)")
    
        guard let contentView = subviews.first as? MarkdownContentView else { return }
        
        /// Abbrechen aller noch laufenden Render-Jobs
        pendingRender?.cancel()
        let deadline = DispatchTime.now() + .milliseconds(100)

        /// Neuen Work-Item erzeugen
        var workItem: DispatchWorkItem!
        workItem = DispatchWorkItem(qos: .userInitiated) { [weak self] in
            guard let self = self, !workItem.isCancelled else { return }

            /// Generieren der Block Renderer
            let renderers = MarkdownParser.markdown(string: string, size: size, weight: weight, textColor: textColor)

            /// Falls der Task nicht abgebrochen wurde, Updaten wir die UI
            DispatchQueue.main.async {
                guard !workItem.isCancelled else { return }
                /// Block Renderer an den Content View übergeben
                contentView.apply(renderers)
                self.layoutSubviews()
            }
        }
        pendingRender = workItem

        /// Auf der Hintergrund-Queue starten
        renderQueue.asyncAfter(deadline: deadline, execute: workItem)
     }
    
    // MARK: Layout
    override func layoutSubviews() {
        print("layoutSubViews \(bounds.width)")

        guard let contentView = subviews.first as? MarkdownContentView else { return }
        super.layoutSubviews()
        
        let width = bounds.width
        let totalHeight = contentView.layout(width: width - 20)
        contentView.frame = CGRect(x: 5, y: 0, width: width - 20, height: totalHeight)
        self.contentSize = CGSize(width: width, height: totalHeight)
        
        contentView.setNeedsDisplay()
    }
}


