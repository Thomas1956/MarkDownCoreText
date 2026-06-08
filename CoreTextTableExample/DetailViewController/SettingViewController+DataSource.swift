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
    /// Alle definierten Sektionen erzeugen
    ///
    func applySnapshot(forEditing: Bool) {
        guard let settings = self.entity else { return }
        
        /// Die Section Snapshots löschen, damit sie aktualisiert werden.
        var snapshot = Snapshot()
        snapshot.deleteSections(SectionContent.allCases.map {$0.title} )
        dataSource.apply(snapshot)
        
        if Self.activeSection[.ViewSetting] ?? false {
            sectionViewSetting(settings, forEditing: forEditing)
        }
        if Self.activeSection[.CodeBlockSetting] ?? false {
            sectionCodeBlockSetting(settings, forEditing: forEditing)
        }
        if Self.activeSection[.PdfSetting] ?? false {
            sectionPdfSetting(settings, forEditing: forEditing)
        }
        if Self.activeSection[.BlockQuoteSetting] ?? false {
            sectionBlockQuoteSetting(settings, forEditing: forEditing)
        }
        if Self.activeSection[.RulerSetting] ?? false {
            sectionRulerSetting(settings, forEditing: forEditing)
        }
        if Self.activeSection[.TableSetting] ?? false {
            sectionTableSetting(settings, forEditing: forEditing)
        }
        if Self.activeSection[.DefaultSetting] ?? false {
            sectionDefaultSetting()
        }
        if Self.activeSection[.HelpSetting] ?? false {
            sectionHelpSetting(settings, forEditing: forEditing)
        }
    }
}


