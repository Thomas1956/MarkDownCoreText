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
    /// Inhalt der Section für Settings zusammenstellen
    ///
    func sectionSettings(_ setting: Settings, forEditing: Bool) {
        typealias Content = DetailContent

        ///-----------------------------------------------------------------------------------
        /// items anlegen
        var items = [BasicType]()
        
        items.append(.basic([Content.headIndent        .data(setting),
                             Content.tailIndent        .data(setting),
                             Content.lineHeightMultiple.data(setting),
                            ]))
        
        items.append(.basic(.lineSpace(height: 8, color: .secondarySystemBackground)))
        
        /// Item für die Anzeige variabler Meldungen
        items.append(.source(key: "CODE1"))
        
        ///-----------------------------------------------------------------------------------
        /// Snapshot erzeugen und der DataSource zuweisen
        ///
        var sectionSnapshot = SectionSnapshot()
        sectionSnapshot.append(SectionContent.setting, items: items.itemType)
        dataSource.apply(sectionSnapshot, to: SectionContent.setting.title, animatingDifferences: true)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Inhalt der Section für das Drucken zusammenstellen
    ///
    func sectionMessage() {

        var sectionSnapshot = SectionSnapshot()
        sectionSnapshot.append(SectionContent.message, items: [SectionContent.message.title.itemType])
        dataSource.apply(sectionSnapshot, to: SectionContent.message.title, animatingDifferences: true)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Inhalt der Section für das Drucken zusammenstellen
    ///
    func sectionPrint() {
        typealias Content = DetailContent

        /// items anlegen
        var items = [BasicType]()
        items.append(.stdItem(Content.infotext.title))
        /// Nur über das Setzen des Textes über ContentData wird der Stil für einen Link gesetzt.
        self.linkPrint = BasicType.stdItem(ContentData(text: "Drucken oder Teilen"), image: "square.and.arrow.up")
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

        sectionSettings(setting, forEditing: forEditing)
        sectionPrint()
    }
}


