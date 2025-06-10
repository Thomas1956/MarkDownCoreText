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

final class ScopeView: UICollectionReusableView {

    private lazy var segmented: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Anzeige","PDF","Block","Drucken"])
//        sc.selectedSegmentIndex = ...
        sc.addTarget(self, action:#selector(change(_:)), for:.valueChanged)
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(segmented)
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            segmented.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func change(_ sender: UISegmentedControl) {
//        NotificationCenter.default.post(name: .scopeChanged,
//                                        object: sender.selectedSegmentIndex)
    }
}


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
    var linkDefaults: BasicType!
    
    let colorSelectContent = [
        (nil                    , "-"      , .black                 ),
        (UIColor.lightGray      , "Weiss"  , UIColor.lightGray      ),
        (UIColor.gray           , "Grau"   , UIColor.gray           ),
        (UIColor.yellow.lowlight, "Gelb"   , UIColor.yellow.lowlight),
        (UIColor.red            , "Rot"    , UIColor.red            ),
        (UIColor.blue           , "Blau"   , UIColor.blue           ),
        (UIColor.green.darklight, "Grün"   , UIColor.green.darklight),
        (UIColor.brown          , "Braun"  , UIColor.brown          ),
        (UIColor.black          , "Schwarz", UIColor.black          ),
    ].keyTextArray

    ///---------------------------------------------------------------------------------------

    static var activeSection: [SectionContent : Bool]!
    
    /// Sichtbarkeit der Sektionen initialisieren
    static func initSection() {
        var dir = SectionContent.allCases.reduce(into: [SectionContent: Bool]()) { result, property in
            result[property] = false
        }
//        dir[.links] = true
        activeSection = dir
    }
    
    ///---------------------------------------------------------------------------------------
    /// Den Zustand des SAVE-Button aktualisieren (Methode ist so wie hier in der Basisklasse definiert)
    ///
    override func saveButtonState() {
        guard isEditing, let setting = self.entity else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        
        /// Aktualisierung der Meldung veranlassen
        ItemType.reloadIfNeeded(on: self.dataSource, ViewSettings.message.key)
 
        
        let changed = setting.changedValues()
        changed.forEach( { print($0.key, $0.value) } )
        
        navigationItem.rightBarButtonItem?.isEnabled = setting.hasPersistentChangedValues
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
        self.cellConfiguration(cell: cell, itemIdentifier: item, onChange:     self.onEditChange,
                                                                 onUpdateData: self.onUpdateData)
    }
    
    ///---------------------------------------------------------------------------------------
    /// CLOSURE - Funktion für die Rückmeldung von Änderungen
    ///
    override func onEditChange(value: Any, key: String?) {
        guard let key, let setting = self.entity else { return }
        
        /// Änderung der Button für die Auswahl der Sektionen
        if let item = SectionContent.allCases.first(where: {$0.rawValue == key}) {
            Self.activeSection[item]?.toggle()
            applySnapshot(forEditing: isEditing)
            return
        }

        
        if key == ViewSettings.viewColor.key {
            let color = value as? UIColor ?? .label
            setting.pushProperty(value: color, key: key)
            ItemType.reloadIfNeeded(on: self.dataSource, ViewSettings.viewColorSelect.key)
            print("Color", setting.isChanged, key, value)
        }
        else if key == PdfSettings.pdfTextColor.key {
            let color = value as? UIColor ?? .label
            setting.pushProperty(value: color, key: key)
            ItemType.reloadIfNeeded(on: self.dataSource, PdfSettings.pdfColorSelect.key)
            print("Color", setting.isChanged, key, value)
        }
       else {
            /// Die Attribute werden als ihre ursprünglichen Datentypen gespeichert
            setting.pushProperty(value: value, key: key)
            print("Änderungen", setting.isChanged, key, value)
        }
        saveButtonState()
    }
    
    ///---------------------------------------------------------------------------------------
    /// CLOSURE - Funktion für die Aktualisierung von Attributen (Standardfunktion tut nichts)
    ///
    override func onUpdateData(value: Any, key: String?) -> AnyHashable? {

        if let item = SectionContent.allCases.first(where: {$0.rawValue == key}) {
            return Self.activeSection[item]
        }
        
        typealias C = ViewSettings
        typealias P = PdfSettings

        if key == C.viewColorSelect.key {
            /// Das Image aus der Entity heraus ermitteln und in einen Image-Namen umwandeln.
            if let color = entity?.property(forKey: C.viewColor.key) as? UIColor
            {
                /// Die Liste aller auswählbaren Images holen und den aktuellen Eintrag suchen.
                guard var select = colorSelectContent.first(where: {$0.value as? UIColor == color} )
                else { return nil }
                
                select.value = nil
                return select
            }
        }
        
        if key == P.pdfColorSelect.key {
            /// Das Image aus der Entity heraus ermitteln und in einen Image-Namen umwandeln.
            if let color = entity?.property(forKey: P.pdfTextColor.key) as? UIColor
            {
                /// Die Liste aller auswählbaren Images holen und den aktuellen Eintrag suchen.
                guard var select = colorSelectContent.first(where: {$0.value as? UIColor == color} )
                else { return nil }
                
                select.value = nil
                return select
            }
        }

        if key == C.message.key, let settings = entity {
            
            /// Meldung, die überprüft, ob die eingegebenen Daten gültig sind
            var text = """
              Für die Einzüge sind nur Werte größer gleich Null zulässing. Der rechte Rand wird
              intern in einen negativen Wert umgerechnet. Die Zeilenhöhe darf nicht kleiner als 1 sein.
              """
            var isOk = true
            
            if  let headIndent = settings.property(forKey: C.viewHeadIndent.key) as? CGFloat,
                let tailIndent = settings.property(forKey: C.viewTailIndent.key) as? CGFloat,
                let lineHeight = settings.property(forKey: C.viewLineHeight.key) as? CGFloat
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
            
            var ktxt = KeyText(value: nil, text: text.markdown(size: 15, textcolor: (isOk ? .label : .systemRed) ) )
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
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        /// Beispiel für Aufruf des Druckens
        if item == linkPrint   .itemType { actionShare(linkPrint) }
        if item == linkDefaults.itemType { actionSetDefaults()    }
    }
    
    /// Abfrage, ob eine Zelle ausgewählt werden kann
    /// Diese Funktion MUSS auch implementiert werden, wenn keine Auswahl erfolgt. Defaultmäßig ist der Rückgabewert TRUE !
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return false }

        /// Beispiel für Aufruf des Druckens
        if item == linkPrint   .itemType  { return true }
        if item == linkDefaults.itemType  { return true }

        collectionView.deselectItem(at: indexPath, animated: false)
        return false
    }
}
