//
//  SettingViewController+Content.swift
//  CoreTextTableExample
//
//  Created by Thomas on 09.05.25.
//

import UIKit
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension für Inhalt der Sektionen und Zeilen

extension SettingViewController  {
    
    //----------------------------------------------------------------------------------------
    // MARK: - Definition der Sektionen
    
    enum SectionContent: String, BasicSection, CaseIterable {
        case auswahl, ViewSettings, PdfSettings, BlockQuoteSetting, print
        
        var title : String {
            switch self {
            case .ViewSettings:      "Anzeige"
            case .BlockQuoteSetting: "Block"
            case .PdfSettings:       "PDF"
            case .print:             "Drucken"
            case .auswahl:           "Auswahl"
            }
        }
        
        var appearence: UICollectionLayoutListConfiguration.Appearance {
            switch self {
            default: .insetGrouped
            }
        }
        
        var headerMode: UICollectionLayoutListConfiguration.HeaderMode {
            switch self {
            case .auswahl: .none
            case .print: .none
            default: .firstItemInSection
            }
        }
        
        var showsSeparators: Bool {
            switch self {
            default: false
            }
        }
        
        var trailingSwipeActionsConfigurationProvider: UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider? {
            switch self {
            default: nil
            }
        }
    }
  
    //----------------------------------------------------------------------------------------
    // MARK: - Definition der möglichen Inhalte des Dialogs
    
    /// Alle Attribute von BasicDetail sind in der Extension des Protokolls mit Defaultwerten vorbelegt. Demzufolge können alle
    /// standardmäßig genutzten, nicht benötigten Attribute aus dem ENUM gelöscht werden.
    ///
    enum DetailContent: String, BasicDetail, Hashable, CaseIterable {
   
        /// Die Strings sollen den Namen der Properties entsprechen
        case textDefaults
        
        var title: TextSourceConvertible? {
            switch self {
            case .textDefaults:
              """
              Die **Standardeinstellungen** wiederherstellen. Alle Einstellungen werden überschrieben.
              """.markdown()
            }
        }
        
        var placeholder: String? {
            switch self {
            default: nil
            }
        }
        
        var textstyle: UIFont.TextStyle? { .callout }

        var parameter: [KeyText]? {
            switch self {
            default: nil
          }
        }
        
        ///-----------------------------------------------------------------------------------
        /// Zugewiesene Konfiguration entsprechend des Datentyps
        ///
        var contentViewType: ContentViewType
        {
            switch self {
            default: .number
            }
        }
        
        var configurationWidth   : CGFloat?                {  nil  }
        var configurationHeight  : CGFloat?                {  nil  }
        var configurationMargins : NSDirectionalEdgeInsets { .zero }
        
        ///-----------------------------------------------------------------------------------
        /// Zusätzliche Daten für BasicType
        ///
        var presentation: ContentPresentation? { nil }      /// Defaultmäßig wird TITLE verwendet
        var widthUsage  : WidthUsage?          { nil }      /// Defaultmäßig wirkt die Breite auf LABEL

      }
}

