//
//  SettingsController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 22.05.25.
//

import CoreData
import UIKit
import CommonCollection



// MARK: – SettingsController für Loading, Saving & Restoring
@MainActor
final class SettingsController {
    static let shared = SettingsController()
    private let ctx = Persistence.shared.persistentContainer.viewContext

    /// Objekt-ID der aktiven Settings – perfekt, um sie in Child-Contexts wiederzuverwenden
    var activeObjectID: NSManagedObjectID { active.objectID }

    private(set) var `default`: Settings
    private(set) var   active : Settings
    
    private init() {
        
        let defaultSettings: Settings
        if let def = try? ctx.fetch(Settings.fetchRequest(kind: .default)).first {
            defaultSettings = def
        } else {
            defaultSettings = Settings(context: ctx)
            defaultSettings.kind = Settings.Kind.default.rawValue
        }

        // -> Nur speichern, wenn sich beim Kopieren etwas geändert hat
        if Self.copyMarkdown(to: defaultSettings) {
            try? ctx.save()
        }
        self.default = defaultSettings
          
        
        // --- Active instanziieren oder laden (Kopie des Default) ---
        let activeSettings: Settings
        if let act = try? ctx.fetch(Settings.fetchRequest(kind: .active)).first {
            activeSettings = act
        } else {
            activeSettings = Settings(context: ctx)
            activeSettings.kind = Settings.Kind.active.rawValue
            // Erstbefüllung: direkt kopieren (egal ob sich etwas ändert)
            _ = Self.copyMarkdown(to: activeSettings)
            try? ctx.save()
        }
        self.active = activeSettings
        
        
        // Nun sind erst alle Stored Properties initialisiert …
        self.`default` = defaultSettings
        self.active    = activeSettings
        
        // … und jetzt dürfen wir Instanz-Methoden aufrufen
        Self.apply(self.active)
    }
    
    func save(_ s: Settings, in context: NSManagedObjectContext) throws {
        do {
            // sicherstellen, dass Main-Context die Änderung bekommt
            try context.save()
            try ctx.save()
        }
        catch {
            assertionFailure("Settings-Save failed: \(error)")
        }
    }

    private static func copy(from src: Settings, to dst: Settings) {
        for (name, _) in src.entity.attributesByName {
            guard name != #keyPath(Settings.kind)            // ausschließen
               else { continue }

            // Relationen werden hier ohnehin nicht erfasst
            dst.setValue(src.value(forKey: name), forKey: name)
        }
    }
 
    func restoreDefaults(to dst: Settings) {
        // Default → Active kopieren, anwenden und speichern
        Self.copy(from: `default`, to: dst)
    }
    
    
    
    private static func assignDefaults(to s: Settings) -> Bool {
        var didChange = false

        func set<V: Equatable>(_ keyPath: ReferenceWritableKeyPath<Settings,V>, _ new: V) {
            if s[keyPath: keyPath] != new {
                s[keyPath: keyPath] = new
                didChange = true
            }
        }

        set(\.viewTextSize,   17)
        set(\.viewHeadIndent, 0)
        // ...
        return didChange
    }
/*
    if assignDefaults(to: defaultSettings) {
        try? ctx.save()   // nur wenn wirklich etwas anders war
    }
 */
}

// MARK: - Settings ⇆ Markdown Synchronisation
extension SettingsController {

    // ------------------------------------------------------------
    //  1)  Generischer Feld-Mapper  (Closure-basiert, typ-sicher)
    // ------------------------------------------------------------
    struct FieldMap<Value> {
        // Core-Data-Seite
        let settingsKey : ReferenceWritableKeyPath<Settings, Value>

        // Markdown-Seite – als Getter/Setter-Closures
        let getMarkdown : () -> Value
        let setMarkdown : (Value) -> Void

        // optionale Konvertierung (Identität = Standard)
        var toMarkdown  : (Value) -> Value = { $0 }   // Settings ➜ Markdown
        var toSettings  : (Value) -> Value = { $0 }   // Markdown ➜ Settings
    }

