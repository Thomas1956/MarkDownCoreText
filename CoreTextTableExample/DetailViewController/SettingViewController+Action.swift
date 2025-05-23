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
        guard let setting = self.entity else { return }
        
        let predicate = NSPredicate.all
        let settings = Settings.fetch(predicate, context: viewContext)

        /* Beispiel für das Drucken
 
        /// Produkte, die dem Lager zugeordnet sind und noch nicht verkauft wurden
        let predicate = NSPredicate(format: "%K = %@ AND %K = nil", #keyPath(Produkt.lager), lager, #keyPath(Produkt.verkauf) )
         */
        let subTitle = "Liste für das Drucken."

        ///-----------------------------------------------------------------------------------
        /// Druckaufbereitung - Für die Unterstützung des Druckens das Template 'Print Support' dem Projekt zufügen.
        ///
        /*
        let pageSupport = SettingsSupport(settings: settings, subTitle: subTitle)
        shareContent(view, pageSupport: pageSupport)
         */

    }
    
    ///---------------------------------------------------------------------------------------
    /// Action - Setzen der Defaultwerte
    ///
    @objc func actionSetDefaults() {
        guard let setting = self.entity else { return }
        
        let settingDefault = SettingsController.shared.default
        
        DetailContent.allCases.forEach { keyName in
            let key = keyName.key
            guard setting.entity.attributesByName[key] != nil else { return }

            let value = settingDefault.value(forKey: key)
            setting.pushProperty(value: value, key: key)
        
            print("Key: \(key) \t \(value ?? "nil") ")
        }
        
        navigationItem.rightBarButtonItem?.isEnabled = setting.isChanged

        var snapshot = self.dataSource.snapshot()
        snapshot.reloadItems(snapshot.itemIdentifiers)
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }
}
