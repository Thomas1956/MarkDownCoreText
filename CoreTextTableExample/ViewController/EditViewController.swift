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
    /// Eigener Markdown-Typ (fallback auf plainText, wenn’s schiefgeht)
    static var markdown: UTType { UTType(filenameExtension: "md") ?? .plainText }
}


//--------------------------------------------------------------------------------------------
// MARK: EditViewController

class EditViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    private let keySavedText   = "EditViewController.savedText"
    private let keyColumnWidth = "EditViewController.columnWidth"

    var start : DispatchTime?

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

        navigationItem.rightBarButtonItems = [settingButton, deleteButton, exportButton, importButton]
        
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
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    /// Export Markdown Datei
    @objc func didPressExportButton(_ sender: Any) {
        /// Text aus dem UITextView holen
        let text = textView.text ?? ""
        
        /// Temp-URL für die Export-Datei anlegen
        let fileName = "TempMarkdown.md"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            /// Text in die Datei schreiben
            try text.write(to: tempURL, atomically: true, encoding: .utf8)
            
            /// Document Picker zum Exportieren öffnen
            let picker = UIDocumentPickerViewController(
                forExporting: [tempURL],
                asCopy: true
            )
            present(picker, animated: true)
            
        } catch {
            /// Im Fehlerfall einen Alert anzeigen
            let alert = UIAlertController(
                title: "Export fehlgeschlagen",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    /// Löschen des Text View
    @objc func didPressDeleteButton(_ sender: Any) {
        textView.text.removeAll()
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
        viewController.preferredContentSize = CGSize(width: 550, height: 720)

        let nav = UINavigationController(rootViewController: viewController)

        if traitCollection.userInterfaceIdiom == .pad {
            /// iPad: Popover über der linken Spalte
            nav.modalPresentationStyle = .popover

            if let popover = nav.popoverPresentationController {
                popover.sourceView = view   // deine Edit-View im Primary

                /// Anker-Punkt links oben in der Primary-Spalte
                let margin: CGFloat = 16
                let y = view.safeAreaInsets.top    // z.B. unter der NavBar

                popover.sourceRect = CGRect(x: margin, y: y, width: 1, height: 1)
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
        
        /// Falls Sandbox-Scoped: Zugriff anfordern
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            /// Versuche UTF-8, fallback auf String(decoding:)
            if let str = String(data: data, encoding: .utf8) {
                textView.text = str
            } else {
                textView.text = String(decoding: data, as: UTF8.self)
            }
            detailViewController?.markdown(text: textView.text)
            
        } catch {
            /// Fehler anzeigen
            let alert = UIAlertController(
                title: "Import-Fehler",
                message: "Datei konnte nicht geladen werden:\n\(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(.init(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
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
