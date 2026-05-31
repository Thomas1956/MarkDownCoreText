//
//  SettingViewController+Action.swift
//  CoreTextTableExample
//
//  Created by Thomas on 09.05.25.
//

import UIKit
import CoreData
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension für Aktionen

extension SettingViewController  {
    
    ///---------------------------------------------------------------------------------------
    /// Action - Teilen und Drucken
    ///
    @objc func actionShare(_ sender: Any?) {
    }
    
    ///---------------------------------------------------------------------------------------
    /// Action - Setzen der Defaultwerte
    ///
    @objc func actionSetDefaults() {
        guard let setting = self.entity else { return }
        
        /// Defaultwerte zurückspeichern
        SettingsController.shared.restoreDefaults(to: setting)
        
        saveButtonState()
        
        /// Rückmeldung über Änderungen für Live Preview
        onLiveChange?(setting)

        var snapshot = self.dataSource.snapshot()
        snapshot.reloadItems(snapshot.itemIdentifiers)
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
}
