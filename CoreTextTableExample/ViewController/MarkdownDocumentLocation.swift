//
//  MarkdownDocumentLocation.swift
//  CoreTextTableExample
//
//  Created by Coding Assistant on 29.05.26.
//

import Foundation

extension FileManager {
    func removeItemIfExists(at url: URL) throws {
        guard fileExists(atPath: url.path) else { return }
        try removeItem(at: url)
    }
}

final class MarkdownDocumentLocation {
    static let shared = MarkdownDocumentLocation()

    private let bookmarkKey = "MarkdownDocumentLocation.bookmark"
    private let fallbackFileName = "Markdown.md"

    private init() {}

    var markdownURL: URL {
        resolvedStoredURL() ?? defaultMarkdownURL
    }

    var pdfURL: URL {
        markdownURL.deletingPathExtension().appendingPathExtension("pdf")
    }
    
    var directoryURL: URL {
        markdownURL.deletingLastPathComponent()
    }
    
    var temporaryMarkdownExportURL: URL {
        temporaryExportURL(for: markdownURL)
    }
    
    var temporaryPDFExportURL: URL {
        temporaryExportURL(for: pdfURL)
    }

    func updateLoadedFileURL(_ url: URL) {
        storeBookmark(for: url)
    }

    func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: bookmarkKey)
    }

    func accessMarkdownURL<T>(_ body: (URL) throws -> T) rethrows -> T {
        try access(url: markdownURL, body)
    }

    func accessPDFURL<T>(_ body: (URL) throws -> T) rethrows -> T {
        let sourceURL = markdownURL
        let targetURL = pdfURL
        let didStartSource = sourceURL.startAccessingSecurityScopedResource()
        let didStartTarget = targetURL.startAccessingSecurityScopedResource()
        defer {
            if didStartTarget {
                targetURL.stopAccessingSecurityScopedResource()
            }
            if didStartSource {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        return try body(targetURL)
    }

    private var defaultMarkdownURL: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return directory.appendingPathComponent(fallbackFileName)
    }
    
    private func temporaryExportURL(for targetURL: URL) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(targetURL.lastPathComponent)
    }

    private func storeBookmark(for url: URL) {
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
            UserDefaults.standard.set(data, forKey: bookmarkKey)
        } catch {
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
        }
    }

    private func resolvedStoredURL() -> URL? {
        guard let data = UserDefaults.standard.data(forKey: bookmarkKey) else { return nil }

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
            if isStale {
                storeBookmark(for: url)
            }
            return url
        } catch {
            UserDefaults.standard.removeObject(forKey: bookmarkKey)
            return nil
        }
    }

    func access<T>(url: URL, _ body: (URL) throws -> T) rethrows -> T {
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }
        return try body(url)
    }
}
