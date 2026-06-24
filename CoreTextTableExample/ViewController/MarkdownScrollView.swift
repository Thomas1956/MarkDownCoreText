//
//  MarkdownScrollView.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.04.25.
//


import UIKit
import CoreText
import PDFKit


//--------------------------------------------------------------------------------------------
// MARK: MarkdownScrollView 

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
    /// Asynchrones Rendern des Markdown Textes
    ///
    private var renderTask: Task<Void, Never>?
    private let debounceNanoseconds = 50 * 1_000_000  // 50 ms

    func markdown(string: String, size: CGFloat, weight: UIFont.Weight, textColor: UIColor) {
        /// Alte Aufgabe abbrechen
        renderTask?.cancel()

        renderTask = Task.detached(priority: .userInitiated) { [weak self] in
            /// Zieh dir sofort ein starkes Alias und beende, falls nil:
            guard let strongSelf = self else { return }

            /// Debounce, um schnelle Folgen des Taskes zu verhindern
            try? await Task.sleep(nanoseconds: UInt64(strongSelf.debounceNanoseconds))
            if Task.isCancelled { return }

            /// Bearbeiten des Rendern des Makdown Textes
            let renderers = MarkdownParser.markdown(string: string, size: size,
                                                    weight: weight, textColor: textColor)
            if Task.isCancelled { return }

            /// UI-Update über den MainActor
            await MainActor.run { [strongSelf] in
                guard !Task.isCancelled,
                      let contentView = strongSelf.subviews.first as? MarkdownContentView
                else { return }
                
                /// Renderer an den Content View übergeben
                contentView.apply(renderers)
                /// Aktualisieren
                strongSelf.setNeedsLayout()
                strongSelf.layoutIfNeeded()
            }
        }
    }
    
    ///---------------------------------------------------------------------------------------
    /// Aktualisieren der SubViews (contentSize setzen!)
    ///
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let contentView = subviews.first as? MarkdownContentView else { return }
        let width             = bounds.width - 20
        let totalHeight       = contentView.layout(width: width)
        contentView.frame     = CGRect(x: 10, y: 0, width: width, height: totalHeight)
        contentSize           = CGSize(width: bounds.width, height: totalHeight)
    }
 }


