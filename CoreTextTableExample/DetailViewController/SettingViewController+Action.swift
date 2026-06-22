//
//  SettingViewController+Action.swift
//  CoreTextTableExample
//
//  Created by Thomas on 09.05.25.
//

import UIKit
import CoreData
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension für Aktionen

extension SettingViewController  {
    
    ///---------------------------------------------------------------------------------------
    /// Action - Teilen und Drucken
    ///
    @objc func actionShare(_ sender: Any?) {
    }
    
    ///---------------------------------------------------------------------------------------
    /// Action - Setzen der Defaultwerte
    ///
    @objc func actionSetDefaults() {
        guard let setting = self.entity else { return }
        
        /// Defaultwerte zurückspeichern
        SettingsController.shared.restoreDefaults(to: setting)
        
        saveButtonState()
        
        /// Rückmeldung über Änderungen für Live Preview
        onLiveChange?(setting)

        var snapshot = self.dataSource.snapshot()
        snapshot.reloadItems(snapshot.itemIdentifiers)
        self.dataSource.apply(snapshot, animatingDifferences: true)
    }

    ///---------------------------------------------------------------------------------------
    /// Action - Bilder-Ordner auswählen (öffnet den Document Picker für Folder).
    ///
    @objc func actionSelectImageFolder() {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        picker.directoryURL = MarkdownDocumentLocation.shared.directoryURL
        imageFolderPickerProxy = ImageFolderPickerProxy { [weak self] url in
            guard let self else { return }
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            MarkdownImageLocation.shared.updateFolderURL(url)
            self.refreshDefaultSettingSection()
        }
        picker.delegate = imageFolderPickerProxy
        present(picker, animated: true)
    }

    ///---------------------------------------------------------------------------------------
    /// Action - Bilder-Ordner entfernen.
    ///
    @objc func actionClearImageFolder() {
        MarkdownImageLocation.shared.clearFolderURL()
        refreshDefaultSettingSection()
    }

    ///---------------------------------------------------------------------------------------
    /// Hilfsmethode:  Die Sichtbarkeit des "Entfernen"-Buttons aktuell sind.
    ///
    private func refreshDefaultSettingSection() {
        
        dataSource.reconfigureIfNeeded([ViewSetting.folderName.key])
        
        if let setting = self.entity {
            onLiveChange?(setting)
        }
    }
}

//--------------------------------------------------------------------------------------------
// MARK: - Delegate-Proxy für den Folder-Picker

/// `UIDocumentPickerDelegate` ist ein `NSObject`-Protokoll. Da `SettingViewController` über
/// CommonCollection bereits andere Delegates verwendet, kapseln wir den Image-Folder-Picker
/// in einem schlanken Proxy, der nur diesen einen Use-Case bedient.
final class ImageFolderPickerProxy: NSObject, UIDocumentPickerDelegate {
    private let onPick: (URL) -> Void
    private let onCancel: () -> Void

    init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void = {}) {
        self.onPick = onPick
        self.onCancel = onCancel
    }

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        onPick(url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onCancel()
    }
}
