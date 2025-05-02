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
    /// Main entry: parse Markdown string, build renderers, trigger layout
    ///
    func markdown(string: String, size: CGFloat, weight: UIFont.Weight, textColor: UIColor) {
        
        guard let contentView = subviews.first as? MarkdownContentView else { return }
        contentView.markdown(string: string, size: size, weight: weight, textColor: textColor)
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
}


