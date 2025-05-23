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

        items.append(.stdInfo(Content.textDefaults.title))
        /// Defaultwerte wiederherstellen.
        self.linkDefaults = BasicType.stdItem("Defaultwerte einstellen" , image: "arrow.trianglehead.2.clockwise")
        items.append(linkDefaults)
        
        /// Drucken oder Teilen
        self.linkPrint = BasicType.stdItem("Drucken oder Teilen", image: "square.and.arrow.up")
        items.append(linkPrint)

        var sectionSnapshot = SectionSnapshot()
        sectionSnapshot.append(SectionContent.print, items: items.itemType)
        dataSource.apply(sectionSnapshot, to: SectionContent.print.title, animatingDifferences: true)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Alle definierten Sektionen erzeugen
    ///
    func applySnapshot(forEditing: Bool) {
        guard let setting = self.entity else { return }
        
        /// Die Section Snapshots löschen, damit sie aktualisiert werden.
        var snapshot = Snapshot()
        snapshot.deleteSections(SectionContent.allCases.map {$0.title} )
        dataSource.apply(snapshot)

        sectionViewSettings(setting, forEditing: forEditing)
        sectionPdfSettings (setting, forEditing: forEditing)
        sectionPrint()
    }
}


