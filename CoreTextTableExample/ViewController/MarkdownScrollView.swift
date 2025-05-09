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
    
    private var renderTask: Task<Void, Never>?
    private let debounceNanoseconds = 100 * 1_000_000  // 100 ms

    func markdown(string: String, size: CGFloat, weight: UIFont.Weight, textColor: UIColor) {
        // 1) Alte Aufgabe abbrechen
        renderTask?.cancel()
        
        renderTask = Task.detached(priority: .userInitiated) { [weak self] in
            // Zieh dir sofort ein starkes Alias und beende, falls nil:
            guard let strongSelf = self else { return }

            // 1) Debounce
            try? await Task.sleep(nanoseconds: UInt64(strongSelf.debounceNanoseconds))
            if Task.isCancelled { return }

            // 2) Heavy-Lifting
            let renderers = MarkdownParser.markdown(
                string: string,
                size: size,
                weight: weight,
                textColor: textColor
            )
            if Task.isCancelled { return }

            // 3) UI-Update auf MainActor, Capture nur strongSelf
            await MainActor.run { [strongSelf] in
                guard !Task.isCancelled,
                      let contentView = strongSelf.subviews.first as? MarkdownContentView
                else { return }
                
                contentView.apply(renderers)
                strongSelf.setNeedsLayout()
                strongSelf.layoutIfNeeded()
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard let contentView = subviews.first as? MarkdownContentView else { return }
        let width       = bounds.width - 20
        let totalHeight = contentView.layout(width: width)
        contentView.frame       = CGRect(x: 10, y: 0, width: width, height: totalHeight)
        contentSize             = CGSize(width: bounds.width, height: totalHeight)
    }
 }


