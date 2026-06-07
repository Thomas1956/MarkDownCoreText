//
//  MarkdownTypography.swift
//  CoreTextTableExample
//
//  Adapted from MarkdownParserKit.
//

import UIKit

//--------------------------------------------------------------------------------------------
// MARK: - Markdown Typography

struct MarkdownTypography {
    
    //----------------------------------------------------------------------------------------
    // MARK: Nested Types
    
    struct ParagraphMetrics {
        let font: UIFont
        let lineHeightMultiple: CGFloat
        let paragraphSpacing: CGFloat
        let paragraphSpacingBefore: CGFloat
        let firstLineHeadIndent: CGFloat
        let headIndent: CGFloat
    }
    
    struct HeaderMetrics {
        let level: Int
        let font: UIFont
        let paragraphSpacingBefore: CGFloat
        let paragraphSpacing: CGFloat
        let firstLineHeadIndent: CGFloat
        let headIndent: CGFloat
    }
    
    struct CodeBlockMetrics {
        let font: UIFont
        let lineHeightMultiple: CGFloat
        let paragraphSpacingBefore: CGFloat
        let paragraphSpacing: CGFloat
        /// Abstand der BG-Box vom linken Frame-Rand (= `viewHeadIndent` + `codeLeftIndent`).
        let outerLeftIndent: CGFloat
        /// Abstand der BG-Box vom rechten Frame-Rand (= `viewTailIndent` + `codeRightIndent`).
        let outerRightIndent: CGFloat
        let rectAttachment: RectAttachment
    }
    
    struct BlockQuoteMetrics {
        let blockQuoteContentIndent: CGFloat
        let blockQuoteRightIndent: CGFloat
        let lineHeightMultiple: CGFloat
        let paragraphSpacingBefore: CGFloat
        let paragraphSpacing: CGFloat
        let headIndent: CGFloat
        let tailIndent: CGFloat
        let rectAttachment: RectAttachment
    }
    
    struct RulerMetrics {
        let leftIndent: CGFloat
        let rightIndent: CGFloat
        let height: CGFloat
        let lineHeight: CGFloat
    }
    
    /// Rechteck-Parameter fuer Hintergruende in BlockQuote und CodeBlock.
    struct RectAttachment {
        let rectInsetTop: CGFloat
        let rectInsetBottom: CGFloat
        let rectInsetLeft: CGFloat
        let rectInsetRight: CGFloat
        let stripeWidth: CGFloat
        let stripeGap: CGFloat
        let rectCornerRadius: CGFloat
        let borderWidth: CGFloat
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: Constants
    
    /// Referenzgroesse, fuer die die Markdown.fontSizes definiert wurden.
    static let referenceBodySize: CGFloat = 16.0
    
    //----------------------------------------------------------------------------------------
    // MARK: Stored Properties
    
    var bodyFont: UIFont
    var monospacedFont: UIFont
    let device: UIUserInterfaceIdiom
    var scale: CGFloat
    
    //----------------------------------------------------------------------------------------
    // MARK: Init
    
    init(bodyFont: UIFont, device: UIUserInterfaceIdiom? = nil) {
        self.bodyFont = bodyFont
        self.monospacedFont = .monospacedSystemFont(ofSize: bodyFont.pointSize, weight: .regular)
        self.scale = bodyFont.pointSize / Self.referenceBodySize
        self.device = device ?? UIDevice.current.userInterfaceIdiom
    }
    
