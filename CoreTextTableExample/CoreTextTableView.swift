//
//  Table.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.04.25.
//
/*
import UIKit
import CoreText

// Simple data model for the table
struct Table {
    let headers: [String]
    let rows: [[String]]
}

/// Custom UIView that draws a table using Core Text
class CoreTextTableView: UIView {
    var table: Table?
    var font: UIFont = UIFont.systemFont(ofSize: 18)
    let padding: CGFloat = 8

    override init(frame: CGRect) {
        super.init(frame: frame)
        // White background so text is visible
        backgroundColor = .white
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(), let table = table else { return }
        // Flip coordinate system: origin at bottom-left
        context.textMatrix = .identity
        context.translateBy(x: 0, y: bounds.height)
        context.scaleBy(x: 1.0, y: -1.0)

        let colCount = table.headers.count
        let colWidth = bounds.width / CGFloat(colCount)

        // Measure header cell heights and pick max
        let headerHeights = table.headers.map { measureHeight(text: $0, width: colWidth) }
        let headerHeight = headerHeights.max() ?? 0
        // Measure each data row's height (max of its cells)
        let rowHeights: [CGFloat] = table.rows.map { row in
            row.map { measureHeight(text: $0, width: colWidth) }.max() ?? 0
        }

        // Build Y positions for all horizontal grid lines
        // Start at top (y = bounds.height)
        var yPositions: [CGFloat] = [bounds.height]
        // After header
        yPositions.append(yPositions.last! - headerHeight)
        // After each row
        for h in rowHeights {
            yPositions.append(yPositions.last! - h)
        }

        // Build X positions for vertical grid lines
        var xPositions: [CGFloat] = [0]
        for i in 1...colCount {
            xPositions.append(CGFloat(i) * colWidth)
        }

                // Draw grid lines once
        let gridPath = CGMutablePath()
        // Horizontal lines across full table width
        for y in yPositions {
            gridPath.move(to: CGPoint(x: 0, y: y))
            gridPath.addLine(to: CGPoint(x: bounds.width, y: y))
        }
        // Vertical lines only between top and bottom of table
        let topY = yPositions.first!  // starting at bounds.height
        let bottomY = yPositions.last! // lowest grid line
        for x in xPositions {
            gridPath.move(to: CGPoint(x: x, y: bottomY))
            gridPath.addLine(to: CGPoint(x: x, y: topY))
        }
        context.addPath(gridPath)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(1)
        context.strokePath()

        // Draw text in each cell
        let totalRows = 1 + table.rows.count // header + body
        for rowIndex in 0..<totalRows {
            let cellHeight = (rowIndex == 0 ? headerHeight : rowHeights[rowIndex - 1])
            for colIndex in 0..<colCount {
                let text: String
                if rowIndex == 0 {
                    text = table.headers[colIndex]
                } else {
                    text = table.rows[rowIndex - 1][colIndex]
                }
                let attr = attributedString(for: text)
                let framesetter = CTFramesetterCreateWithAttributedString(attr)
                // Inset cell for padding
                let textRect = CGRect(
                    x: xPositions[colIndex] + padding,
                    y: yPositions[rowIndex + 1] + padding,
                    width: colWidth - 2 * padding,
                    height: cellHeight - 2 * padding
                )
                let textPath = CGMutablePath()
                textPath.addRect(textRect)
                let frame = CTFramesetterCreateFrame(
                    framesetter,
                    CFRangeMake(0, CFAttributedStringGetLength(attr)),
                    textPath,
                    nil
                )
                CTFrameDraw(frame, context)
            }
        }
    }

    private func attributedString(for text: String) -> CFAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: style
        ]
        return NSAttributedString(string: text, attributes: attributes) as CFAttributedString
    }

    private func measureHeight(text: String, width: CGFloat) -> CGFloat {
        let attr = attributedString(for: text)
        let framesetter = CTFramesetterCreateWithAttributedString(attr)
        let constraint = CGSize(width: width - 2 * padding,
                                height: .greatestFiniteMagnitude)
        let size = CTFramesetterSuggestFrameSizeWithConstraints(
            framesetter,
            CFRangeMake(0, CFAttributedStringGetLength(attr)),
            nil,
            constraint,
            nil
        )
        return ceil(size.height) + 2 * padding
    }
}

*/
