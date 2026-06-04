//
//  MarkdownViewController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.04.25.
//

import UIKit
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: MarkdownViewController

class MarkdownViewController: UIViewController, UIDocumentPickerDelegate {

    // MARK: - Views
    private let scrollView  = MarkdownScrollView()
    private let contentView = MarkdownContentView()

    /// Parameter
    var textMarkdown : String  = ""
    
    //----------------------------------------------------------------------------------------
    // MARK: - Initialisierung
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.extendedLayoutIncludesOpaqueBars = true
//        self.navigationController?.navigationBar.prefersLargeTitles = true

        /// Farbe setzen
        self.view  .backgroundColor = .systemGray6.highlight
        contentView.backgroundColor = .systemBackground

        /// Setup der untergeordneten Views
        setupScrollView()
        setupContentView()
       
        /// Button einfügen
        let importButton = ImageBarButtonItem(systemName: "square.and.arrow.up", bottomOffset: 3, action: didPressExportButton(_:))
        self.navigationItem.rightBarButtonItems = [importButton]
        self.navigationItem.style = .navigator

        /// Initialen Text anzeigen
        self.markdown(text: self.textMarkdown)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Markdown-Text darstellen
    ///
    func markdown(text: String) {
        typealias M = Markdown
        self.textMarkdown = text
        scrollView.markdown(string: text, size: M.textSize, weight: .regular, textColor: M.textColor )
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Setup
    
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor     .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor .constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor  .constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func setupContentView() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        NSLayoutConstraint.activate([
            // Festpinnen an Content-Layout-Guide
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            // Breite und horizontale Position über Frame-Layout-Guide
            contentView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 10),
            contentView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -10),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -20)
        ])
    }
    
    ///---------------------------------------------------------------------------------------
    /// PDF-Export
    ///
    private var temporaryPDFExportURL: URL?
    
    @objc func didPressExportButton(_ sender: Any) {
        let renderers = MarkdownParser.markdown(string: self.textMarkdown,
                                                size: Markdown.PDF.textSize,
                                                textColor: Markdown.textColor)
        let location = MarkdownDocumentLocation.shared
        let exportURL = location.temporaryPDFExportURL
        
        do {
            try FileManager.default.removeItemIfExists(at: exportURL)
            try MarkdownParser.exportPDF(renderers: renderers) { exportURL }
            temporaryPDFExportURL = exportURL
            
            let picker = UIDocumentPickerViewController(forExporting: [exportURL], asCopy: true)
            picker.delegate = self
            picker.directoryURL = location.directoryURL
            picker.modalPresentationStyle = .formSheet
            present(picker, animated: true)
        } catch {
            showAlert(title: "PDF-Export fehlgeschlagen",
                      message: "PDF-Datei konnte nicht vorbereitet werden:\n\(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    ///---------------------------------------------------------------------------------------
    // MARK: UIDocumentPickerDelegate
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        if let url = temporaryPDFExportURL {
            try? FileManager.default.removeItem(at: url)
            temporaryPDFExportURL = nil
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        if let url = temporaryPDFExportURL {
            try? FileManager.default.removeItem(at: url)
            temporaryPDFExportURL = nil
        }
    }

    
    let text1 =
    """
    > # Beispiel Blockquote
    
    Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
    Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    
    _______________
    > ## Überschrift 2    
    > Blockquote loorem ipsum dolor sit amet, **consectetur** adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut ~***aliquip***~ ex ea ^[commodo consequat](size:20, weight: 'bold', color: 'orange'). Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
        0 1 2 3 4 5 6 7 8 9     
    > - Erstens Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore 
    > - Zweitens    
    > Ende
    
    0 1 2 3 4
    Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. 
    _______________
    
    # Headline 1-![Circle](HappyBee:70)
    
    ## ![Circle](person.circle:35) Headline 2 

    Here is an [Example Link](https://example.com).

    --------
    
    ^[Lorem ipsum **bold** dolor sit _italic_ amet, -![Trash](trash)- consectetur **adipisicing** elit.](size:22, color: 'orange')

    - List item 1 lorem ipsum dolor sit amet lorem ipsum dolor
    - List item 2 ![Circle](circle)

    ![AppIcon](AppIcon1024:80)
    
    1. List item 1 aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat
    3. List item 2
    1. List item 3

    ### Tabelle
    | Name      | Datum    | Preis       |
    | :--       | :--:     |  ---:       |
    | Socken    | 01.02.24 |     12,34 € |
    | Hose      | 14.06.23 |    654,78 € |
    | Stehlampe | 12.12.21 | 10.543,98 € |

    ### Headline 3

    Ut enim ad `inline code` minim ***bold italic*** veniam, ~strikethrough~ quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

    > Blockquote loorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea ^[commodo consequat](style: 'marked'). Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    
    > Zweite Zeile
    
    jkjkjk

    ```
    5 LET S = 0
    10 MAT INPUT V
    20 LET N = NUM
    30 IF N = 0 ^[THEN](style: 'marked') 99
    40 FOR I = 1 TO N
    45 LET S = S + V(I)
    50 NEXT I
    60 PRINT S/N
    70 GO TO 5
    99 END
    ```

    
    # Beispiel: Farbe und Liste

    Excepteur sint occaecat cupidatat non proident,\
    sunt in culpa qui officia deserunt mollit anim id est laborum. Zeilenende.
    Zeilenanfang. Excepteur sint occaecat cupidatat non proident,\
    sunt in culpa qui officia deserunt mollit anim id est laborum.
    
    ^[Farbe!!! Lorem ipsum bold dolor sit italic amet, consectetur adipisicing elit.](size:22, color: 'orange')

    - List item 1 lorem ipsum dolor sit amet lorem ipsum dolor
    - List item 2 sdd
    - 1986^[.]() Jahreszahl
    - List item 2 sdd

    > Letzter
    
    > Allerletzter
    """


    let text2 =
        """
        1 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident, sunt in culpa qui
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\ 
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\ 
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        
        1 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\ 
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\ 
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

        1 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.\
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.\ 
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
        
        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        1 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        1 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic

        1 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        1 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        1 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic

        1 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        2 Duis  ^[dynamisches Blau](color: 'blue') aecat cupidatat non proident
        
        Duis aute irure dolor in reprehenderit in voluptate velit esse cillum d
        
        Excepteur sint occaecat cupidatat non proident, sunt in culpa qui offic
        
        """
    
        var text3 =
"""
Der Fasan besiedelt halboffene Landschaften, lichte Wälder mit Unterwuchs oder schilfbestandene Feuchtgebiete., die ihm gute Deckung und offene Flächen zur Nahrungssuche bieten. In Europa findet man ihn häufig in der Kulturlandschaft. 
"""
var text31 =
"""
123. Der Fasan besiedelt halboffene Landschaften, lichte Wälder mit Unterwuchs oder schilfbestandene Feuchtgebiete.
"""
    
    var text4 =
"""
In der Nacht zu Samstag ^[dynamisches Blau](color: 'blue') hat ein Geisterfahrer auf der Autobahn A60 einen schweren Verkehrsunfall verursacht. Das Auto des jungen Mannes kollidierte frontal mit einem Pkw, in dem drei junge Frauen saßen. 

Die 23-jährige Fahrerin starb. Ihre beiden 24 Jahre alten Mitfahrerinnen erlitten schwere Verletzungen. Der Falschfahrer zog sich leichte Verletzungen zu. Alle Verletzten wurden den Angaben der Autobahnpolizei in Schweich zufolge in umliegende Krankenhäuser gebracht.

Gegen drei Uhr morgens hätten mehrere Verkehrsteilnehmer einen Falschfahrer auf der A60 bei Landscheid im Kreis Bernkastel-Wittlich über den Notruf gemeldet, erklärte die Polizei laut Nachrichtenagentur dpa. Unter anderem sei eine Meldung dazu im Verkehrswarnfunk eingestellt worden. Kurz darauf sei es zu dem Verkehrsunfall gekommen. Die Autobahn in der Eifel war mehrere Stunden lang gesperrt.

Ein Gutachter soll den genauen Unfallhergang aufklären. Warum der Mann mit seinem Wagen in falscher Richtung auf der Autobahn unterwegs war, war zunächst unklar. Der Polizei zufolge nutzte der Falschfahrer die Fahrbahn Richtung Westen und Belgien, fuhr aber in Richtung Wittlich. Die A60 blieb nach dem Unfall mehrere Stunden lang gesperrt.
"""

    
    var text5 =
"""
**Entwurf eines Einspruchsschreibens mit Antrag auf Aussetzung der Vollziehung**

Absender:  
[Name]  
[Anschrift]  
[Steuernummer / Steuer-ID]

An  
Finanzamt [bitte zuständiges Finanzamt eintragen]  
[Anschrift Finanzamt]

[Ort], [Datum]

**Betreff**: Einspruch gegen die Einkommensteuerbescheide für 2020, 2021 und 2022  
Steuernummer: [bitte Ihre Steuernummer eintragen]

---

Sehr geehrte Damen und Herren,

hiermit lege ich fristgerecht **Einspruch** gegen die Einkommensteuerbescheide für die Veranlagungszeiträume 2020, 2021 und 2022 ein. Zugleich **beantrage ich** die **Aussetzung der Vollziehung** gem. § 361 AO (ggf. § 69 FGO), soweit aus diesen Bescheiden Forderungen herrühren, die infolge der streitigen Punkte entstanden sind.

---

### 1. Einstufung als „Scheinselbständigkeit“

Nach den vorliegenden Bescheiden hat das Finanzamt meine selbständige Tätigkeit ab dem Jahr 2020 als „Scheinselbständigkeit“ eingestuft. Diese Einstufung ist nach meinem Dafürhalten **nicht haltbar** und entbehrt jeder Grundlage.

- Seit **1996** führe ich durchgehend ein **Ingenieurbüro** unter meinem Namen.  
- Im Rahmen meiner Tätigkeit habe ich zahlreiche **unterschiedliche Auftraggeber** aus der Automatisierungs- und Softwarebranche (z. B. Siemens, Lenze, Bosch Rexroth, Beckhoff usw.) betreut.  
- Über den gesamten Zeitraum von 1996 bis 2022 ist ein erheblicher Betrag an **versteuerten Einkünften** (Saldo von 776.000 €) erzielt und ordnungsgemäß gegenüber dem Finanzamt erklärt worden.  
- Die Langfristigkeit und Vielfalt meiner Auftragsstruktur sowie der Abschluss von Wartungsverträgen im Softwarebereich untermauern eine **echte Selbständigkeit**.

Eine Scheinselbständigkeit setzt voraus, dass ein Arbeitnehmerverhältnis verschleiert wird (Fehlen unternehmerischer Risiken, Eingliederung in eine fremde Betriebsorganisation, Weisungsgebundenheit etc.). All diese Kriterien sind in meinem Fall nachweislich nicht erfüllt.

---

### 2. Beantragung der Aussetzung der Vollziehung

Ich beantrage die **Aussetzung der Vollziehung** der angefochtenen Bescheide, bis über meinen Einspruch rechtskräftig entschieden ist. Der Eintritt finanzieller Nachteile durch eine sofortige Vollstreckung wäre für mich unverhältnismäßig und würde mich unter Umständen in erhebliche Liquiditätsschwierigkeiten bringen, zumal ich seit vielen Jahren eine ordnungsgemäß versteuerte selbständige Tätigkeit ausübe.

Die Aussetzung der Vollziehung ist gem. **§ 361 Abs. 2 AO** geboten, da die Erfolgsaussichten des Einspruchs als offen bzw. sehr aussichtsreich anzusehen sind.

---

### 3. Begründung des Einspruchs

- **Selbständige Unternehmensstruktur**  
  - Mehrere unterschiedliche Auftraggeber über viele Jahre.  
  - Langfristige Wartungs- und Supportverträge, z. B. mit Siemens.  
  - Entwicklung und Vertrieb von Software-Komponenten und iOS-Apps, unabhängig von nur einem Auftraggeber.

- **Fehlen arbeitsverhältnisähnlicher Bedingungen**  
  - Keine Eingliederung in einen fremden Betrieb (keine festen Arbeitszeiten, kein Arbeitgeber-Weisungsrecht).  
  - Tragen eines unternehmerischen Risikos, z. B. durch Investitionen (Server, Geräte, Reisekosten, Marketing).  
  - Selbständige Akquise und Abwicklung von Aufträgen.

- **Historie & Prüfung durch andere Stellen**  
  - Seit 1996 wurden regelmäßig Steuererklärungen eingereicht und akzeptiert.  
  - Interne Prüfungen (Internal Audit) bei Siemens stellten keinerlei Interessenkonflikte oder Scheinarrangements fest.

Diese Punkte zeigen eindeutig, dass ich eine **tatsächliche selbständige Tätigkeit** ausübe.

---

### 4. Antrag

- **Aufhebung** bzw. **Anpassung** der Einkommensteuerbescheide für 2020, 2021 und 2022 in Bezug auf die Einstufung als Scheinselbständigkeit.  
- **Aussetzung der Vollziehung** der strittigen Forderungen, bis über den Einspruch unanfechtbar entschieden wurde.

---

### 5. Schlussbemerkung

Ich bitte um eine schriftliche Bestätigung des Eingangs dieses Einspruchs sowie Ihres Bescheids zur Aussetzung der Vollziehung. Für Rückfragen stehe ich selbstverständlich gerne zur Verfügung.

Mit freundlichen Grüßen,

*[Unterschrift]*

**Anlagen** (beispielsweise):
- Nachweise zu Kundenaufträgen (Verträge, Rechnungen)
- Auszüge früherer Steuerbescheide (1996–2019)
- Übersicht über die versteuerten Einkünfte seit 1996
- Wartungsvertrag(e) mit Siemens und andere relevante Verträge
- Schriftstücke aus internen Revisionen/Prüfungen

---

*Hinweis*: Dieses Schreiben stellt einen Musterentwurf dar und ersetzt keine individuelle Rechts- oder Steuerberatung. Es wird empfohlen, das Schreiben gemeinsam mit einer Steuerberaterin/einem Steuerberater oder einer Rechtsanwältin/einem Rechtsanwalt zu prüfen.
"""
}

