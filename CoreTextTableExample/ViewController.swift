//
//  ViewController.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.04.25.
//

import UIKit

class ViewController: UIViewController, UIDocumentPickerDelegate {

    @IBOutlet weak var scrollView: MarkdownScrollView!

    var textSize:CGFloat = 12
    var textColor = UIColor.label

    override func viewDidLoad() {
        super.viewDidLoad()
 
        scrollView.markdown(string: text1, size: textSize, textColor: textColor )
    }
    
    ///---------------------------------------------------------------------------------------
    /// PDF-Export
    ///
    private var tmpPDF: URL?            // <– merken, um später zu löschen

    @IBAction func actionExport(_ sender: Any) {

        // 1) PDF erzeugen → tmpURL zurückgeben
        scrollView.exportPDF { [unowned self] in
            let tmp = FileManager.default
                .temporaryDirectory
                .appendingPathComponent("Markdown")
                .appendingPathExtension("pdf")
            self.tmpPDF = tmp            // merken
            return tmp
        }
        guard let url = tmpPDF else { return }

        // 2) Document-Picker (Export-Modus) anzeigen
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        picker.delegate = self
        picker.modalPresentationStyle = .formSheet
        present(picker, animated: true)
    }

    ///---------------------------------------------------------------------------------------
    // MARK: UIDocumentPickerDelegate
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        if let u = tmpPDF { try? FileManager.default.removeItem(at: u) }
        tmpPDF = nil
    }

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        // Datei wurde kopiert → Temp entfernen
        if let u = tmpPDF { try? FileManager.default.removeItem(at: u) }
        tmpPDF = nil
    }
    
    ///---------------------------------------------------------------------------------------

    
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
        # CommonCollection – Struktur und Nutzung

        ## Einführung
        Das `CommonCollection`-Framework ermöglicht eine dynamische Gestaltung von `UICollectionView`-Elementen durch parametrierbare Datenstrukturen. Im Zentrum stehen `ContentData`, `ContentDataLayout` und `BasicType`, die für die flexible Konfiguration der UI-Elemente verwendet werden.

        ## 1. `ContentData` – Inhalt einer Zelle
        `ContentData` beschreibt den Inhalt einer Zelle in der `UICollectionView`.

        ### **Struktur**
        ```swift
        public struct ContentData {
            var viewType: ContentViewType
            var accessType: ContentRWType
            var value: AnyHashable?
            var key: String
            var title: String?
            var parameter: ContentEditType?
        }
        ```

        ### **Funktion**
        - `viewType`: Gibt an, welcher Inhaltstyp (z. B. `.image`, `.label`, `.text`) angezeigt wird.
        - `accessType`: Legt fest, ob die Daten **nur gelesen** (`ro`), **bearbeitet** (`rw`) oder **als FirstResponder gesetzt** (`rwf`) werden können.
        - `value`: Enthält die eigentlichen Daten.
        - `key`: Identifier für das Content-Element.
        - `title`: Optionaler Titel für die Anzeige.
        - `parameter`: Zusätzliche Parameter, z. B. Alignment oder Formatierungen.

        ### **Beispiel**
        ```swift
        let contentImage = ContentData(viewType: .image, rwo, "Icon-Person".data(using: .utf8), "image", parameter: .alignmentNone)
        ```

        ## 2. `ContentDataLayout` – Positionierung des Inhalts
        `ContentDataLayout` erweitert `ContentData` um Layout-Informationen für die Darstellung.

        ### **Struktur**
        ```swift
        public struct ContentDataLayout {
            var content: ContentData
            var height: CGFloat?
            var width: CGFloat?
            var widthUsage: WidthUsage?
            var layoutMargins: NSDirectionalEdgeInsets
            var presentation: ContentPresentation?
        }
        ```

        ### **Funktion**
        - `content`: Referenz auf ein `ContentData`-Objekt.
        - `height`, `width`: Setzt die Dimensionen des Inhalts.
        - `widthUsage`: Bestimmt die Breitenzuweisung (z. B. `.content`).
        - `layoutMargins`: Steuert Abstände.
        - `presentation`: Gibt an, wie der Inhalt visuell dargestellt wird (`.plain`, `.line`, `.title`).

        ### **Beispiel**
        ```swift
        let layoutImage = ContentDataLayout(contentImage, presentation: .plain, width: 110, widthUsage: .content, height: 110)
        ```

        ### **Diagramm zur Struktur von `ContentDataLayout` und `BasicType`**
        Das folgende Diagramm zeigt die Beziehung zwischen `BasicType.basic` und `ContentDataLayout`:

        ![Struktur von ContentDataLayout und BasicType](diagram_contentdatalayout_basic.png)

        ## 3. `BasicType` – Erstellung des Layouts
        `BasicType` ist ein `enum`, das verschiedene Zellenstrukturen für die `UICollectionView` definiert.

        ### **Cases von `BasicType`**
        ```swift
        public enum BasicType {
            case basic([ContentDataLayout])
            case header(String?)
            case standard(String?, String?, textstyle: UIFont.TextStyle?)
            case infoText(AnyHashable?, UIFont.TextStyle?, lines: Int?, image: UIImage?)
            case lineSpace(CGFloat?, String)
            case plusButton
            case sidebarHeader(String)
            case sidebarStandard(ContentData)
            case linkSelect(ContentRWType, object: AnyHashable, key: String?, placeholder: String?, imagename: String?, color: UIColor?)
            case linkDetail(String, imagename: String?)
            case linkPrint(String)
        }
        ```

        ### **Funktion**
        - `basic`: Eine **Gruppe von `ContentDataLayout`-Objekten**, die zusammen eine Zelle bilden.
        - `header`: Ein **einfacher Header mit Titel**.
        - `standard`: **Zweizeilige Standardzelle** mit optionalem Titel, Untertitel und Schriftstil.
        - `infoText`: Zeigt einen **mehrzeiligen Infotext** mit optionalem Bild.
        - `lineSpace`: Fügt **Abstände** zwischen den Zellen ein.
        - `sidebarHeader`, `sidebarStandard`: Definieren spezielle **Sidebar-Zellen**.
        - `linkSelect`, `linkDetail`, `linkPrint`: **Interaktive Zellen** mit Auswahl- oder Druckfunktion.

        ### **Hierarchische Struktur von `ContentDataLayout`**
        Das folgende Diagramm zeigt, wie `ContentDataLayout` verschachtelte Strukturen für eine flexible UI-Gestaltung ermöglicht:

        ![Beispielhafte Hierarchie von ContentDataLayout](diagram_hierarchie_contentdatalayout.png)

        ### **Parametrierung der `basic`-Case**
        ```swift
        let itemsPerson = [BasicType.basic([layoutImage, [[layoutName, layoutVorname], layoutDatum]])]
        ```
        - Die `basic`-Case erhält eine Liste von `ContentDataLayout`-Elementen.
        - Diese Elemente können **verschachtelt** sein, um z. B. ein **horizontales Layout** für Name und Vorname zu erzeugen.

        ## Fazit
        Die Kombination von `ContentData`, `ContentDataLayout` und `BasicType` ermöglicht eine hochflexible Konfiguration der `UICollectionView`-Zellen, ohne dass für jede Ansicht eigene Zellen implementiert werden müssen.


        """
}

