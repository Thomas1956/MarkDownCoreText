//
//  MarkdownParser+Statics.swift
//  MarkdownParser
//
//  Created by Thomas on 19.10.24.
//

import UIKit

//--------------------------------------------------------------------------------------------
// MARK: - Statische Definitionen für das Markdown-Rendering

public struct Markdown {
    
    /// Konstanten
    static let _1cm                   : Double = 1/2.54 * 72    /// 1cm in Zoll umrechnen und 72dpi Standard

    /// Globale Parameter
    static var textSize               : Double = 17             /// Eingestellte Fontgröße für View
    static var textColor              : UIColor = .black        /// Eingestellte Textfarbe

    static var headIndent             : Double = 0.0
    static var tailIndent             : Double = 0.0
    static var useSoftBreaks          : Bool    = true          /// Soft Breaks aktivieren / deaktivieren

    
    /// Abstände und Einzüge in 'em' als Multiplikator zum Text Size
    static var lineHeightMultiple     : Double = 1.1            /// Zeilenabstand Multiplikator
    static var paragraphSpacing       : Double = 0.5            /// Absatzabstand
    static var paragraphSpacingBefore : Double = 1.2            /// Absatzabstand vor einem Header
//    static var paddingHorz            : Double = 0.5          /// blockQouteSpacings
//    static var paddingBefore          : Double = 0.3
//    static var paddingAfter           : Double = 0.3
    
    /// Allgemeine Block-Metriken für CodeBlock, BlockQuote und Tabellen.
    struct Block {
        static let spacing       : CGFloat = 15
        static let spacingBefore : CGFloat = 15
        static let headIndent    : CGFloat = 10
        static let tailIndent    : CGFloat = 10
        static let contentIndent : CGFloat = 10
    }
    
    /// Gerätespezifische Referenzgrößen für Header
    static var fontSizes: [UIUserInterfaceIdiom: [CGFloat]] {
        [.mac:   [34, 30, 24, 20, 18, 16],
         .pad:   [32, 24, 20, 18, 16, 16],
         .phone: [24, 18, 16, 16, 16, 16]]
    }
    
    static func headerSpacing(level: Int, size: CGFloat) -> (before: CGFloat, after: CGFloat) {
        switch level {
        case 1:  return (before: size * 0.90, after: size * 0.30)
        case 2:  return (before: size * 0.75, after: size * 0.28)
        case 3:  return (before: size * 0.65, after: size * 0.24)
        case 4:  return (before: size * 0.55, after: size * 0.20)
        case 5:  return (before: size * 0.45, after: size * 0.18)
        default: return (before: size * 0.40, after: size * 0.16)
        }
    }

    /// Konstanten für den Edit View Controller
    struct Edit {
        static var textSize     : Double = 17                   /// Eingestellte Fontgröße für View
        static var textColor    : UIColor = .black              /// Eingestellte Textfarbe
    }
    
    /// Konstanten für die PDF-Ausgabe
    struct PDF {                                                /// Seitengröße A4
        static var pageRect     = CGRect(x: 0, y: 0, width: 21 * _1cm, height: 29.7 * _1cm)
        static var marginLeft   : Double = 2 * _1cm             /// Seitenränder definieren
        static var marginTop    : Double = 2 * _1cm
        static var marginRight  : Double = 2 * _1cm
        static var marginBottom : Double = 2 * _1cm
        static var textSize     : Double = 12                   /// Eingestellte Fontgröße für PDF
        static var footerTextScale: Double = 0.8                /// Schriftgröße der Fußzeile relativ zum Text
    }
    
    /// Konstanten für die Tabelle
    struct Table {
        static var weightText   : UIFont.Weight = .regular      /// Stil des Textes in der Tabelle
        static var weightHeader : UIFont.Weight = .bold         /// Stil der Überschrift in der Tabelle
        static var weightBox    : UIFont.Weight = .ultraLight   /// Stil der Balken in der Tabelle
        static var colorBox     : UIColor       = .clear        /// Farbe der Balken der Tabelle
    }
    
    /// Konstanten für die Liste (Anführungszeichen der Liste in der Hierarchie)
    struct List {
        static var bulletPoint      : [String] = [.listBullet_1, .listBullet_2, .listBullet_3]
        static var leftIndent       : Double = 10               /// Linker Rand der untersten Hierarchie
    }
    
    /// Konstanten für den vertikalen Trennstrich (Ruler)
    struct Ruler {
        static var rightIndent      : Double = 0                /// rechter Rand der Trennlinie
        static var height           : Double = 10               /// Höhe des Hintergrundes der Trennlinie
        static var lineHeight       : Double = 1.5              /// Strichdicke der Trennlinie
        static var colorHighLight   : Bool   = true             /// Die Farbe der Trennlinie wird etwas heller
        static var color            : UIColor = .systemGray4    /// Eigene Farbe, wenn colorHighLight aus ist
    }                                                           /// als die Textfarbe dargestellt
    
