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
        case textImageFolder
        
        var title: TextSourceConvertible? {
            switch self {
            case .textDefaults:
              """
              Die **Standardeinstellungen** wiederherstellen. Alle Einstellungen werden überschrieben.
              """.markdown()
            case .textImageFolder:
              """
              **Bilder-Ordner** für eingebettete Bilder. Bilder werden zuerst neben der Markdown-Datei \
              gesucht, dann in diesem Ordner.
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

        ///-----------------------------------------------------------------------------------
        /// Bilder-Ordner auswählen / zurücksetzen
        items.append(.info(Content.textImageFolder.title))

        let folderPath = MarkdownImageLocation.shared.folderURL?.path ?? "Kein Ordner ausgewählt"
        items.append(.info(folderPath.markdown(size: 13, textcolor: .textGray)))

        let linkImageFolder = BasicType.stdItem("Bilder-Ordner auswählen", image: "folder.badge.plus")
        items.append(linkImageFolder)
        self.linkImageFolder = linkImageFolder

        if MarkdownImageLocation.shared.folderURL != nil {
            let linkImageFolderClear = BasicType.stdItem("Bilder-Ordner entfernen", image: "folder.badge.minus")
            items.append(linkImageFolderClear)
            self.linkImageFolderClear = linkImageFolderClear
        } else {
            self.linkImageFolderClear = nil
        }

        dataSource.makeSection(SectionContent.DefaultSetting, items: items.itemType)
    }
}

