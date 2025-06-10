//
//  SettingViewController+BlockQuote.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.05.25.
//

import UIKit
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension SettingViewController für den Inhalt einer Sektion

extension SettingViewController  {
    
    //----------------------------------------------------------------------------------------
    // MARK: - Definition der Inhalte einer Sektion

    /// Alle Attribute von BasicDetail sind in der Extension des Protokolls mit Defaultwerten vorbelegt. Demzufolge können alle
    /// standardmäßig genutzten, nicht benötigten Attribute aus dem ENUM gelöscht werden.
    ///
    enum BlockQuoteSetting: String, BasicDetail, CaseIterable {

        case blockHorizIndent, blockBarIndent, blockContentIndent, blockBarWidth,
             blockVerticalOffset, blockBarColor, blockBackColor
        
        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .blockHorizIndent:    "Horizontale Einzüge"
            case .blockBarIndent:      "Abstand zum Balken"
            case .blockContentIndent:  "Abstand zum Inhalt"
            case .blockBarWidth:       "Balkenbreite"
            case .blockVerticalOffset: "Vertikaler Offset"
            default: nil
            }
        }
        
        /// Platzhalter bei Texteingaben
        var placeholder: String? {
            switch self {            
            default: nil
            }
        }
                
        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            default: .einsNachkomma
            }
        }
        
        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            default: .number
            }
        }
        
        ///-----------------------------------------------------------------------------------
        /// Textstil und Größen für die Positionierung
        ///
        var textstyle            : UIFont.TextStyle?       { .body }
        var configurationWidth   : CGFloat?                {  nil  }
        var configurationHeight  : CGFloat?                {  nil  }
        var configurationMargins : NSDirectionalEdgeInsets { .zero }
        
        ///-----------------------------------------------------------------------------------
        /// Zusätzliche Daten für BasicType für  Parametrierungen
        ///
        var image: ImageSourceConvertible? {
            switch self {
            default: nil
            }
        }
        
        var presentation: ContentPresentation? {       /// Defaultmäßig wird TITLE verwendet
            switch self {
            default: nil
            }
        }

        var widthUsage: WidthUsage?  { nil }           /// Defaultmäßig wirkt die Breite auf LABEL
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionBlockQuoteSetting(_ settings: Settings, forEditing: Bool) {
        typealias Content = BlockQuoteSetting
        let rwo : ContentRWType = forEditing ? .rw : .ro

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        items.append(.basic([Content.blockHorizIndent  .data(settings),
                             Content.blockBarIndent    .data(settings),
                             Content.blockContentIndent.data(settings),
                            ]))
        
        items.append(.basic([Content.blockBarWidth      .data(settings),
                             Content.blockVerticalOffset.data(settings),
                            ]))

        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        var sectionSnapshot = SectionSnapshot()
        sectionSnapshot.append(SectionContent.BlockQuoteSetting, items: items.itemType)
        dataSource.apply(sectionSnapshot, to: SectionContent.BlockQuoteSetting.title, animatingDifferences: true)
    }
}
