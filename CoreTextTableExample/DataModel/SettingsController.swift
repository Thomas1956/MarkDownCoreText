//
//  SettingsController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 22.05.25.
//

import CoreData
import CommonCollection


final class SettingsController1 {
  static let shared = SettingsController1()
  private let ctx = Persistence.shared.persistentContainer.viewContext

  /// Die aktive Settings-Entity (im Main-Context)
  private(set) var active: Settings

  /// Objekt-ID der aktiven Settings – perfekt, um sie in Child-Contexts wiederzuverwenden
  var activeObjectID: NSManagedObjectID { active.objectID }

  private init() {
    // active laden oder neu anlegen (Kind = .active)
    active = Self.fetchOrCreate(kind: .active, in: ctx)
    // hier evtl. Default → Active, wenn neu
    apply(active)
  }

  /// Public: Werte aus der übergebenen Settings in die Markdown-Statik übernehmen
  func apply(_ s: Settings) {
    Markdown.textSize           = s.textSizeView
    Markdown.PDF.textSize       = s.textSizePDF
    Markdown.headIndent         = s.headIndent
    Markdown.tailIndent         = -s.tailIndent
    Markdown.lineHeightMultiple = s.lineHeightMultiple
  }

  /// Public: Active Settings updaten und speichern
  func save(_ s: Settings, in context: NSManagedObjectContext) throws {
    try context.save()
    // sicherstellen, dass Main-Context die Änderung bekommt
    try ctx.save()
  }

  /// Public: Active Settings zurücksetzen auf Default
  func restoreDefaults(in context: NSManagedObjectContext) throws {
    let `default` = Self.fetchOrCreate(kind: .default, in: context)
    // copy-Logik inline, ganz ohne self-aufruf vor init
    s.textSizeView       = `default`.textSizeView
    s.textSizePDF        = `default`.textSizePDF
    s.headIndent         = `default`.headIndent
    s.tailIndent         = `default`.tailIndent
    s.lineHeightMultiple = `default`.lineHeightMultiple
    try save(s, in: context)
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
      new.textSizeView       = Markdown.textSize
      new.textSizePDF        = Markdown.PDF.textSize
      new.headIndent         = Markdown.headIndent
      new.tailIndent         = -Markdown.tailIndent
      new.lineHeightMultiple = Markdown.lineHeightMultiple
    }
    try? context.save()
    return new
  }
}



// MARK: – SettingsController für Loading, Saving & Restoring
final class SettingsController {
    static let shared = SettingsController()
    private let ctx = Persistence.shared.persistentContainer.viewContext
    
    private(set) var `default`: Settings
    private(set) var active: Settings
    
    private init() {
        // --- Default instanziieren oder laden ---
        let defaultSettings: Settings
        if let def = try? ctx.fetch(Settings.fetchRequest(kind: .default)).first {
            defaultSettings = def
        } else {
            let def = Settings(context: ctx)
            def.kind               = Settings.Kind.default.rawValue
            def.textSizeView       = Markdown.textSize
            def.textSizePDF        = Markdown.PDF.textSize
            def.headIndent         = Markdown.headIndent
            def.tailIndent         = -Markdown.tailIndent
            def.lineHeightMultiple = Markdown.lineHeightMultiple
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
        new.textSizeView       = Markdown.textSize
        new.textSizePDF        = Markdown.PDF.textSize
        new.headIndent         = Markdown.headIndent
        new.tailIndent         = -Markdown.tailIndent
        new.lineHeightMultiple = Markdown.lineHeightMultiple
      }
      try? context.save()
      return new
    }
    
    // Ty­p-Methode, greift nicht auf `self` zu
    private static func copy(from src: Settings, to dst: Settings) {
        dst.textSizeView       = src.textSizeView
        dst.textSizePDF        = src.textSizePDF
        dst.headIndent         = src.headIndent
        dst.tailIndent         = src.tailIndent
        dst.lineHeightMultiple = src.lineHeightMultiple
    }
    
    func apply(_ s: Settings) {
        Markdown.textSize           = s.textSizeView
        Markdown.PDF.textSize       = s.textSizePDF
        Markdown.headIndent         = s.headIndent
        Markdown.tailIndent         = -s.tailIndent
        Markdown.lineHeightMultiple = s.lineHeightMultiple
    }
    
//    func applyActive() {
//        // Werte aus Markdown zurück in active schreiben
//        Markdown.textSize           = active.textSizeView
//        Markdown.PDF.textSize       = active.textSizePDF
//        Markdown.headIndent         = active.headIndent
//        Markdown.tailIndent         = active.tailIndent
//        Markdown.lineHeightMultiple = active.lineHeightMultiple
//    }
    
    // … Deine saveActive() und restoreDefaults() bleiben unverändert …
    
    func saveActive() {
        // Werte aus Markdown zurück in active schreiben
        active.textSizeView       = Markdown.textSize
        active.textSizePDF        = Markdown.PDF.textSize
        active.headIndent         = Markdown.headIndent
        active.tailIndent         = -Markdown.tailIndent
        active.lineHeightMultiple = Markdown.lineHeightMultiple
        try? ctx.save()
    }
    
    func restoreDefaults() {
        // Default → Active kopieren, anwenden und speichern
        Self.copy(from: `default`, to: active)
        apply(active)
        try? ctx.save()
    }
}
