//
//  SettingViewController+Action.swift
//  CoreTextTableExample
//
//  Created by Thomas on 09.05.25.
//

import UIKit
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
}