    /// Konstanten für den Hintergrund des Block Quote
    struct BlockQuote {
        static var contentIndent    : Double = 20               /// Abstand des Inhaltes vom Rand des Block Quote
        static var horizontalIndent : Double = 0                /// Ränder Hintergrund links und rechts
        static var verticalOffset   : Double = 5                /// Verschiebung des  Hintergrunds nach unten
        static var useDefaultBackgroundColor: Bool = true       /// Hintergrundfarbe aus Textfarbe ableiten
        static var backgroundColor  : UIColor = .systemGray6    /// Eigene Farbe für den Hintergrund
            
        static var barIndent        : Double = 5                /// Linker Rand des Balkens
        static var barWidth         : Double = 6                /// Breite des Balkens
        static var useDefaultBarColor: Bool = true              /// Balkenfarbe aus Textfarbe ableiten
        static var barColor         : UIColor = .systemGray4    /// Eigene Farbe für den Balken
    }
    
    /// Konstanten für den Code Block
    struct CodeBlock {
        static var codeTextSizeFactor : Double = 80.0           /// Prozentuale Größe des Textfonts im Code Block
        static var lineHeightMultiple : Double = 1.0            /// Zeilenabstand im Code Block
        static var spacing            : Double = 6.0            /// Abstand nach dem Code Block
        static var spacingBefore      : Double = 6.0            /// Abstand vor dem Code Block
        static var headIndent         : Double = 10.0           /// Linker Einzug des Code Blocks
        static var tailIndent         : Double = 10.0           /// Rechter Einzug des Code Blocks
        static var useDefaultBackgroundColor: Bool = true       /// Hintergrundfarbe aus Textfarbe ableiten
        static var backgroundColor    : UIColor = .systemGray6  /// Eigene Farbe für den Hintergrund
        static var useDefaultBorderColor: Bool = true           /// Rahmenfarbe aus Textfarbe ableiten
        static var borderColor        : UIColor = .systemGray4  /// Eigene Farbe für den Rahmen
        static var padding            = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Definition für spezielle Zeichen

public extension String {
    static var tabulator:    String = "ⓣ"               /// Anzeige des Tabulators ⓣ   \u{2186}
    static var lineBreak:    String = "⬇"               /// Anzeige von Line Break ↆ  \u{2b07}
    static var objReplace:   String = "￼"               /// Objekt-Ersatz (Attachment) \u{fffc}
    static var punctuation:  String = "⸻"            /// Supplemental Punctuation \u{2eb3}

    static var listBullet_1: String = "•"               /// Bullet 1   \u{2022}   Standard Bullet
    static var listBullet_2: String = "⚬"               /// Bullet 2   \u{26ac}   Medium Small White Circle
    static var listBullet_3: String = "⁃"               /// Bullet 3   \u{2043}  Hyphen Bullett

    static var listBullet_4: String = "◦"               /// Bullet 4   \u{25e6}   White Bullet (sehr klein)
    static var listBullet_5: String = "◆"               /// Bullet 5   \u{25c6}   Black Diamond (groß)
    static var listBullet_6: String = "◇"               /// Bullet 6   \u{25c7}   White Diamond (groß)
    static var listBullet_7: String = "○"               /// Bullet 7   \u{25cb}   White Circle (groß)
    static var listBullet_8: String = "●"               /// Bullet 8   \u{25cf}   Black Circle (groß)
    
    static var lineSeparator: String      = "\u{2028}"
    static var paragraphSeparator: String = "\u{2029}"
    static var downwardsArrow: String     = "⇩"
    static var nonBreakingSpace: String   = "\u{00A0}"
    static var mathematicSpace:  String   = "\u{205f}"  /// Medium Space für Leerzeile (mathematisch)
}

//--------------------------------------------------------------------------------------------
// MARK: - Unicode Rahmenzeichnung 2500–257F

extension String {
    static var heavy: Bool = false
    
    static let ve: String = heavy ? "┃" : "│"           /// Rahmen vertikal
    static let ho: String = heavy ? "━" : "─"           /// Rahmen horizontal
    static let ol: String = heavy ? "┏" : "┌"           /// Ecke oben links
    static let ul: String = heavy ? "┗" : "└"           /// Ecke unten links
    static let or: String = heavy ? "┓" : "┐"           /// Ecke oben rechts
    static let ur: String = heavy ? "┛" : "┘"           /// Ecke unten rechts
    static let ml: String = heavy ? "┣" : "├"           /// Rahmen mitte links
    static let mr: String = heavy ? "┫" : "┤"           /// Rahmen mitte rechts
    static let om: String = heavy ? "┳" : "┬"           /// Rahmen oben mitte
    static let um: String = heavy ? "┻" : "┴"           /// Rahmen unten mitte
    static let mi: String = heavy ? "╋" : "┼"           /// Rahmenkreuz mitte
}
