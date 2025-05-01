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
    
    static let _1cm: CGFloat = 1 / 2.54 * 72                    /// 1cm in Zoll umrechnen und 72dpi Standard

    /// Soft Break aktivieren
    static var useSoftBreaks : Bool = true                      /// Soft Breaks aktivieren / deaktivieren
    
    /// Konstanten für die Tabelle
    static var tableWeightText   : UIFont.Weight = .regular     /// Stil des Textes in der Tabelle
    static var tableWeightHeader : UIFont.Weight = .bold        /// Stil der Überschrift in der Tabelle
    static var tableWeightBox    : UIFont.Weight = .ultraLight  /// Stil der Balken in der Tabelle
    static var tableColorBox     : UIColor?      = nil          /// Farbe der Balken der Tabelle

    /// Konstanten für die Liste (Anführungszeichen der Liste in der Hierarchie)
    static var listBulletPoint         :[String] = [.listBullet_1, .listBullet_2, .listBullet_3]
    static var listLeftIndent          : CGFloat = 10           /// Linker Rand der untersten Hierarchie

    /// Konstanten für den vertikalen Trennstrich (Ruler)
    static var rulerRightIndent        : CGFloat = 5            /// rechter Rand der Trennlinie
    static var rulerHeight             : CGFloat = 20           /// Höhe des Hintergrundes der Trennlinie
    static var rulerLineHeight         : CGFloat = 4            /// Strichdicke der Trennlinie
    static var rulerColorHighLight     : Bool    = true         /// Die Farbe der Trennlinie wird etwas heller
                                                                /// als die Textfarbe dargestellt
    /// Konstanten für den Hintergrund des Block Quote
    static var blockquoteContentIndent : CGFloat = 30           /// Abstand des Inhaltes vom Rand des Block Quote
    static var blockquoteHorzIndent    : CGFloat = 0            /// Ränder Hintergrund links und rechts
    static var blockquoteVertOffset    : CGFloat = 5            /// Verschiebung des  Hintergrunds nach unten
    static var blockquoteColor         : UIColor = .systemGray6 /// Farbe für den Hintergrund
    
    static var blockquoteBarIndent     : CGFloat = 5            /// Linker Rand des Balkens
    static var blockquoteBarWidth      : CGFloat = 10           /// Breite des Balkens
    static var blockquoteBarColor      : UIColor = .systemGray4 /// Farbe für den Balken
    
    /// Konstanten für den Code Block
    static var codeblockTextsize       : CGFloat = 14           /// Größe des Textfonts im Code Block
    
    /// Konstanten für den  Header
    static var fontSizes: [UIUserInterfaceIdiom : [CGFloat]] =  /// Gerätespezifische Fontgrößen für  Header
    [.mac:   [34, 30, 24, 20, 18, 16],
     .pad:   [32, 24, 20, 18, 16, 16],
     .phone: [24, 18, 16, 16, 16, 16]]
}


//--------------------------------------------------------------------------------------------
// MARK: - Definition für spezielle Zeichen

public extension String {
    static var tabulator:    String = "ⓣ"            /// Anzeige des Tabulators ⓣ   \u{2186}
    static var lineBreak:    String = "⬇"             /// Anzeige von Line Break ↆ  \u{2b07}
    static var objReplace:   String = "￼"             /// Objekt-Ersatz (Attachment) \u{fffc}
    static var punctuation:  String = "⸻"          /// Supplemental Punctuation \u{2eb3}

    static var listBullet_1: String = "•"             /// Bullet 1   \u{2022}   Standard Bullet
    static var listBullet_2: String = "⚬"             /// Bullet 2   \u{26ac}   Medium Small White Circle
    static var listBullet_3: String = "⁃"             /// Bullet 3   \u{2043}  Hyphen Bullett

    static var listBullet_4: String = "◦"             /// Bullet 4   \u{25e6}   White Bullet (sehr klein)
    static var listBullet_5: String = "◆"             /// Bullet 5   \u{25c6}   Black Diamond (groß)
    static var listBullet_6: String = "◇"             /// Bullet 6   \u{25c7}   White Diamond (groß)
    static var listBullet_7: String = "○"             /// Bullet 7   \u{25cb}   White Circle (groß)
    static var listBullet_8: String = "●"             /// Bullet 8   \u{25cf}   Black Circle (groß)
    
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

