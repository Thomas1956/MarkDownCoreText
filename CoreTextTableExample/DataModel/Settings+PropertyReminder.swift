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
    
    private static let strokeColorDefinitions     = makeDerivedColorDefinitions(\.derivedStrokeColor)
    private static let fillColorDefinitions       = makeDerivedColorDefinitions(\.derivedFillColor)
    private static let headerFillColorDefinitions = makeDerivedColorDefinitions(\.derivedHeaderFillColor)
    
    static let textColorPalette                   = makeColorPalette(textColorDefinitions)
    static let blockBarColorPalette               = makeColorPalette(strokeColorDefinitions)
    static let blockBackgroundColorPalette        = makeColorPalette(fillColorDefinitions)
    static let rulerColorPalette                  = makeColorPalette(strokeColorDefinitions)
    static let codeBackgroundColorPalette         = makeColorPalette(fillColorDefinitions)
    static let codeBorderColorPalette             = makeColorPalette(strokeColorDefinitions)
    static let tableGridColorPalette              = makeColorPalette(strokeColorDefinitions)
    static let tableHeaderBackgroundColorPalette  = makeColorPalette(headerFillColorDefinitions)
    static let tableBackgroundColorPalette        = makeColorPalette(fillColorDefinitions)
    
    private static var completeColorPalette: [UIColor] {
        (textColorDefinitions + strokeColorDefinitions + fillColorDefinitions + headerFillColorDefinitions).map(\.1)
    }
    
    private static func makeColorPalette(_ definitions: [(String, UIColor)]) -> [KeyText] {
        definitions.map { name, color in
            KeyText(value: color, text: name, color: color)
        }
    }
    
    private static func makeDerivedColorDefinitions(_ keyPath: KeyPath<UIColor, UIColor>) -> [(String, UIColor)] {
        textColorDefinitions.map { name, color in
            (name, color[keyPath: keyPath])
        }
    }
    
    private static func defaultedColor(_ color: UIColor?, default defaultColor: UIColor) -> UIColor {
        color ?? defaultColor
    }
    
    ///---------------------------------------------------------------------------------------
    /// Gemeinsame Textfarbe für LiveView und PDF.
    @objc dynamic public var viewTextColor: UIColor {
        get { viewRawTextColor as? UIColor ?? .black }
        set { viewRawTextColor = newValue }
    }

    /// Eigene Farbe für die Balken im BlockQuote.
    @objc dynamic public var blockBarColor: UIColor? {
        get { Self.defaultedColor(blockRawBarColor as? UIColor, default: .systemGray4) }
        set { blockRawBarColor = Self.defaultedColor(newValue, default: .systemGray4) }
    }

    /// Eigene Farbe für den Hintergrund im BlockQuote.
    @objc dynamic public var blockBackgroundColor: UIColor? {
        get { Self.defaultedColor(blockRawBackgroundColor as? UIColor, default: .systemGray6) }
        set { blockRawBackgroundColor = Self.defaultedColor(newValue, default: .systemGray6) }
    }

    /// Eigene Farbe für die Trennlinie, wenn `rulerUseHighlightColor` aus ist.
    @objc dynamic public var rulerColor: UIColor? {
        get { Self.defaultedColor(rulerRawColor as? UIColor, default: .systemGray4) }
        set { rulerRawColor = Self.defaultedColor(newValue, default: .systemGray4) }
    }

    /// Eigene Farbe für den CodeBlock-Hintergrund.
    @objc dynamic public var codeBackgroundColor: UIColor? {
        get { Self.defaultedColor(codeRawBackgroundColor as? UIColor, default: .systemGray6) }
        set { codeRawBackgroundColor = Self.defaultedColor(newValue, default: .systemGray6) }
    }

    /// Eigene Farbe für den CodeBlock-Rahmen.
    @objc dynamic public var codeBorderColor: UIColor? {
        get { Self.defaultedColor(codeRawBorderColor as? UIColor, default: .systemGray4) }
        set { codeRawBorderColor = Self.defaultedColor(newValue, default: .systemGray4) }
    }

    /// Eigene Farbe für die Gitterlinien der Tabelle.
    @objc dynamic public var tableGridColor: UIColor? {
        get { Self.defaultedColor(tableRawGridColor as? UIColor, default: .systemGray4) }
        set { tableRawGridColor = Self.defaultedColor(newValue, default: .systemGray4) }
    }

    /// Eigene Farbe für den Tabellen-Header-Hintergrund.
    @objc dynamic public var tableHeaderBackgroundColor: UIColor? {
        get { Self.defaultedColor(tableRawHeaderBackgroundColor as? UIColor, default: .systemGray5) }
        set { tableRawHeaderBackgroundColor = Self.defaultedColor(newValue, default: .systemGray5) }
    }

    /// Eigene Farbe für den Tabellen-Body-Hintergrund.
    @objc dynamic public var tableBackgroundColor: UIColor? {
        get { Self.defaultedColor(tableRawBackgroundColor as? UIColor, default: .systemGray6) }
        set { tableRawBackgroundColor = Self.defaultedColor(newValue, default: .systemGray6) }
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
