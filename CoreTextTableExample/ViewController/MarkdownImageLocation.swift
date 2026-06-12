//
//  MarkdownImageLocation.swift
//  CoreTextTableExample
//
//  Created by Thomas on 10.06.26.
//

import Foundation
import UIKit


/// Speichert den vom User gewählten Bilder-Ordner als Security-Scoped Bookmark in
/// `UserDefaults`. Zusätzlich wird beim Öffnen einer Markdown-Datei der Eltern-Folder
/// (so weit das System es erlaubt) automatisch als zweiter Bookmark erfasst – damit
/// Bilder neben der `.md`-Datei ohne separaten Folder-Picker funktionieren.
///
/// Such-Reihenfolge in `resolveLocalImageURL`:
///   1. Diagnose-Override (`debugOverrideFolder`)
///   2. Automatisch erfasstes Eltern-Verzeichnis (`documentFolderURL`)
///   3. Vom User explizit gewählter Bilder-Ordner (`folderURL`)
final class MarkdownImageLocation {
    static let shared = MarkdownImageLocation()

    private let bookmarkKey       = "MarkdownImageLocation.bookmark"
    private let documentFolderKey = "MarkdownImageLocation.documentFolderBookmark"

    /// Diagnose-Override: wenn gesetzt, wird dieser Pfad als erster Such-Folder verwendet
    /// und das Security-Scoping wird übersprungen. Funktioniert auf Catalyst nur, wenn die
    /// App-Sandbox den Pfad explizit erlaubt – sonst liefert `UIImage` nil mit
    /// "Operation not permitted". Default `nil`; nur für Tests setzen.
    var debugOverrideFolder: URL?

    private init() {}

    /// Vom User explizit ausgewählter Bilder-Ordner.
    var folderURL: URL? {
        resolvedStoredURL(key: bookmarkKey)
    }

    /// Automatisch beim Öffnen der `.md`-Datei gespeicherter Folder-Bookmark des
    /// Eltern-Verzeichnisses.
    var documentFolderURL: URL? {
        resolvedStoredURL(key: documentFolderKey)
    }

    func updateFolderURL(_ url: URL) {
        storeBookmark(for: url, key: bookmarkKey)
    }

    func clearFolderURL() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    ///---------------------------------------------------------------------------------------
    /// Versucht, das Eltern-Verzeichnis der angegebenen `.md`-Datei als Folder-Bookmark
    /// zu speichern. Auf macOS Catalyst mit `withSecurityScope`. Falls das System keinen
    /// Folder-Bookmark erlaubt (typisch bei iCloud-Drive ohne Folder-Picker), bleibt der
    /// alte Wert erhalten und der User muss manuell einen Bilder-Ordner setzen.
    func captureFolder(forDocumentAt url: URL) {
        let folder = url.deletingLastPathComponent()
        let started = url.startAccessingSecurityScopedResource()
        defer { if started { url.stopAccessingSecurityScopedResource() } }

        do {
            #if targetEnvironment(macCatalyst)
            let data = try folder.bookmarkData(options: [.withSecurityScope],
                                               includingResourceValuesForKeys: nil,
                                               relativeTo: nil)
            #else
            let data = try folder.bookmarkData(options: [],
                                               includingResourceValuesForKeys: nil,
                                               relativeTo: nil)
            #endif
            UserDefaults.standard.set(data, forKey: documentFolderKey)
        } catch {
            // Schweigend übergehen – Status quo.
        }
    }

    ///---------------------------------------------------------------------------------------
    /// Sucht eine Datei mit dem angegebenen Bild-Namen in der Reihenfolge:
    ///   1. `debugOverrideFolder` (ohne Scope, zum Testen)
    ///   2. `documentFolderURL` (automatisch erfasstes Eltern-Verzeichnis der `.md`-Datei)
    ///   3. `folderURL` (vom User explizit gewählter Bilder-Ordner)
    /// Falls die Datei keine Endung hat, werden die üblichen Bild-Endungen probiert.
    func resolveLocalImageURL(named name: String) -> URL? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let override = debugOverrideFolder,
           let url = firstExistingFile(in: override, name: trimmed, scopeURL: nil) {
            return url
        }
        if let docFolder = documentFolderURL,
           let url = firstExistingFile(in: docFolder, name: trimmed, scopeURL: docFolder) {
            return url
        }
        if let folder = folderURL,
           let url = firstExistingFile(in: folder, name: trimmed, scopeURL: folder) {
            return url
        }
        return nil
    }

    ///---------------------------------------------------------------------------------------
    /// Lädt das `UIImage` aus dem aufgelösten Pfad mit dem passenden Security-Scope.
    func loadImage(named name: String) -> UIImage? {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name != "<null>",
              let url = resolveLocalImageURL(named: name) else { return nil }

        if let override = debugOverrideFolder, url.path.hasPrefix(override.path) {
            return UIImage(contentsOfFile: url.path)
        }
        if let docFolder = documentFolderURL, url.path.hasPrefix(docFolder.path) {
            let started = docFolder.startAccessingSecurityScopedResource()
            defer { if started { docFolder.stopAccessingSecurityScopedResource() } }
            return UIImage(contentsOfFile: url.path)
        }
        if let folder = folderURL, url.path.hasPrefix(folder.path) {
            let started = folder.startAccessingSecurityScopedResource()
            defer { if started { folder.stopAccessingSecurityScopedResource() } }
            return UIImage(contentsOfFile: url.path)
        }
        return UIImage(contentsOfFile: url.path)
    }

    //----------------------------------------------------------------------------------------
    // MARK: - Private

    private static let extensionFallbacks: [String] = ["png", "jpg", "jpeg", "heic", "gif", "tiff", "bmp"]

    private func firstExistingFile(in base: URL, name: String, scopeURL: URL?) -> URL? {
        let started = scopeURL?.startAccessingSecurityScopedResource() ?? false
        defer { if started, let scopeURL { scopeURL.stopAccessingSecurityScopedResource() } }

        let direct = base.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: direct.path) { return direct }

        guard direct.pathExtension.isEmpty else { return nil }
        for ext in Self.extensionFallbacks {
            let candidate = direct.appendingPathExtension(ext)
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        }
        return nil
    }

    private func storeBookmark(for url: URL, key: String) {
        do {
            #if targetEnvironment(macCatalyst)
            let data = try url.bookmarkData(options: [.withSecurityScope],
                                            includingResourceValuesForKeys: nil,
                                            relativeTo: nil)
            #else
            let data = try url.bookmarkData(options: [],
                                            includingResourceValuesForKeys: nil,
                                            relativeTo: nil)
            #endif
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    private func resolvedStoredURL(key: String) -> URL? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            var isStale = false
            #if targetEnvironment(macCatalyst)
            let url = try URL(resolvingBookmarkData: data,
                              options: [.withSecurityScope],
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            #else
            let url = try URL(resolvingBookmarkData: data,
                              options: [],
                              relativeTo: nil,
                              bookmarkDataIsStale: &isStale)
            #endif
            if isStale { storeBookmark(for: url, key: key) }
            return url
        } catch {
            UserDefaults.standard.removeObject(forKey: key)
            return nil
        }
    }
}
