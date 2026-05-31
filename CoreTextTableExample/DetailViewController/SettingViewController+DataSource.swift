//
//  SettingViewController+DataSource.swift
//  CoreTextTableExample
//
//  Created by Thomas on 09.05.25.
//

import UIKit
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension für den Inhalt des Dialogs in einem Snapshot

extension SettingViewController  {
        
    ///---------------------------------------------------------------------------------------
    /// Inhalt der Section für das Drucken zusammenstellen
    ///
    func sectionPrint() {
        typealias Content = DetailContent

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

        dataSource.makeSection(SectionContent.print, items: items.itemType)
    }
 
    ///---------------------------------------------------------------------------------------
    /// Alle definierten Sektionen erzeugen
    ///
    func applySnapshot(forEditing: Bool) {
        guard let settings = self.entity else { return }
        
        /// Die Section Snapshots löschen, damit sie aktualisiert werden.
        var snapshot = Snapshot()
        snapshot.deleteSections(SectionContent.allCases.map {$0.title} )
        dataSource.apply(snapshot)
        
        if Self.activeSection[.ViewSettings] ?? false {
            sectionViewSettings     (settings, forEditing: forEditing)
        }
        if Self.activeSection[.PdfSettings] ?? false {
            sectionPdfSettings      (settings, forEditing: forEditing)
        }
        if Self.activeSection[.BlockQuoteSetting] ?? false {
            sectionBlockQuoteSetting(settings, forEditing: forEditing)
        }
        if Self.activeSection[.print] ?? false {
            sectionPrint()
        }
    }
}


