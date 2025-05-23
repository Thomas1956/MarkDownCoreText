//
//  SettingsController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 22.05.25.
//

import CoreData
import CommonCollection


// MARK: – SettingsController für Loading, Saving & Restoring
final class SettingsController {
    static let shared = SettingsController()
    private let ctx = Persistence.shared.persistentContainer.viewContext

    /// Objekt-ID der aktiven Settings – perfekt, um sie in Child-Contexts wiederzuverwenden
    var activeObjectID: NSManagedObjectID { active.objectID }

    private(set) var `default`: Settings
    private(set) var active: Settings
    
    private init() {
        // --- Default instanziieren oder laden ---
        let defaultSettings: Settings
        if let def = try? ctx.fetch(Settings.fetchRequest(kind: .default)).first {
            defaultSettings = def
        } else {
            let def = Settings(context: ctx)
            def.kind            = Settings.Kind.default.rawValue
            def.viewTextSize    = Markdown.textSize
            def.viewHeadIndent  = Markdown.headIndent
            def.viewTailIndent  = -Markdown.tailIndent
            def.viewLineHeight  = Markdown.lineHeightMultiple
            
            def.pdfTextSize     = Markdown.PDF.textSize
            def.pdfColor        = Markdown.PDF.textColor

            try! ctx.save()
            defaultSettings = def
        }
        
        // --- Active instanziieren oder laden (Kopie des Default) ---
        let activeSettings: Settings
        if let act = try? ctx.fetch(Settings.fetchRequest(kind: .active)).first {
            activeSettings = act
        } else {
            let act = Settings(context: ctx)
            act.kind = Settings.Kind.active.rawValue
            // Hier rufen wir eine statische copy-Methode auf
            SettingsController.copy(from: defaultSettings, to: act)
            try! ctx.save()
            activeSettings = act
        }
        
        // Nun sind erst alle Stored Properties initialisiert …
        self.`default` = defaultSettings
        self.active    = activeSettings
        
        // … und jetzt dürfen wir Instanz-Methoden aufrufen
        apply(self.active)
    }
    
    func save(_ s: Settings, in context: NSManagedObjectContext) throws {
       try context.save()
       // sicherstellen, dass Main-Context die Änderung bekommt
       try ctx.save()
     }

    // MARK: – Private Factory
    private static func fetchOrCreate(kind: Settings.Kind,
                                      in context: NSManagedObjectContext) -> Settings
    {
        let req = Settings.fetchRequest(kind: kind)
        if let obj = (try? context.fetch(req))?.first { return obj }
        
        let new = Settings(context: context)
        new.kind               = kind.rawValue
        // Default befüllen nur beim Default-Objekt
        if kind == .default {
            new.viewTextSize       = Markdown.textSize
            new.viewHeadIndent     = Markdown.headIndent
            new.viewTailIndent     = -Markdown.tailIndent
            new.viewLineHeight     = Markdown.lineHeightMultiple
            new.viewColor          = Markdown.textColor
            
            new.pdfTextSize        = Markdown.PDF.textSize
            new.pdfColor           = Markdown.PDF.textColor
        }
        try? context.save()
        return new
    }
    
    // Ty­p-Methode, greift nicht auf `self` zu
    private static func copy(from src: Settings, to dst: Settings) {
        dst.viewTextSize    = src.viewTextSize
        dst.viewHeadIndent  = src.viewHeadIndent
        dst.viewTailIndent  = src.viewTailIndent
        dst.viewLineHeight  = src.viewLineHeight
        dst.viewColor       = src.viewColor
        
        dst.pdfTextSize     = src.pdfTextSize
        dst.pdfColor        = src.pdfColor
    }
    
    func apply(_ s: Settings) {
        Markdown.textSize           =  s.viewTextSize
        Markdown.headIndent         =  s.viewHeadIndent
        Markdown.tailIndent         = -s.viewTailIndent
        Markdown.lineHeightMultiple =  s.viewLineHeight
        Markdown.textColor          =  s.viewColor ?? .label
        
        Markdown.PDF.textSize       =  s.pdfTextSize
        Markdown.PDF.textColor      =  s.pdfColor ?? .label
    }
    
    // … Deine saveActive() und restoreDefaults() bleiben unverändert …
    
    func saveActive() {
        // Werte aus Markdown zurück in active schreiben
        active.viewTextSize    = Markdown.textSize
        active.viewHeadIndent  = Markdown.headIndent
        active.viewTailIndent  = -Markdown.tailIndent
        active.viewLineHeight  = Markdown.lineHeightMultiple
        
        active.pdfTextSize     = Markdown.PDF.textSize
        active.pdfColor        = Markdown.PDF.textColor
        try? ctx.save()
    }
    
    func restoreDefaults() {
        // Default → Active kopieren, anwenden und speichern
        Self.copy(from: `default`, to: active)
        apply(active)
        try? ctx.save()
    }
}
