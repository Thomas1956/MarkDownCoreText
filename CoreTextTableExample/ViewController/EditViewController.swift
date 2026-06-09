//
//  EditViewController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 08.05.25.
//

import UIKit
import CoreData
import UniformTypeIdentifiers
import UsefulExtensions


extension UTType {
    /// Eigener Markdown-Typ, an plainText gebunden, damit der Document-Picker
    /// zuverlässig auf die Erweiterung .md filtert.
    static var markdown: UTType {
        UTType(filenameExtension: "md", conformingTo: .plainText) ?? .plainText
    }
}


//--------------------------------------------------------------------------------------------
// MARK: EditViewController

class EditViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    private let keySavedText   = "EditViewController.savedText"
    private let keyColumnWidth = "EditViewController.columnWidth"

    var start : DispatchTime?
    private var temporaryMarkdownExportURL: URL?

    /// Zugehöriger Detail View Contoller
    public lazy var detailViewController: MarkdownViewController? = {
        return splitViewController?.viewController(for: .secondary) as? MarkdownViewController
    }()

    //----------------------------------------------------------------------------------------
    // MARK: - Initialisierung
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.backgroundColor = .systemGray6
        textView.font            = .systemFont(ofSize: Markdown.Edit.textSize)
        textView.textColor       = Markdown.Edit.textColor
        
        self.extendedLayoutIncludesOpaqueBars = true

        if #available(iOS 16, *) {
            navigationItem.style = .navigator
        }
        
        textView.textContainerInset.left = 8
        textView.textContainerInset.right = 8
        textView.delegate = self
        
        let importButton  = ImageBarButtonItem(systemName: "square.and.arrow.down", bottomOffset: 3, action: didPressImportButton(_:))
        let exportButton  = ImageBarButtonItem(systemName: "square.and.arrow.up", bottomOffset: 3, action: didPressExportButton(_:))
        let deleteButton  = ImageBarButtonItem(systemName: "trash", action: didPressDeleteButton(_:))
        let settingButton = ImageBarButtonItem(systemName: "gearshape", action: didPressSettingButton(_:))

        navigationItem.leftBarButtonItems = [settingButton, deleteButton, exportButton, importButton]
        
        /// Auf Hintergrund / Terminate achten und speichern
        NotificationCenter.default.addObserver(self, selector: #selector(saveTextToDefaults),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil )
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /// Gespeicherten Text laden
        loadSavedText()
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Bedienfunktionen
    
    /// Import Markdown Datei
    @objc func didPressImportButton(_ sender: Any) {
        let allowedTypes: [UTType] = [.markdown]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: false)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        picker.directoryURL = MarkdownDocumentLocation.shared.directoryURL
        present(picker, animated: true)
    }
    
    /// Export Markdown Datei
    @objc func didPressExportButton(_ sender: Any) {
        saveMarkdownFile()
    }
    
    /// Löschen des Text View
    @objc func didPressDeleteButton(_ sender: Any) {
        textView.text.removeAll()
        MarkdownDocumentLocation.shared.resetToDefaults()
        detailViewController?.markdown(text: textView.text)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Parameter bearbeiten
    ///
    @objc private func didPressSettingButton(_ sender: Any) {
            
        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = viewContext
        childContext.automaticallyMergesChangesFromParent = true
        
        /// Bei den Settings den  Eintrag 'active' ermitteln und dem View Controller übergeben
        let objectID = SettingsController.shared.activeObjectID
        guard let settings = childContext.object(with: objectID) as? Settings else { return }

        let viewController = SettingViewController(object: settings, title: "Parameter",
            
            ///-------------------------------------------------------------------------------
            /// Änderungen im Live View anzeigen
            ///
            onLiveChange: { [weak self] draftSettings in
                guard let self else { return }
                // Nur LESEN aus dem Child, NICHT speichern:
                SettingsController.apply(draftSettings)
                self.detailViewController?.markdown(text: self.textView.text)
            },
                                                   
           ///-------------------------------------------------------------------------------
           /// OK oder CANCEL beim Abbruch
           ///
           onFinish: { [weak self] shouldSave in
                guard let self else { return }
                if shouldSave {
                    do {
                        /// Zuerst im ChildContext speichern, danach im ViewContext
                        try SettingsController.shared.save(settings, in: childContext)
                        /// Zurückschreiben der Settings in Markdown
                        SettingsController.apply(settings)
                        self.detailViewController?.markdown(text: self.textView.text)
                    }
                    catch {
                        let nserror = error as NSError
                        fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                    }
                }
                else {
                    /// CANCEL: UI auf den Zustand des Parents zurücksetzen
                      if let parentSettings = try? self.viewContext.existingObject(with: objectID) as? Settings {
                          SettingsController.apply(parentSettings)
                          self.detailViewController?.markdown(text: self.textView.text)
                      }
                 }
                self.dismiss(animated: true)
            }
        )
        
        viewController.navigationItem.title = NSLocalizedString("Parameter zufügen",
                                              comment: "Parameter zufügen als Überschrift")
        viewController.preferredContentSize = CGSize(width: 600, height: 720)

        let nav = UINavigationController(rootViewController: viewController)

        if traitCollection.userInterfaceIdiom == .pad {
            /// iPad: Popover über der linken Spalte
            nav.modalPresentationStyle = .popover

            if let popover = nav.popoverPresentationController {
                /// Popover am auslösenden Control verankern.
                if let barButtonItem = sender as? UIBarButtonItem {
                    popover.barButtonItem = barButtonItem
                } else if let sourceView = sender as? UIView {
                    popover.sourceView = sourceView
                    popover.sourceRect = sourceView.bounds
                } else {
                    popover.sourceView = view
                    popover.sourceRect = CGRect(x: view.bounds.midX, y: view.safeAreaInsets.top, width: 1, height: 1)
                }
                popover.permittedArrowDirections = [.up, .down]
            }
        } else {
            /// iPhone: weiter wie bisher (vollflächig)
            nav.modalPresentationStyle = .automatic
            nav.modalTransitionStyle = .coverVertical
        }

        present(nav, animated: true)
    }
}


