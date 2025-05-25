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
    /// A U S W A H L  zur Aktivierung der Sektionen
    ///
    func sectionAuswahl() {
        var itemsActivate = [ItemType]()
        let itemsSection = SectionContent.allCases.filter( {$0 != .auswahl} )
        
        var index = 0
        while index < itemsSection.count {
            let title = itemsSection[index].title.attrString(fontsize: 15, textcolor: .defaultLineTitleColor, alignment: .right)
            let contentLeft  = ContentData(viewType: .button, .rw, nil, itemsSection[index].rawValue,
                                           title: title, parameter: .alignmentTrailing)
            let layoutLeft = ContentDataLayout(contentLeft, presentation: .line, width: 30, widthUsage: .content)
            index += 1

            var contentRight = ContentData(viewType: .label)
            if index < itemsSection.count {
                let title = itemsSection[index].title
                contentRight = ContentData(viewType: .button, .rw, nil, itemsSection[index].rawValue,
                                           title: title, parameter: .alignmentLeading)
            }
            let layoutRight = ContentDataLayout(contentRight, presentation: .line, width: 30, widthUsage: .content)
            index += 1

            itemsActivate.append(BasicType.basic([layoutLeft, layoutRight]).itemType)
        }
        
        var sectionSnapshot = SectionSnapshot()
        sectionSnapshot.append(SectionContent.auswahl, items: itemsActivate)
        dataSource.apply(sectionSnapshot, to: SectionContent.auswahl.title, animatingDifferences: true)
    }

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
        guard let settings = self.entity else { return }
        
        /// Die Section Snapshots löschen, damit sie aktualisiert werden.
        var snapshot = Snapshot()
        snapshot.deleteSections(SectionContent.allCases.map {$0.title} )
        dataSource.apply(snapshot)

        sectionAuswahl()
        
        if Self.activeSection[.BlockQuoteSetting] ?? false {
            sectionBlockQuoteSetting(settings, forEditing: forEditing)
        }
        if Self.activeSection[.ViewSettings] ?? false {
            sectionViewSettings     (settings, forEditing: forEditing)
        }
        if Self.activeSection[.PdfSettings] ?? false {
            sectionPdfSettings      (settings, forEditing: forEditing)
        }
        if Self.activeSection[.print] ?? false {            
            sectionPrint()
        }
    }
}


