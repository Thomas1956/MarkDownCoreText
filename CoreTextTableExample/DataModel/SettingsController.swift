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
    // Double-Felder
    private static let doubleMaps: [FieldMap<Double>] = [

        // ── View / allgemein ───────────────────────────────────
        FieldMap(settingsKey: \Settings.viewTextSize,
                 getMarkdown: { Markdown.textSize },
                 setMarkdown: { Markdown.textSize = $0 }),

        FieldMap(settingsKey: \Settings.viewMarginLeft,
                 getMarkdown: { Markdown.marginLeft },
                 setMarkdown: { Markdown.marginLeft = $0 }),

        FieldMap(settingsKey: \Settings.viewMarginRight,
                 getMarkdown: { Markdown.marginRight },
                 setMarkdown: { Markdown.marginRight = $0 }),

        FieldMap(settingsKey: \Settings.viewLineHeightMultiple,
                 getMarkdown: { Markdown.lineHeightMultiple },
                 setMarkdown: { Markdown.lineHeightMultiple = $0 }),

        FieldMap(settingsKey: \Settings.viewParagraphSpacing,
                 getMarkdown: { Markdown.paragraphSpacing },
                 setMarkdown: { Markdown.paragraphSpacing = $0 }),

        FieldMap(settingsKey: \Settings.viewParagraphSpacingBefore,
                 getMarkdown: { Markdown.paragraphSpacingBefore },
                 setMarkdown: { Markdown.paragraphSpacingBefore = $0 }),

        // ── Markdown.BlockQuote ────────────────────────────────
        FieldMap(settingsKey: \Settings.blockIndentLeft,
                 getMarkdown: { Markdown.BlockQuote.indentLeft },
                 setMarkdown: { Markdown.BlockQuote.indentLeft = $0 }),

        FieldMap(settingsKey: \Settings.blockIndentRight,
                 getMarkdown: { Markdown.BlockQuote.indentRight },
                 setMarkdown: { Markdown.BlockQuote.indentRight = $0 }),

        FieldMap(settingsKey: \Settings.blockBarIndent,
                 getMarkdown: { Markdown.BlockQuote.barIndent },
                 setMarkdown: { Markdown.BlockQuote.barIndent = $0 }),

        FieldMap(settingsKey: \Settings.blockBarWidth,
                 getMarkdown: { Markdown.BlockQuote.barWidth },
                 setMarkdown: { Markdown.BlockQuote.barWidth = $0 }),

        FieldMap(settingsKey: \Settings.blockPaddingLeft,
                 getMarkdown: { Markdown.BlockQuote.paddingLeft },
                 setMarkdown: { Markdown.BlockQuote.paddingLeft = $0 }),

        FieldMap(settingsKey: \Settings.blockPaddingRight,
                 getMarkdown: { Markdown.BlockQuote.paddingRight },
                 setMarkdown: { Markdown.BlockQuote.paddingRight = $0 }),

        FieldMap(settingsKey: \Settings.blockVerticalOffset,
                 getMarkdown: { Markdown.BlockQuote.verticalOffset },
                 setMarkdown: { Markdown.BlockQuote.verticalOffset = $0 }),

        // ── Markdown.CodeBlock ─────────────────────────────────
        FieldMap(settingsKey: \Settings.codeTextSizeFactor,
                 getMarkdown: { Markdown.CodeBlock.textSizeFactor },
                 setMarkdown: { Markdown.CodeBlock.textSizeFactor = $0 }),

        FieldMap(settingsKey: \Settings.codeLineHeightMultiple,
                 getMarkdown: { Markdown.CodeBlock.lineHeightMultiple },
                 setMarkdown: { Markdown.CodeBlock.lineHeightMultiple = $0 }),

        FieldMap(settingsKey: \Settings.codeSpacing,
                 getMarkdown: { Markdown.CodeBlock.spacing },
                 setMarkdown: { Markdown.CodeBlock.spacing = $0 }),

        FieldMap(settingsKey: \Settings.codeSpacingBefore,
                 getMarkdown: { Markdown.CodeBlock.spacingBefore },
                 setMarkdown: { Markdown.CodeBlock.spacingBefore = $0 }),

        FieldMap(settingsKey: \Settings.codeIndentLeft,
                 getMarkdown: { Markdown.CodeBlock.indentLeft },
                 setMarkdown: { Markdown.CodeBlock.indentLeft = $0 }),

        FieldMap(settingsKey: \Settings.codeIndentRight,
                 getMarkdown: { Markdown.CodeBlock.indentRight },
                 setMarkdown: { Markdown.CodeBlock.indentRight = $0 }),

        FieldMap(settingsKey: \Settings.codePaddingLeft,
                 getMarkdown: { Markdown.CodeBlock.paddingLeft },
                 setMarkdown: { Markdown.CodeBlock.paddingLeft = $0 }),

        FieldMap(settingsKey: \Settings.codePaddingRight,
                 getMarkdown: { Markdown.CodeBlock.paddingRight },
                 setMarkdown: { Markdown.CodeBlock.paddingRight = $0 }),

        FieldMap(settingsKey: \Settings.codeBorderWidth,
                 getMarkdown: { Markdown.CodeBlock.borderWidth },
                 setMarkdown: { Markdown.CodeBlock.borderWidth = $0 }),

        // ── Markdown.Ruler ─────────────────────────────────────
        FieldMap(settingsKey: \Settings.rulerHeight,
                 getMarkdown: { Markdown.Ruler.height },
                 setMarkdown: { Markdown.Ruler.height = $0 }),

        FieldMap(settingsKey: \Settings.rulerLineHeight,
                 getMarkdown: { Markdown.Ruler.lineHeight },
                 setMarkdown: { Markdown.Ruler.lineHeight = $0 }),

        FieldMap(settingsKey: \Settings.rulerPaddingLeft,
                 getMarkdown: { Markdown.Ruler.paddingLeft },
                 setMarkdown: { Markdown.Ruler.paddingLeft = $0 }),

        FieldMap(settingsKey: \Settings.rulerPaddingRight,
                 getMarkdown: { Markdown.Ruler.paddingRight },
                 setMarkdown: { Markdown.Ruler.paddingRight = $0 }),

        // ── Markdown.Table ─────────────────────────────────────
        FieldMap(settingsKey: \Settings.tableIndentLeft,
                 getMarkdown: { Markdown.Table.indentLeft },
                 setMarkdown: { Markdown.Table.indentLeft = $0 }),

        FieldMap(settingsKey: \Settings.tableIndentRight,
                 getMarkdown: { Markdown.Table.indentRight },
                 setMarkdown: { Markdown.Table.indentRight = $0 }),

        // ── Markdown.PDF ───────────────────────────────────────
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
        FieldMap(settingsKey: \Settings.viewUseSoftBreaks,
                 getMarkdown: { Markdown.useSoftBreaks },
                 setMarkdown: { Markdown.useSoftBreaks = $0 }),

        FieldMap(settingsKey: \Settings.viewUseHyphenation,
                 getMarkdown: { Markdown.useHyphenation },
                 setMarkdown: { Markdown.useHyphenation = $0 }),

        FieldMap(settingsKey: \Settings.viewUseJustification,
                 getMarkdown: { Markdown.useJustification },
                 setMarkdown: { Markdown.useJustification = $0 }),

        FieldMap(settingsKey: \Settings.blockUseDefaultTextColor,
                 getMarkdown: { Markdown.BlockQuote.useDefaultTextColor },
                 setMarkdown: { Markdown.BlockQuote.useDefaultTextColor = $0 }),

        FieldMap(settingsKey: \Settings.blockUseDefaultBarColor,
                 getMarkdown: { Markdown.BlockQuote.useDefaultBarColor },
                 setMarkdown: { Markdown.BlockQuote.useDefaultBarColor = $0 }),

        FieldMap(settingsKey: \Settings.blockUseDefaultBackgroundColor,
                 getMarkdown: { Markdown.BlockQuote.useDefaultBackgroundColor },
                 setMarkdown: { Markdown.BlockQuote.useDefaultBackgroundColor = $0 }),

        FieldMap(settingsKey: \Settings.codeUseDefaultBackgroundColor,
                 getMarkdown: { Markdown.CodeBlock.useDefaultBackgroundColor },
                 setMarkdown: { Markdown.CodeBlock.useDefaultBackgroundColor = $0 }),

        FieldMap(settingsKey: \Settings.codeUseDefaultBorderColor,
                 getMarkdown: { Markdown.CodeBlock.useDefaultBorderColor },
                 setMarkdown: { Markdown.CodeBlock.useDefaultBorderColor = $0 }),

        FieldMap(settingsKey: \Settings.rulerUseHighlightColor,
                 getMarkdown: { Markdown.Ruler.useHighlightColor },
                 setMarkdown: { Markdown.Ruler.useHighlightColor = $0 }),

        FieldMap(settingsKey: \Settings.tableUseDefaultGridColor,
                 getMarkdown: { Markdown.Table.useDefaultGridColor },
                 setMarkdown: { Markdown.Table.useDefaultGridColor = $0 }),

        FieldMap(settingsKey: \Settings.tableUseDefaultHeaderBackgroundColor,
                 getMarkdown: { Markdown.Table.useDefaultHeaderBackgroundColor },
                 setMarkdown: { Markdown.Table.useDefaultHeaderBackgroundColor = $0 }),

        FieldMap(settingsKey: \Settings.tableUseDefaultBackgroundColor,
                 getMarkdown: { Markdown.Table.useDefaultBackgroundColor },
                 setMarkdown: { Markdown.Table.useDefaultBackgroundColor = $0 }),
    ]

    // Farb-Felder
    private static let colorMaps: [FieldMap<UIColor>] = [
        FieldMap(settingsKey: \Settings.viewTextColor,
                 getMarkdown: { Markdown.textColor },
                 setMarkdown: { Markdown.textColor = $0 })
    ]

    private static let optionalColorMaps: [FieldMap<UIColor?>] = [
        FieldMap(settingsKey: \Settings.blockTextColor,
                 getMarkdown: { Markdown.BlockQuote.textColor },
                 setMarkdown: { if let color = $0 { Markdown.BlockQuote.textColor = color } }),

        FieldMap(settingsKey: \Settings.blockBarColor,
                 getMarkdown: { Markdown.BlockQuote.barColor },
                 setMarkdown: { if let color = $0 { Markdown.BlockQuote.barColor = color } }),

        FieldMap(settingsKey: \Settings.blockBackgroundColor,
                 getMarkdown: { Markdown.BlockQuote.backgroundColor },
                 setMarkdown: { if let color = $0 { Markdown.BlockQuote.backgroundColor = color } }),

        FieldMap(settingsKey: \Settings.codeBackgroundColor,
                 getMarkdown: { Markdown.CodeBlock.backgroundColor },
                 setMarkdown: { if let color = $0 { Markdown.CodeBlock.backgroundColor = color } }),

        FieldMap(settingsKey: \Settings.codeBorderColor,
                 getMarkdown: { Markdown.CodeBlock.borderColor },
                 setMarkdown: { if let color = $0 { Markdown.CodeBlock.borderColor = color } }),

        FieldMap(settingsKey: \Settings.rulerColor,
                 getMarkdown: { Markdown.Ruler.color },
                 setMarkdown: { if let color = $0 { Markdown.Ruler.color = color } }),

        FieldMap(settingsKey: \Settings.tableGridColor,
                 getMarkdown: { Markdown.Table.gridColor },
                 setMarkdown: { if let color = $0 { Markdown.Table.gridColor = color } }),

        FieldMap(settingsKey: \Settings.tableHeaderBackgroundColor,
                 getMarkdown: { Markdown.Table.headerBackgroundColor },
                 setMarkdown: { if let color = $0 { Markdown.Table.headerBackgroundColor = color } }),

        FieldMap(settingsKey: \Settings.tableBackgroundColor,
                 getMarkdown: { Markdown.Table.backgroundColor },
                 setMarkdown: { if let color = $0 { Markdown.Table.backgroundColor = color } }),
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
