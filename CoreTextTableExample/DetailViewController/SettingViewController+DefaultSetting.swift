//
//  SettingViewController+DefaultSetting.swift
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
    // MARK: - Definition der möglichen Inhalte des Dialogs
    
    /// Alle Attribute von BasicDetail sind in der Extension des Protokolls mit Defaultwerten vorbelegt. Demzufolge können alle
    /// standardmäßig genutzten, nicht benötigten Attribute aus dem ENUM gelöscht werden.
    ///
    enum DefaultSetting: String, @MainActor BasicDetail, Hashable, CaseIterable {
   
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
    }
    
    
    ///---------------------------------------------------------------------------------------
    /// Inhalt der Section für das Drucken zusammenstellen
    ///
    func sectionDefaultSetting() {
        typealias Content = DefaultSetting

        /// items anlegen
        var items = [BasicType]()

        items.append(.info(Content.textDefaults.title))
        /// Defaultwerte wiederherstellen.
        let linkDefaults = BasicType.stdItem("Defaultwerte einstellen" , image: "arrow.trianglehead.2.clockwise")
        items.append(linkDefaults)
        self.linkDefaults = linkDefaults
        
        /// Drucken oder Teilen
        let linkPrint = BasicType.stdItem("Drucken oder Teilen", image: "square.and.arrow.up")
        items.append(linkPrint)
        self.linkPrint = linkPrint

        dataSource.makeSection(SectionContent.DefaultSetting, items: items.itemType)
    }
}