    mutating func bodyFont(_ font: UIFont) {
        self.bodyFont = font
        self.monospacedFont = .monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
        self.scale = font.pointSize / Self.referenceBodySize
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: Base Values
    
    func scaled(_ value: CGFloat, rounded: Bool = false) -> CGFloat {
        let result = value * scale
        return rounded ? round(result) : result
    }
    
    private var referenceHeaderSizes: [CGFloat] {
        Markdown.fontSizes[device] ?? Markdown.fontSizes[.phone] ?? [24, 18, 16, 16, 16, 16]
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: Paragraph
    
    var paragraph: ParagraphMetrics {
        ParagraphMetrics(
            font: bodyFont,
            lineHeightMultiple: CGFloat(Markdown.lineHeightMultiple),
            paragraphSpacing: bodyFont.pointSize * CGFloat(Markdown.paragraphSpacing),
            paragraphSpacingBefore: 0,
            firstLineHeadIndent: 0,
            headIndent: 0
        )
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: Header
    
    func header(level: Int) -> HeaderMetrics {
        let safeLevel = min(max(level, 1), 6)
        let refSize = referenceHeaderSizes.indices.contains(safeLevel - 1)
            ? referenceHeaderSizes[safeLevel - 1]
            : referenceHeaderSizes.last ?? bodyFont.pointSize
        let size = scaled(refSize, rounded: true)
        let font = UIFont.systemFont(ofSize: size, weight: .bold)
        let spacing = Markdown.headerSpacing(level: safeLevel, size: size)
        
        return HeaderMetrics(
            level: safeLevel,
            font: font,
            paragraphSpacingBefore: spacing.before,
            paragraphSpacing: spacing.after,
            firstLineHeadIndent: 0,
            headIndent: 0
        )
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: Code Block
    
    var codeBlock: CodeBlockMetrics {
        typealias MC = Markdown.CodeBlock

        let size = bodyFont.pointSize * CGFloat(MC.textSizeFactor / 100)
        let font = UIFont.monospacedSystemFont(ofSize: size, weight: .regular)

        let spacing = scaled(10)
        let rectInsetTop    = 0.40 * spacing
        let rectInsetBottom = spacing - rectInsetTop

        /// Globale Dokument-Einzüge (`viewHeadIndent` / `viewTailIndent`).
        let viewLeft  = CGFloat(Markdown.headIndent)
        let viewRight = -CGFloat(Markdown.tailIndent)

        /// Die BG-Box ist additiv zu den Dokument-Einzügen eingerückt.
        let outerLeftIndent  = viewLeft  + scaled(CGFloat(MC.leftIndent))
        let outerRightIndent = viewRight + scaled(CGFloat(MC.rightIndent))

        /// Innenabstände vom BG-Rand zum Text.
        let rectInsetLeft  = scaled(CGFloat(MC.contentLeftIndent))
        let rectInsetRight = scaled(CGFloat(MC.contentRightIndent))

        return CodeBlockMetrics(
            font: font,
            lineHeightMultiple: CGFloat(MC.lineHeightMultiple),
            paragraphSpacingBefore: scaled(CGFloat(MC.spacingBefore)),
            paragraphSpacing: scaled(CGFloat(MC.spacing)),
            outerLeftIndent: outerLeftIndent,
            outerRightIndent: outerRightIndent,
            rectAttachment: RectAttachment(
                rectInsetTop: rectInsetTop,
                rectInsetBottom: rectInsetBottom,
                rectInsetLeft: rectInsetLeft,
                rectInsetRight: rectInsetRight,
                stripeWidth: 0,
                stripeGap: 0,
                rectCornerRadius: scaled(8),
                borderWidth: scaled(CGFloat(MC.borderWidth))
            )
        )
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: Block Quote
    
    var blockQuote: BlockQuoteMetrics {
        typealias MB = Markdown.BlockQuote
        
        let refSize = referenceHeaderSizes.first ?? referenceHeaderSizes.last ?? bodyFont.pointSize
        let size = scaled(refSize, rounded: true)
        let spacing = 2 * Markdown.headerSpacing(level: 0, size: size).after
        
        let stripeWidth        = scaled(CGFloat(MB.barWidth))
        let stripeGap          = scaled(CGFloat(MB.barIndent))
        let rectInsetTop       = scaled(CGFloat(MB.verticalOffset))
        let rectInsetBottom    = max(0, spacing - rectInsetTop)
        let contentLeftIndent  = scaled(CGFloat(MB.contentLeftIndent))
        let contentRightIndent = scaled(CGFloat(MB.contentRightIndent))

        /// Globale Dokument-Einzüge (`viewHeadIndent` / `viewTailIndent`). `Markdown.tailIndent`
        /// ist negativ gespeichert, deshalb steht hier `-tailIndent` für den positiven Rechts-Rand.
        let viewLeft  = CGFloat(Markdown.headIndent)
        let viewRight = -CGFloat(Markdown.tailIndent)

        /// Der Hintergrund des BlockQuote ist additiv zu den Dokument-Einzügen eingerückt.
        let rectInsetLeft  = viewLeft  + scaled(CGFloat(MB.leftIndent))
        let rectInsetRight = viewRight + scaled(CGFloat(MB.rightIndent))

        let headIndent = scaled(Markdown.Block.headIndent)
        let tailIndent = rectInsetRight + scaled(Markdown.Block.tailIndent)

        /// Linke und rechte Position des BlockQuote-Textes (absolut, vom Frame-Ursprung).
        let leftTextIndent  = rectInsetLeft  + stripeGap + stripeWidth + contentLeftIndent
        let rightTextIndent = rectInsetRight + contentRightIndent

        return BlockQuoteMetrics(
            blockQuoteContentIndent: leftTextIndent,
            blockQuoteRightIndent:   rightTextIndent,
            lineHeightMultiple: paragraph.lineHeightMultiple,
            paragraphSpacingBefore: scaled(Markdown.Block.spacingBefore),
            paragraphSpacing: scaled(Markdown.Block.spacing),
            headIndent: headIndent,
            tailIndent: tailIndent,
            rectAttachment: RectAttachment(
                rectInsetTop: rectInsetTop,
                rectInsetBottom: rectInsetBottom,
                rectInsetLeft: rectInsetLeft,
                rectInsetRight: rectInsetRight,
                stripeWidth: stripeWidth,
                stripeGap: stripeGap,
                rectCornerRadius: 0,
                borderWidth: 0
            )
        )
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: Thematic Break (Ruler)
    
    var thematicBreak: RulerMetrics {
        RulerMetrics(
            leftIndent : scaled(CGFloat(Markdown.Ruler.leftIndent)),
            rightIndent: scaled(CGFloat(Markdown.Ruler.rightIndent)),
            height     : scaled(CGFloat(Markdown.Ruler.height)),
            lineHeight : scaled(CGFloat(Markdown.Ruler.lineHeight))
        )
    }
}
