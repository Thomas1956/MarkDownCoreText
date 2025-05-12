//
//  Settings+PropertyReminder.swift
//  CoreTextTableExample
//
//  Created by Thomas on 09.05.25.
//

import CoreData
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Temporäres Speichern von Properties in einem Directory

extension Settings: PropertyReminder, GenericEntity {
    
    /// GenericProtocol
    public typealias Entity = Settings

    /// Standard-Prädikat
    public static var defaultPredicate: NSPredicate = .all

    /// Standard-Sortieren. Sinnvollerweise sollte ein Kriterium definiert werden.
    public static var defaultSortDescriptor: [NSSortDescriptor] = []

    /// Der `#keyPath` für die Sektionen der Tabelle. Der Wert wird auf `nil` gesetzt, wenn es keine Sektionen gibt.
    /// Der Wert könnte beispielsweise als `#keyPath(Person.firstLetter)` definiert sein.
    public static var defaultSectionNameKeyPath : String? = nil
    
    /// Das Prädikat für die Filterung der ResultTabelle. In der Regel wird `NSPredicate.all` verwendet.
    public static var resultPredicate: NSPredicate = .all
    
    /// Der Sort-Descriptor für die ResultTabelle. Kann auf `defaultSortDescriptor` gesetzt werden.
    public static var resultSortDescriptor: [NSSortDescriptor] = defaultSortDescriptor
    
    /// Abfrage, ob die Entity gelöscht werden kann.
    public var canDelete : Bool {
        get {
            return true
        }
    }

    ///---------------------------------------------------------------------------------------
    // MARK: - Zusätzlich Properties und Funktionen ergänzen
    
    /// Beispiel für die berechnete Property `firstLetter`, die für die Anzeige der Sektionen genutzt werden kann.
    /*
    @objc public var firstLetter: String {
        self.willAccessValue(forKey: #keyPath(Person.firstLetter))
        /// Damit die Sektionen mit der Sortierung übereinstimmen, müssen die Diacritics entfernt werden
        let familyname = self.familyName?.uppercased().folding(options: .diacriticInsensitive, locale: .current) ?? "A"
        self.didAccessValue(forKey: #keyPath(Person.firstLetter))
        /// Anfangsbuchstaben zurückgeben
        return String(familyname.prefix(1))
    }
    */    
}
