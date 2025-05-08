//
//  EditViewController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 08.05.25.
//

import UIKit
import UniformTypeIdentifiers
import UsefulExtensions

extension UTType {
    /// Eigener Markdown-Typ (fallback auf plainText, wenn’s schiefgeht)
    static var markdown: UTType {
        UTType(filenameExtension: "md") ?? .plainText
    }
}

class EditViewController: UIViewController {

    @IBOutlet weak var textView: UITextView!
    private let defaultsKey = "EditViewController.savedText"
    
    ///---------------------------------------------------------------------------------------
    /// Zugehöriger Detail View Contoller
    public lazy var detailViewController: CoreTextViewController? = {
        return splitViewController?.viewController(for: .secondary) as? CoreTextViewController
    }()

     
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.view.backgroundColor = .clear
        textView.backgroundColor = .systemGray6
        
        self.extendedLayoutIncludesOpaqueBars = true
//        self.navigationController?.navigationBar.prefersLargeTitles = true

        if #available(iOS 16, *) {
            navigationItem.style = .navigator
        }
        
        textView.textContainerInset.left = 8
        textView.textContainerInset.right = 8
        textView.delegate = self
        
        let addButton    = ImageBarButtonItem(systemName: "plus",  action: didPressImportButton(_:))
        let deleteButton = ImageBarButtonItem(systemName: "trash", action: didPressDeleteButton(_:))
        
        navigationItem.rightBarButtonItems = [deleteButton, addButton]
        
        // 2) Gespeicherten Text laden
        loadSavedText()
        
        // 3) Auf Hintergrund / Terminate achten und speichern
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(saveTextToDefaults),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    @objc func didPressImportButton(_ sender: Any) {
        // Erlaubte Dateitypen: Plain-Text und Markdown
        let allowedTypes: [UTType] = [.plainText, .markdown]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedTypes, asCopy: true)
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }
    
    @objc func didPressDeleteButton(_ sender: Any) {
        textView.text.removeAll()
    }

}


private extension EditViewController {
    
    func loadSavedText() {
        if let saved = UserDefaults.standard.string(forKey: defaultsKey) {
            textView.text = saved
            detailViewController?.markdown(text: textView.text)
        }
    }
    
    @objc func saveTextToDefaults() {
        UserDefaults.standard.set(textView.text, forKey: defaultsKey)
    }
}


// MARK: – UIDocumentPickerDelegate
extension EditViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Falls Sandbox-Scoped: Zugriff anfordern
        let didStart = url.startAccessingSecurityScopedResource()
        defer {
            if didStart {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            // Versuche UTF-8, fallback auf String(decoding:)
            if let str = String(data: data, encoding: .utf8) {
                textView.text = str
            } else {
                textView.text = String(decoding: data, as: UTF8.self)
            }
            detailViewController?.markdown(text: textView.text)
            
        } catch {
            // Fehler anzeigen
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

extension EditViewController: UITextViewDelegate {
    
    ///---------------------------------------------------------------------------------------
    /// Änderungen im Text zur Anzeige im Core Text
    ///
    func textViewDidChange(_ textView: UITextView) {
        
        guard let text = textView.text else { return }
        detailViewController?.markdown(text: text)
    }
    

}
