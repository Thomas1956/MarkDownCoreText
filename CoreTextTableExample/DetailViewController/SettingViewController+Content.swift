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
    
    enum SectionContent: Int, BasicSection, CaseIterable {
        case setting, message, print
        
        var title : String {
            switch self {
            case .setting: "Zeilenparameter"
            case .message: "Meldung"
            case .print:   "Drucken oder Teilen"
            }
        }
        
        var appearence: UICollectionLayoutListConfiguration.Appearance {
            switch self {
            default: .insetGrouped
            }
        }
        
        var headerMode: UICollectionLayoutListConfiguration.HeaderMode {
            switch self {
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
        var key: String { return self.rawValue }

        /// Die Strings sollen den Namen der Properties entsprechen
        case headIndent, tailIndent, lineHeightMultiple, infotext
        
        var title: AnyHashable? {
            switch self {
            case .headIndent:         "Linker Einzug"
            case .tailIndent:         "Rechter Einzug"
            case .lineHeightMultiple: "Zeilenhöhe"
            case .infotext:
              """
              Die Parameter können gedruckt oder geteilt werden.
              """.markdown()
            }
        }
        
        var placeholder: String? {
            switch self {
            default: nil
            }
        }
        
        var textstyle: UIFont.TextStyle? { .callout }

        var parameter: ContentEditType? {
            switch self {
            case .headIndent:           .einsNachkomma
            case .tailIndent:           .einsNachkomma
            case .lineHeightMultiple:   .einsNachkomma
            default: nil
          }
        }
        
        ///-----------------------------------------------------------------------------------
        /// Zugewiesene Konfiguration entsprechend des Datentyps
        ///
        var contentViewType: ContentViewType
        {
            switch self {
            case .headIndent:           .number
            case .tailIndent:           .number
            case .lineHeightMultiple:   .number
            default: .text
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