    // ------------------------------------------------------------
    //  2)  Zuordnungen (3 Listen = 3 Typen)
    // ------------------------------------------------------------
    // Double-Felder  (Markdown & Markdown.PDF)
    private static let doubleMaps: [FieldMap<Double>] = [

        // ── Markdown ────────────────────────────────────────────
        FieldMap(settingsKey: \Settings.viewTextSize,
                 getMarkdown: { Markdown.textSize },
                 setMarkdown: { Markdown.textSize = $0 }),

        FieldMap(settingsKey: \Settings.codeTextSizeFactor,
                 getMarkdown: { Markdown.CodeBlock.codeTextSizeFactor },
                 setMarkdown: { Markdown.CodeBlock.codeTextSizeFactor = $0 }),

        FieldMap(settingsKey: \Settings.viewHeadIndent,
                 getMarkdown: { Markdown.headIndent },
                 setMarkdown: { Markdown.headIndent = $0 }),

        FieldMap(settingsKey: \Settings.viewTailIndent,
                 getMarkdown: { Markdown.tailIndent },
                 setMarkdown: { Markdown.tailIndent = $0 },
                 toMarkdown: { -$0 },   // Vorzeichenwechsel beachten
                 toSettings: { -$0 }),

        FieldMap(settingsKey: \Settings.viewLineHeight,
                 getMarkdown: { Markdown.lineHeightMultiple },
                 setMarkdown: { Markdown.lineHeightMultiple = $0 }),

        FieldMap(settingsKey: \Settings.viewSpacing,
                 getMarkdown: { Markdown.paragraphSpacing },
                 setMarkdown: { Markdown.paragraphSpacing = $0 }),

        FieldMap(settingsKey: \Settings.viewSpacingBefore,
                 getMarkdown: { Markdown.paragraphSpacingBefore },
                 setMarkdown: { Markdown.paragraphSpacingBefore = $0 }),

        // ── Markdown.BlockQuote ────────────────────────────────────────
        FieldMap(settingsKey: \Settings.blockHorizIndent,
                 getMarkdown: { Markdown.BlockQuote.horizontalIndent },
                 setMarkdown: { Markdown.BlockQuote.horizontalIndent = $0 }),
        
        FieldMap(settingsKey: \Settings.blockBarIndent,
                 getMarkdown: { Markdown.BlockQuote.barIndent },
                 setMarkdown: { Markdown.BlockQuote.barIndent = $0 }),

        FieldMap(settingsKey: \Settings.blockContentIndent,
                 getMarkdown: { Markdown.BlockQuote.contentIndent },
                 setMarkdown: { Markdown.BlockQuote.contentIndent = $0 }),

        FieldMap(settingsKey: \Settings.blockBarWidth,
                 getMarkdown: { Markdown.BlockQuote.barWidth },
                 setMarkdown: { Markdown.BlockQuote.barWidth = $0 }),

        FieldMap(settingsKey: \Settings.blockVerticalOffset,
                 getMarkdown: { Markdown.BlockQuote.verticalOffset },
                 setMarkdown: { Markdown.BlockQuote.verticalOffset = $0 }),
        
        // ── Markdown.Ruler ────────────────────────────────────────
        FieldMap(settingsKey: \Settings.rulerHeight,
                 getMarkdown: { Markdown.Ruler.height },
                 setMarkdown: { Markdown.Ruler.height = $0 }),
        
        FieldMap(settingsKey: \Settings.rulerLineHeight,
                 getMarkdown: { Markdown.Ruler.lineHeight },
                 setMarkdown: { Markdown.Ruler.lineHeight = $0 }),
        
        FieldMap(settingsKey: \Settings.rulerRightIndent,
                 getMarkdown: { Markdown.Ruler.rightIndent },
                 setMarkdown: { Markdown.Ruler.rightIndent = $0 }),

        // ── Markdown.PDF ────────────────────────────────────────
        FieldMap(settingsKey: \Settings.pdfTextSize,
                 getMarkdown: { Markdown.PDF.textSize },
                 setMarkdown: { Markdown.PDF.textSize = $0 }),
        
        FieldMap(settingsKey: \Settings.pdfMarginLeft,
                 getMarkdown: { Markdown.PDF.marginLeft },
                 setMarkdown: { Markdown.PDF.marginLeft = $0 },
                 toMarkdown: { $0 * Markdown._1cm },
                 toSettings: { $0 / Markdown._1cm }),

        FieldMap(settingsKey: \Settings.pdfMarginRight,
                 getMarkdown: { Markdown.PDF.marginRight },
                 setMarkdown: { Markdown.PDF.marginRight = $0 },
                 toMarkdown: { $0 * Markdown._1cm },
                 toSettings: { $0 / Markdown._1cm }),

        FieldMap(settingsKey: \Settings.pdfMarginTop,
                 getMarkdown: { Markdown.PDF.marginTop },
                 setMarkdown: { Markdown.PDF.marginTop = $0 },
                 toMarkdown: { $0 * Markdown._1cm },
                 toSettings: { $0 / Markdown._1cm }),

        FieldMap(settingsKey: \Settings.pdfMarginBottom,
                 getMarkdown: { Markdown.PDF.marginBottom },
                 setMarkdown: { Markdown.PDF.marginBottom = $0 },
                 toMarkdown: { $0 * Markdown._1cm },
                 toSettings: { $0 / Markdown._1cm }),

    ]

