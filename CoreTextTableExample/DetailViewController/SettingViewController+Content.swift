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
        case setting, print
        
        var title : String {
            switch self {
            case .setting: "Settings"
            case .print: "Drucken oder Teilen"
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
        case kommentar, infotext
        
        var title: AnyHashable? {
            switch self {
            case .kommentar : "Kommentar"
            case .infotext  : """
                              Der Name des Lagerortes darf nicht leer sein. \
                              Die Kombination aus **einem** oder **zwei** Buchstaben und einer Zahl sind \
                              optimal (z.B. ^[G2](style: 'dark') für große Box Nummer 2). \
                              Ein Lager kann nur gelöscht werden, wenn mit ihm noch keine Produkte verknüpft sind.
                              """.markdown()
            }
        }
        
        var placeholder: String? {
            switch self {
            case .kommentar : "Kommentar eingeben"
            default: nil
            }
        }
        
        var textstyle: UIFont.TextStyle? { .callout }

        var parameter: ContentEditType? {
            switch self {
            default: return .editClear
            }
        }
        
        ///-----------------------------------------------------------------------------------
        /// Zugewiesene Konfiguration entsprechend des Datentyps
        ///
        var contentViewType      : ContentViewType         { .text }
        var configurationWidth   : CGFloat?                {  nil  }
        var configurationHeight  : CGFloat?                {  nil  }
        var configurationMargins : NSDirectionalEdgeInsets { .zero }
        
        ///-----------------------------------------------------------------------------------
        /// Zusätzliche Daten für BasicType
        ///
        var presentation: ContentPresentation? { nil }      /// Defaultmäßig wird TITLE verwendet
        var widthUsage  : WidthUsage?          { nil }      /// Defaultmäßig wirkt die Breite auf LABEL

        
        ///-----------------------------------------------------------------------------------
        /// Drucken (vordefniert, falls es benötigt wird)
        ///
        var attributes : [NSAttributedString.Key: Any] {
            String.attributes(fontsize: 10, textcolor: .black)
        }
        
        /// Fontgröße des Inhaltes (Druck)
        var fontsize: CGFloat? { 10 }
        
        /// Vertikaler Abstand nach dem Eintrag (Druck)
        var verticalDistance: CGFloat {
            switch self {
            case .kommentar: 1.2
            default:         0.8
            }
        }
        
        /// Titel für den Druck erzeugen
        var printTitle : String {
            self.title is String ? self.title as! String : "-"
        }
        
        /// Datensatz für den Druck erzeugen
        func printData(_ setting: Settings) -> String
        {
            switch self {
                /// Standard-Attribute
            default:
                let content = setting.value(forKey: self.rawValue)
                if let text = content as? String { return text }
                return "-"
            }
        }
    }
}

