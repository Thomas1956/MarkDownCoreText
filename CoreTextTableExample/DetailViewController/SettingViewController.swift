//
//  SettingViewController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 09.05.25.
//

import UIKit
import CoreData
import UsefulExtensions
import CommonCollection


//--------------------------------------------------------------------------------------------
// MARK: - SettingViewController

class SettingViewController: CommonDetailViewController<Settings, ItemType> {
    
    /// Titel des Detail View Controllers und den ENUM für die Konfiguration der Sektionen.
    override var titleController : String { "Details" }
    override var sectionConfiguration : SectionDirectory { SectionContent.configuration }
    
    /// Für den Fall, dass eine Liste von Objekten im VC ist, muss hier der Name der Sektion eingetragen werden.
    override var sectionWithList : String { "" }

    /// Liste der Links, die für Aktionen benötigt werden.
    var linkPrint: BasicType!
    
    ///---------------------------------------------------------------------------------------
    /// Den Zustand des SAVE-Button aktualisieren (Methode ist so wie hier in der Basisklasse definiert)
    ///
    override func saveButtonState() {
        guard isEditing, let setting = self.entity else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        
/* Beispiel für eine Property, die nicht leer sein darf
 
        /// Der Ort darf nicht leer sein
        let ort = lager.property(forKey: "ort") as? String
        navigationItem.rightBarButtonItem?.isEnabled = lager.isChanged && !ort.isEmptyOrNil
*/
        navigationItem.rightBarButtonItem?.isEnabled = setting.isChanged
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Initialisierung
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Kann nicht in der Basisklasse definiert werden
        collectionView.delegate = self
    }
    
    ///---------------------------------------------------------------------------------------
    /// Konfiguration von Zellen, die nicht vom BasicType abgedeckt sind (z.B. Summen, Statistik, Liste von Objekten)
    /// Der Aufruf der Funktion erfolgt NICHT im Registration Handler sondern in 'dequeueConfiguredReusableCell'
    ///
    override func cellConfiguration(cell: CommonCollectionViewCell, itemIdentifier: ItemType, indexPath: IndexPath) {
        guard let itemIdentifier = itemIdentifier.item else {
            return
        }

        self.cellConfiguration(cell: cell, itemIdentifier: itemIdentifier, onChange: self.onEditChange, onUpdateData: self.onUpdateData)

/* Beispiel für eine Liste von Produkten
 
        /// Zellen für die Anzeige der Produkte, die dem Stueck zugeordnet sind
        if let objectID = itemIdentifier as? NSManagedObjectID, let context = self.objectContext,
           let produkt = context.object(with: objectID) as? Produkt {
            
            var configuration = StueckDetailViewContent.Configuration()
            configuration.produkt     = produkt
            configuration.isEditing   = self.isEditing
            cell.contentConfiguration = configuration
        }
*/
    }

    ///---------------------------------------------------------------------------------------
    /// CLOSURE - Funktion für die Rückmeldung von Änderungen
    ///
    override func onEditChange(value: Any, key: String?) {
        guard let key, let setting = self.entity else { return }
        
        /// Änderungen im Directory merken (Die Beispiele zeigen das Konverieren in verschiedene Datentypen)
        if key == "birthday" {
            /// 'birthday' ist als Optional(String) definiert
            let text = (value as? DateComponents)?.strDatum
            setting.pushProperty(value: text as Any, key: key)
            print("Änderungen (birthday)", setting.isChanged, key, text as Any)
        }
        else if key == "datum" {
            /// 'datum' ist als Optional(Date) definiert
            let date = (value as? DateComponents)?.date
            setting.pushProperty(value: date as Any, key: key)
            print("Änderungen (datum)", setting.isChanged, key, date as Any)
        }
        else {
            /// alle anderen Attribute werden in ihren normalen Datentypen gespeichert
            setting.pushProperty(value: value, key: key)
            print("Änderungen", setting.isChanged, key, value)
             }

        saveButtonState()
    }
    
    ///---------------------------------------------------------------------------------------
    /// CLOSURE - Funktion für die Aktualisierung von Attributen (Standardfunktion tut nichts)
    ///
    override func onUpdateData(value: Any, key: String?) -> AnyHashable? {
        return nil
    }

    ///---------------------------------------------------------------------------------------
    /// Änderungen der Daten verarbeiten
    ///
    override func makeSnapshot(forEditing: Bool) {
        /// Methode, die typischerweise in der Extension DataSource definiert ist.
        return applySnapshot(forEditing: forEditing)
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - UICollectionViewDelegate

extension SettingViewController: UICollectionViewDelegate {
    
    /// Ausführen einer Aktion bei Auswahl einer Zelle
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        /// Beispiel für Aufruf des Druckens
        if indexPath == dataSource.indexPath(for: linkPrint.itemType) {
            actionShare(linkPrint)
        }
    }
    
    /// Abfrage, ob eine Zelle ausgewählt werden kann
    /// Diese Funktion MUSS auch implementiert werden, wenn keine Auswahl erfolgt. Defaultmäßig ist der Rückgabewert TRUE !
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        
        /// Beispiel für Aufruf des Druckens
        if indexPath == dataSource.indexPath(for: linkPrint.itemType) {
            return true
        }
        
        collectionView.deselectItem(at: indexPath, animated: false)
        return false
    }
}
