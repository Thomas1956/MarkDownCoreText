//
//  Settings+PropertyReminder.swift
//  CoreTextTableExample
//
//  Created by Thomas on 09.05.25.
//

import CoreData
import UIKit
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
}


//--------------------------------------------------------------------------------------------
// MARK: – Entity-Extension für einfache Predicates

extension Settings {
    public enum Kind: String {
        case `default`
        case active
    }
    
    @nonobjc public class func fetchRequest(kind: Kind) -> NSFetchRequest<Settings> {
        let req = NSFetchRequest<Settings>(entityName: "Settings")
        req.predicate = NSPredicate(format: "kind == %@", kind.rawValue)
        req.fetchLimit = 1
        return req
    }
    
    private static let textColorDefinitions: [(String, UIColor)] = [
        ("Schwarz"   , .black),
        ("Dunkelgrau", .textDarkgray),
        ("Grau"      , .textGray),
        ("Hellgrau"  , .textLightgray),
        ("Blau"      , .textBlue),
        ("Mint"      , .textMint),
        ("Grün"      , .textGreen),
        ("Orange"    , .textOrange),
        ("Rot"       , .textRed),
        ("Purpur"    , .textPurple)
    ]
    
    private static let barColorDefinitions: [(String, UIColor)] = [
        ("Grau"      , .systemGray4),
        ("Dunkelgrau", .systemGray2),
        ("Blau"      , .systemBlue),
        ("Indigo"    , .systemIndigo),
        ("Mint"      , .systemMint),
        ("Grün"      , .systemGreen),
        ("Orange"    , .systemOrange),
        ("Rot"       , .systemRed),
        ("Purpur"    , .systemPurple)
    ]
    
    private static let backgroundColorDefinitions: [(String, UIColor)] = [
        ("Hellgrau"  , .systemGray6),
        ("Grau"      , .systemGray5),
        ("Blau"      , .systemBlue  .withAlphaComponent(0.12)),
        ("Indigo"    , .systemIndigo.withAlphaComponent(0.12)),
        ("Mint"      , .systemMint  .withAlphaComponent(0.14)),
        ("Grün"      , .systemGreen .withAlphaComponent(0.12)),
        ("Gelb"      , .systemYellow.withAlphaComponent(0.18)),
        ("Orange"    , .systemOrange.withAlphaComponent(0.14)),
        ("Rot"       , .systemRed   .withAlphaComponent(0.10)),
        ("Purpur"    , .systemPurple.withAlphaComponent(0.12))
    ]
    
    static let textColorPalette       = makeColorPalette(textColorDefinitions)
    static let blockBarColorPalette   = makeColorPalette(barColorDefinitions)
    static let blockBackColorPalette  = makeColorPalette(backgroundColorDefinitions)
    
    private static var completeColorPalette: [UIColor] {
        (textColorDefinitions + barColorDefinitions + backgroundColorDefinitions).map(\.1)
    }
    
    private static func makeColorPalette(_ definitions: [(String, UIColor)]) -> [KeyText] {
        definitions.map { name, color in
            KeyText(value: color, text: name, color: color)
        }
    }
    
    private static func normalizedColor(_ color: UIColor?, default defaultColor: UIColor) -> UIColor {
        guard let color else { return defaultColor }
        return completeColorPalette.first(where: { $0 == color }) ?? defaultColor
    }
    
    ///---------------------------------------------------------------------------------------
    /// Gemeinsame Textfarbe für LiveView und PDF.
    @objc dynamic public var viewColor: UIColor {
        get { viewRawColor as? UIColor ?? .black }
        set { viewRawColor = newValue }
    }
    
    /// Farbe für den Edit-Text
    @objc dynamic public var editColor: UIColor? {
        get { editRawColor as? UIColor }
        set { editRawColor = newValue  }
    }

    /// Farbe für die Box der Tabelle
    @objc dynamic public var tableBoxColor: UIColor? {
        get { tableRawBoxColor as? UIColor }
        set { tableRawBoxColor = newValue  }
    }
    
    /// Farbe für die Balken im BlockQuote
    @objc dynamic public var blockBarColor: UIColor? {
        get { Self.normalizedColor(blockRawBarColor as? UIColor, default: .systemGray4) }
        set { blockRawBarColor = Self.normalizedColor(newValue, default: .systemGray4) }
    }

    /// Farbe für die Hintergrund im BlockQuote
    @objc dynamic public var blockBackColor: UIColor? {
        get { Self.normalizedColor(blockRawBackColor as? UIColor, default: .systemGray6) }
        set { blockRawBackColor = Self.normalizedColor(newValue, default: .systemGray6) }
    }

}

@objc(ColorTransformer)
final class ColorTransformer: ValueTransformer {

    override class func transformedValueClass() -> AnyClass { NSData.self }
    override class func allowsReverseTransformation() -> Bool { true }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }
        return try? NSKeyedArchiver.archivedData(
            withRootObject: color,
            requiringSecureCoding: true
        )
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: UIColor.self,
            from: data
        )
    }
}
