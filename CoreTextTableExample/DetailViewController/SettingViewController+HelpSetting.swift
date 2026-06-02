//
//  SettingViewController+HelpSetting.swift
//  CoreTextTableExample
//
//  Created by Thomas on 02.06.26.
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
    enum HelpSetting: String, @MainActor BasicDetail, CaseIterable {
 
        /// Die Strings sollen den Namen der Properties entsprechen (Beispiel löschen und EIGENE Case's ergänzen)
        case info, wetter
        
        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .info: "Ein einfacher **Info-Text**.".markdown()
            default: nil
            }
        }
        
        /// Ersatztext und Platzhalter bei Texteingaben
        var placeholder: String? {
            switch self {            
            case .wetter: "Schönes Wetter"
            default: nil
            }
        }
                
        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            default: .editClear
            }
        }
        
        /// Auswahl des Content Views für die Konfiguration des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            default: .text
            }
        }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionHelpSetting(_ entity: Settings, forEditing: Bool) {
        typealias Content = HelpSetting
        let rwo : ContentRWType = forEditing ? .rw : .ro

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        items.append(.info(Content.info.title))
        items.append(.link(Content.wetter, type: rwo, image: "sun.max", presentation: .disclosureIndicator))

        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen        
        dataSource.makeSection(SectionContent.HelpSetting, items: items.itemType)
    }
}
