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
        
        /// Aktualisierung der Meldung veranlassen
        BasicType.source(key: "CODE1").reloadIfNeeded(on: self.dataSource)
        BasicType.stdItem(ContentData(nil, nil, DetailContent.message.key)).reloadIfNeeded(on: self.dataSource)

        navigationItem.rightBarButtonItem?.isEnabled = setting.isChanged
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Initialisierung
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        /// Kann nicht in der Basisklasse definiert werden
        collectionView.delegate = self
    }
    
    ///---------------------------------------------------------------------------------------
    /// Konfiguration von Zellen, die nicht vom BasicType abgedeckt sind (z.B. Summen, Statistik, Liste von Objekten)
    /// Der Aufruf der Funktion erfolgt NICHT im Registration Handler sondern in 'dequeueConfiguredReusableCell'
    ///
    override func cellConfiguration(cell: CommonCollectionViewCell, itemIdentifier: ItemType,
                                    indexPath: IndexPath)
    {
        guard let item = itemIdentifier.item else { return }
        
        ///---------------------------------------------------------------------------------------
        /// Die Aktualisierung des Source Code Teiles erkennen
        ///
        if BasicType.isSource(item, key: "CODE1"), let settings = entity
        {
            /// Meldung, die überprüft, ob die eingegebenen Daten gültig sind
            var text = """
          Für die Einzüge sind nur Werte größer gleich Null zulässing. Der rechte Rand wird
          intern in einen negativen Wert umgerechnet. Die Zeilenhöhe darf nicht kleiner als 1 sein.
          """
            var isOk = true
            
            if  let headIndent = settings.property(forKey: "headIndent") as? CGFloat,
                let tailIndent = settings.property(forKey: "tailIndent") as? CGFloat,
                let lineHeight = settings.property(forKey: "lineHeightMultiple") as? CGFloat
            {
                if headIndent > 100.0 {
                    text = "Der linke Einzug darf **nicht größer** als 100 sein."
                    isOk = false
                }
                if tailIndent > 100.0 {
                    text = "Der rechte Einzug darf **nicht größer** als 100 sein."
                    isOk = false
                }
                if lineHeight < 1.0 {
                    text = "Die Zeilenhöhe darf **nicht kleiner** als 1,0 sein."
                    isOk = false
                }
            }
            /// Content View für die Anzeige konfigurieren
            var configuration = cell.defaultContentConfiguration()
            configuration.attributedText = text.markdown(size: 15, textcolor: (isOk ? .label : .systemRed) )
            if !isOk {
                configuration.textProperties.color = .systemRed
                configuration.image = UIImage(systemName: "exclamationmark.triangle.fill")
                configuration.imageProperties.tintColor = .systemRed
            }
            /// Erweiterung des UIListViewContent für FESTE Höhen
            let fixed = FixedHeightListContentView.defaultConfiguration(configuration, height: 80)
            cell.contentConfiguration = fixed
            return
        }
        
        self.cellConfiguration(cell: cell, itemIdentifier: item, onChange:     self.onEditChange,
                                                                 onUpdateData: self.onUpdateData)
    }
    
    ///---------------------------------------------------------------------------------------
    /// CLOSURE - Funktion für die Rückmeldung von Änderungen
    ///
    override func onEditChange(value: Any, key: String?) {
        guard let key, let setting = self.entity else { return }
        
        let vv = value as? CGFloat ?? 0.0
        /// Die Attribute werden als ihre ursprünglichen Datentypen gespeichert
        setting.pushProperty(value: vv, key: key)
        print("Änderungen", setting.isChanged, key, value)
        
        saveButtonState()
    }
    
    ///---------------------------------------------------------------------------------------
    /// CLOSURE - Funktion für die Aktualisierung von Attributen (Standardfunktion tut nichts)
    ///
    override func onUpdateData(value: Any, key: String?) -> AnyHashable? {
        if key == DetailContent.message.key, let settings = entity {
            
            /// Meldung, die überprüft, ob die eingegebenen Daten gültig sind
            var text = """
              Für die Einzüge sind nur Werte größer gleich Null zulässing. Der rechte Rand wird
              intern in einen negativen Wert umgerechnet. Die Zeilenhöhe darf nicht kleiner als 1 sein.
              """
            var isOk = true
            
            if  let headIndent = settings.property(forKey: "headIndent") as? CGFloat,
                let tailIndent = settings.property(forKey: "tailIndent") as? CGFloat,
                let lineHeight = settings.property(forKey: "lineHeightMultiple") as? CGFloat
            {
                if headIndent > 100.0 {
                    text = "Der linke Einzug darf **nicht größer** als 100 sein."
                    isOk = false
                }
                if tailIndent > 100.0 {
                    text = "Der rechte Einzug darf **nicht größer** als 100 sein."
                    isOk = false
                }
                if lineHeight < 1.0 {
                    text = "Die Zeilenhöhe darf **nicht kleiner** als 1,0 sein."
                    isOk = false
                }
            }
            
            var ktxt = KeyText(value: nil, attrText: text.markdown(size: 15, textcolor: (isOk ? .label : .systemRed) ) )
            if !isOk {
                ktxt.color = .systemRed
                ktxt.imageName = "exclamationmark.triangle.fill"
            }
            return ktxt
        }
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