//--------------------------------------------------------------------------------------------
// MARK: Extension EditViewController

private extension EditViewController {
    
    func saveMarkdownFile() {
        let location = MarkdownDocumentLocation.shared
        let exportURL = location.temporaryMarkdownExportURL
        
        do {
            try FileManager.default.removeItemIfExists(at: exportURL)
            try (textView.text ?? "").write(to: exportURL, atomically: true, encoding: .utf8)
            temporaryMarkdownExportURL = exportURL
            
            let picker = UIDocumentPickerViewController(forExporting: [exportURL], asCopy: true)
            picker.delegate = self
            picker.directoryURL = location.directoryURL
            picker.modalPresentationStyle = .formSheet
            present(picker, animated: true)
        } catch {
            showAlert(title: "Speichern fehlgeschlagen",
                      message: "Markdown-Datei konnte nicht vorbereitet werden:\n\(error.localizedDescription)")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    /// Aktuellen MD-Text in den User-Defaults speichern
    func loadSavedText() {
        if let savedText = UserDefaults.standard.string(forKey: keySavedText) {
            textView.text = savedText
            detailViewController?.markdown(text: textView.text)
        }
        if let columnWidth = UserDefaults.standard.object(forKey: keyColumnWidth) as? CGFloat {
            splitViewController?.preferredPrimaryColumnWidth = columnWidth
        }
    }
    
    /// Aktuellen Text aus den User-Defaults lesen
    @objc func saveTextToDefaults() {
        UserDefaults.standard.set(textView.text, forKey: keySavedText)
        UserDefaults.standard.set(splitViewController?.primaryColumnWidth, forKey: keyColumnWidth)
    }
}


//--------------------------------------------------------------------------------------------
// MARK: UIDocumentPickerDelegate

extension EditViewController: UIDocumentPickerDelegate {
    
    /// Notwendig für das Einlesen einer MD-Datei
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        if let exportURL = temporaryMarkdownExportURL {
            try? FileManager.default.removeItem(at: exportURL)
            temporaryMarkdownExportURL = nil
            MarkdownDocumentLocation.shared.updateLoadedFileURL(url)
            return
        }
        
        do {
            let data = try MarkdownDocumentLocation.shared.access(url: url) { url in
                try Data(contentsOf: url)
            }
            MarkdownDocumentLocation.shared.updateLoadedFileURL(url)
            /// Versuche UTF-8, fallback auf String(decoding:)
            if let str = String(data: data, encoding: .utf8) {
                textView.text = str
            } else {
                textView.text = String(decoding: data, as: UTF8.self)
            }
            detailViewController?.markdown(text: textView.text)
            
        } catch {
            showAlert(title: "Import-Fehler",
                      message: "Datei konnte nicht geladen werden:\n\(error.localizedDescription)")
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        if let url = temporaryMarkdownExportURL {
            try? FileManager.default.removeItem(at: url)
            temporaryMarkdownExportURL = nil
        }
        controller.dismiss(animated: true)
    }
}


//--------------------------------------------------------------------------------------------
// MARK: UITextViewDelegate

extension EditViewController: UITextViewDelegate {
    
    /// Änderungen im Text zur Anzeige im Core Text
    func textViewDidChange(_ textView: UITextView) {
        
        guard let text = textView.text else { return }
        detailViewController?.markdown(text: text)
    }
}
