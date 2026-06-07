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
    
    ///---------------------------------------------------------------------------------------
    /// Rückmeldung mit Anzeige als Live View
    public convenience init(object        : Settings,
                            title         : String,
                            firstResponse : Bool = true,
                            onLiveChange  : ((Settings)->Void)?,
                            onFinish      : ((Bool)->Void)?)
    {
        self.init(object: object, title: title, onChange: onFinish)
        self.onLiveChange = onLiveChange
    }
    
    public var onLiveChange: ((Settings) -> Void)?
    
    ///---------------------------------------------------------------------------------------
    /// Titel des Detail View Controllers und den ENUM für die Konfiguration der Sektionen.
    override var sectionConfiguration : SectionDirectory { SectionContent.configuration }
    
    /// Für den Fall, dass eine Liste von Objekten im VC ist, muss hier der Name der Sektion eingetragen werden.
    override var sectionWithList : String { "" }

    /// Liste der Links, die für Aktionen benötigt werden.
    var linkPrint: BasicType?
    var linkDefaults: BasicType?

    ///---------------------------------------------------------------------------------------

    static var activeSection: [SectionContent : Bool]!
    
    /// Sichtbarkeit der Sektionen initialisieren
    static func initSection() {
        var dir = SectionContent.allCases.reduce(into: [SectionContent: Bool]()) { result, property in
            result[property] = false
        }
        dir[.ViewSetting] = true
        activeSection = dir
    }
    
    static func selectSection(_ section: SectionContent) {
        if activeSection == nil { initSection() }
        for key in SectionContent.allCases { activeSection[key] = false }
        activeSection[section] = true
    }
    
    static var activeSectionIndex: Int {
        let key = activeSection.first(where: {$0.value == true})?.key
        return SectionContent.allCases.firstIndex(of: key ?? .ViewSetting) ?? 0
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
        dataSource.reloadIfNeeded([ViewSetting.message.key])
 
        let changed = setting.changedValues()
        changed.forEach( { print($0.key, $0.value) } )
        
        navigationItem.rightBarButtonItem?.isEnabled = setting.hasPersistentChangedValues
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Variablen für die Header
    
    public var scopeIndex = 0

    ///---------------------------------------------------------------------------------------
    /// Capsule Header View (representable)
    ///
    public var capsuleRepresentedHeader: AnySectionHeader {
        .representable(
            CapsuleHeaderView.self,
            identifier: .sectionHeaderTop,
            elementKind : SupplementaryKind.topPinned,
            input     : .init(
                [.text  ("Anzeige",                      toolTip: "Anzeige der Elemente"),
                 .text  ("PDF",                          toolTip: "PDF-Parameter einstellen"),
                 .text  ("Block",                        toolTip: "Blockparameter einstellen"),
                 .text  ("Code",                         toolTip: "CodeBlock-Parameter einstellen"),
                 .text  ("Ruler",                        toolTip: "Trennstrich einstellen"),
                 .symbol("printer",             "Druck", toolTip: "Drucken"),
                 .symbol("questionmark.circle", "Hilfe", toolTip: "Hilfe")
                ],
                at: { [weak self] in self?.scopeIndex ?? 0 } ),
            onChange  : { index in
                self.scopeIndex = index
                print("Scope:", index)
                
                /// alle Sektionen ermitteln
                let sections = SectionContent.allCases
                guard sections.indices.contains(index) else { return }

                /// Neu ausgewählte Sektion setzen
                let key = sections[index]
                Self.selectSection(key)
                self.applySnapshot(forEditing: self.isEditing)
            }
        )
    }

    //----------------------------------------------------------------------------------------
    // MARK: - Initialisierung
    
    override func viewDidLoad() {
        titleController = "Details"
        
        /// Den Scopeindex und den CapsuleHeaderView initialisieren.
        self.scopeIndex = Self.activeSectionIndex
        self.topPinnedHeader = capsuleRepresentedHeader

        super.viewDidLoad()

        view.backgroundColor = .white
        
        /// Kann nicht in der Basisklasse definiert werden
        collectionView.delegate = self
    }
    
    ///---------------------------------------------------------------------------------------
    /// Konfiguration von Zellen, die nicht vom BasicType abgedeckt sind (z.B. Summen, Statistik, Liste von Objekten)
    ///
    override func cellConfiguration(cell: CommonCollectionViewCell, itemIdentifier: ItemType, indexPath: IndexPath) {
        
        ///-----------------------------------------------------------------------------------
        /// Spezielles Item zur Anzeige des Bildes mit dem Layout
        ///
        if itemIdentifier.stringContent(for: "Maße") {
            
            /// Berechnung der Größe anhand der Bounds des Views
            let width  = min(380, (view.bounds.width - 80))
            let height = width * 303 / 570
            
            var configuration = cell.defaultContentConfiguration()
            configuration.image = UIImage.maßeFürBlockQuote
            configuration.imageProperties.maximumSize = CGSize(width: width, height: height)
            cell.contentConfiguration = configuration
            cell.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0)
        }
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

        if key == ViewSetting.viewHeadIndent.key {
            print("HeadIndent \(value) ")
            setting.pushProperty(value: value as? Double, key: key)
//            ItemType.reconfigureIfNeeded(on: self.dataSource, ViewSettings.viewHeadIndent_1.key)
        }
        else if key == ViewSetting.viewTailIndent.key {
            print("TailIndent \(value) ")
            setting.pushProperty(value: value as? Double, key: key)
//            ItemType.reconfigureIfNeeded(on: self.dataSource, ViewSettings.viewTailIndent_1.key)
        }

        else if key == ViewSetting.viewTextColor.key {
            let color = value as? UIColor ?? .black
            setting.pushProperty(value: color, key: key)
            print("Color", setting.isChanged, key, value)
        }
        else {
            /// Die Attribute werden als ihre ursprünglichen Datentypen gespeichert
            setting.pushProperty(value: value, key: key)
            print("Änderungen", setting.isChanged, key, value)
        }
        saveButtonState()
        
        /// Rückmeldung über Änderungen für Live Preview
        onLiveChange?(setting)
    }
    
    ///---------------------------------------------------------------------------------------
    /// CLOSURE - Funktion für die Aktualisierung von Attributen (Standardfunktion tut nichts)
    ///
    override func onUpdateData(value: Any, key: String?) -> AnyHashable? {

        if let item = SectionContent.allCases.first(where: {$0.rawValue == key}) {
            return Self.activeSection[item]
        }
        
        typealias C = ViewSetting

        if key == C.message.key, let settings = entity {
            
            /// Meldung, die überprüft, ob die eingegebenen Daten gültig sind
            var text = """
              Für die Einzüge sind nur Werte größer gleich Null zulässing. Der rechte Rand wird
              intern in einen negativen Wert umgerechnet. Die Zeilenhöhe darf nicht kleiner als 1 sein.
              """
            var isOk = true
            
            if  let headIndent = settings.property(forKey: C.viewHeadIndent.key) as? CGFloat,
                let tailIndent = settings.property(forKey: C.viewTailIndent.key) as? CGFloat,
                let lineHeight = settings.property(forKey: C.viewLineHeightMultiple.key) as? CGFloat
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

    
    //--------------------------------------------------------------------------------------------
    // MARK: - UICollectionViewDelegate: Bearbeitung im Handler

    /// Ausführen einer Aktion bei Auswahl einer Zelle
    public override func handleSelection(of item: ItemType, at indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }

        /// Beispiel für Aufruf des Druckens
        if item == linkPrint?    .itemType { actionShare(linkPrint) }
        if item == linkDefaults? .itemType { actionSetDefaults() }
    }
    
    /// Abfrage, ob eine Zelle ausgewählt werden kann
    public override func canSelect(item: ItemType, at indexPath: IndexPath) -> Bool {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return false }

        /// Beispiel für Aufruf des Druckens
        if item == linkPrint?    .itemType { return true }
        if item == linkDefaults? .itemType { return true }

        collectionView.deselectItem(at: indexPath, animated: false)
        return false
    }
}
