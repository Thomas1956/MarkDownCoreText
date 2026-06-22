//
//  MarkdownImageLocation.swift
//  CoreTextTableExample
//
//  Created by Thomas on 10.06.26.
//

import Foundation
import UIKit


/// Speichert den vom User gewählten Bilder-Ordner als Security-Scoped Bookmark in
/// `UserDefaults`. Bilder werden ausschließlich aus diesem Ordner geladen.
final class MarkdownImageLocation {
    static let shared = MarkdownImageLocation()

    private let bookmarkKey = "MarkdownImageLocation.bookmark"

    private init() {}

    /// Vom User explizit ausgewählter Bilder-Ordner.
    var folderURL: URL? {
        resolvedStoredURL(key: bookmarkKey)
    }

    func updateFolderURL(_ url: URL) {
        storeBookmark(for: url, key: bookmarkKey)
    }

    func clearFolderURL() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    ///---------------------------------------------------------------------------------------
    /// Sucht eine Datei mit dem angegebenen Bild-Namen im vom User gewählten Bilder-Ordner
    /// (`folderURL`). Falls die Datei keine Endung hat, werden die üblichen Bild-Endungen
    /// probiert.
    func resolveLocalImageURL(named name: String) -> URL? {
        resolvedLocalImage(named: name)?.url
    }

    ///---------------------------------------------------------------------------------------
    /// Lädt das `UIImage` aus dem aufgelösten Pfad mit dem passenden Security-Scope.
    func loadImage(named name: String) -> UIImage? {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              name != "<null>",
              let resolvedImage = resolvedLocalImage(named: name) else { return nil }

        let started = resolvedImage.scopeURL?.startAccessingSecurityScopedResource() ?? false
        defer {
            if started, let scopeURL = resolvedImage.scopeURL {
                scopeURL.stopAccessingSecurityScopedResource()
            }
        }
        return UIImage(contentsOfFile: resolvedImage.url.path)
    }

    //----------------------------------------------------------------------------------------
    // MARK: - Private

    private struct ResolvedImage {
        let url: URL
        let scopeURL: URL?
    }

    private static let extensionFallbacks: [String] = ["png", "jpg", "jpeg", "heic", "gif", "tiff", "bmp"]

    private func resolvedLocalImage(named name: String) -> ResolvedImage? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let folder = folderURL,
              let url = firstExistingFile(in: folder, name: trimmed, scopeURL: folder)
        else { return nil }
        return ResolvedImage(url: url, scopeURL: folder)
    }

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
