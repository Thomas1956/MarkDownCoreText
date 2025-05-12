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
        let rwo : ContentRWType = forEditing ? .rw : .ro
        let rwf : ContentRWType = forEditing ? (isAddingEntity ? .rwf : .rw) : .ro

        ///-----------------------------------------------------------------------------------
        /// items anlegen
        var items = [BasicType]()
        
        /// Kommentarfeld anlegen. Dem Kommentar ist KEIN Attribut aus Core Data zugeordnet.
        items.append(.basic(Content.kommentar.data(nil, rwo)))

        /*
        items.append(.basic([Content.familyName.data(person, rwf),
                                   Content.givenName .data(person, rwo)] ))
        
        items.append(.basic([Content.datum.data(person, rwo, presentation: .line)]))
         */
        
        /// Zusammenstellen der Einträge für die Anzeige im Dialog (Editierbar / Readonly, Inhalt vorhanden / leer)
        /*
        
        if forEditing || !(person.postalCode).isEmptyOrNil || !(person.city).isEmptyOrNil {
            items.append(.basic([Content.postalCode.data(person, rwo),
                                 Content.city      .data(person, rwo)]))
        }
        if forEditing || !(person.street).isEmptyOrNil {
            items.append(.basic([Content.street.data(person, rwo)]))
        }
        if forEditing || !(person.address).isEmptyOrNil {
            items.append(BasicType.basic([Content.address.data(person, .ro)]))
        }
         */
        
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
    func sectionPrint() {
        typealias Content = DetailContent

        /// items anlegen
        var items = [BasicType]()
        items.append(.infoText(Content.infotext.title))
        
        self.linkPrint = .linkPrint("Drucken oder Teilen")
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


