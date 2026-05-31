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
        case ViewSetting, PdfSetting, BlockQuoteSetting, RulerSetting, print
        
        var title : String {
            switch self {
            case .ViewSetting:       "Anzeige"
            case .PdfSetting:        "PDF"
            case .BlockQuoteSetting: "Block"
            case .RulerSetting:      "Ruler"
            case .print:             "Drucken"
            }
        }
        
        var appearance: UICollectionLayoutListConfiguration.Appearance {
            switch self {
            default: .insetGrouped
            }
        }
        
        var headerMode: UICollectionLayoutListConfiguration.HeaderMode {
            switch self {
            default: .none
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
    enum DetailContent: String, @MainActor BasicDetail, Hashable, CaseIterable {
   
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
        
      }
}