    // Bool-Felder
    private static let boolMaps: [FieldMap<Bool>] = [
        FieldMap(settingsKey: \Settings.viewSoftBreaks,
                 getMarkdown: { Markdown.useSoftBreaks },
                 setMarkdown: { Markdown.useSoftBreaks = $0 }),
        
        FieldMap(settingsKey: \Settings.rulerHighlightColor,
                 getMarkdown: { Markdown.Ruler.colorHighLight },
                 setMarkdown: { Markdown.Ruler.colorHighLight = $0 })
    ]

    // Farb-Felder
    private static let colorMaps: [FieldMap<UIColor>] = [

        FieldMap(settingsKey: \Settings.viewColor,
                 getMarkdown: { Markdown.textColor },
                 setMarkdown: { Markdown.textColor = $0 }),

        FieldMap(settingsKey: \Settings.pdfTextColor,
                 getMarkdown: { Markdown.PDF.textColor },
                 setMarkdown: { Markdown.PDF.textColor = $0 })
    ]
    
    private static let optionalColorMaps: [FieldMap<UIColor?>] = [
        FieldMap(settingsKey: \Settings.blockBarColor,
                 getMarkdown: { Markdown.BlockQuote.barColor },
                 setMarkdown: { if let color = $0 { Markdown.BlockQuote.barColor = color } }),
        
        FieldMap(settingsKey: \Settings.blockBackColor,
                 getMarkdown: { Markdown.BlockQuote.backgroundColor },
                 setMarkdown: { if let color = $0 { Markdown.BlockQuote.backgroundColor = color } })
    ]

    // ------------------------------------------------------------
    //  3)  Settings ➜ Markdown   (beim App-Start / nach Save)
    // ------------------------------------------------------------
    static func apply(_ s: Settings) {
        
        for m in Self.doubleMaps { m.setMarkdown( m.toMarkdown( s[keyPath: m.settingsKey] ) ) }
        for m in Self.boolMaps   { m.setMarkdown( m.toMarkdown( s[keyPath: m.settingsKey] ) ) }
        for m in Self.colorMaps  { m.setMarkdown( m.toMarkdown( s[keyPath: m.settingsKey] ) ) }
        for m in Self.optionalColorMaps { m.setMarkdown( m.toMarkdown( s[keyPath: m.settingsKey] ) ) }
    }

    // ------------------------------------------------------------
    //  4)  Markdown ➜ Settings   (Seed, Restore-Defaults, Save)
    // ------------------------------------------------------------
//    private static func copyFromMarkdown(to s: Settings) {
//
//        for m in Self.doubleMaps { s[keyPath: m.settingsKey] = m.toSettings( m.getMarkdown() ) }
//        for m in Self.boolMaps   { s[keyPath: m.settingsKey] = m.toSettings( m.getMarkdown() ) }
//        for m in Self.colorMaps  { s[keyPath: m.settingsKey] = m.toSettings( m.getMarkdown() ) }
//    }
    
    
    /// Kopiert alle Felder aus Markdown in das übergebene Settings-Objekt
    /// und gibt `true` zurück, sobald mindestens ein Wert geändert wurde.
    private static func copyMarkdown(to target: Settings) -> Bool {

        var didChange = false

        // ------- Double -----------
        for m in Self.doubleMaps {
            let newVal = m.toSettings(m.getMarkdown())
            if target[keyPath: m.settingsKey] != newVal {
                target[keyPath: m.settingsKey] = newVal
                didChange = true
            }
        }

        // ------- Bool -------------
        for m in Self.boolMaps {
            let newVal = m.toSettings(m.getMarkdown())
            if target[keyPath: m.settingsKey] != newVal {
                target[keyPath: m.settingsKey] = newVal
                didChange = true
            }
        }

        // ------- UIColor ----------
        for m in Self.colorMaps {
            let newVal = m.toSettings(m.getMarkdown())
            if target[keyPath: m.settingsKey] != newVal {
                target[keyPath: m.settingsKey] = newVal
                didChange = true
            }
        }
        
        // ------- UIColor? ----------
        for m in Self.optionalColorMaps {
            let newVal = m.toSettings(m.getMarkdown())
            if target[keyPath: m.settingsKey] != newVal {
                target[keyPath: m.settingsKey] = newVal
                didChange = true
            }
        }
        return didChange
    }
}
