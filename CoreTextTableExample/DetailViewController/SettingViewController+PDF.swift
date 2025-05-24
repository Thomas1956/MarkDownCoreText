//
//  SettingViewController+PDF.swift
//  CoreTextTableExample
//
//  Created by Thomas on 22.05.25.
//

import UIKit
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension SettingViewController für den Inhalt einer Sektion

extension SettingViewController  {
    
    //----------------------------------------------------------------------------------------
    // MARK: - Definition der Inhalte einer Sektion

    /// Alle Attribute von BasicDetail sind in der Extension des Protokolls mit Defaultwerten vorbelegt. Demzufolge können alle
    /// standardmäßig genutzten, nicht benötigten Attribute aus dem ENUM gelöscht werden.
    ///
    enum PdfSettings: String, BasicDetail, CaseIterable {
        case  pdfTextSize, pdfTextColor, pdfMarginLeft, pdfMarginRight, pdfMarginTop, pdfMarginBottom,
              pdfColorSelect
        
        /// Titel des Items
        var title: AnyHashable? {
            switch self {
            case .pdfTextSize:     "Textgröße"
            case .pdfTextColor:    "Textfarbe"
            case .pdfMarginLeft:   "Linker Rand"
            case .pdfMarginRight:  "Rechter Rand"
            case .pdfMarginTop:    "Oberer Rand"
            case .pdfMarginBottom: "Unterer Rand"
             default: nil
            }
        }
        
        /// Platzhalter bei Texteingaben
        var placeholder: String? {
            switch self {
            case .pdfColorSelect: "Textfarbe auswählen"
            default: nil
            }
        }
                
        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: ContentEditType? {
            switch self {
            case .pdfMarginLeft, .pdfMarginRight, .pdfMarginTop, .pdfMarginBottom:
                     .einsNachkomma
            default: .editClear
            }
        }
        
        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            case .pdfMarginLeft, .pdfMarginRight, .pdfMarginTop, .pdfMarginBottom:
                     .zentimeter
            default: .number
            }
        }
        
        ///-----------------------------------------------------------------------------------
        /// Textstil und Größen für die Positionierung
        ///
        var textstyle            : UIFont.TextStyle?       { .body }
        var configurationWidth   : CGFloat?                {  nil  }
        var configurationHeight  : CGFloat?                {  nil  }
        var configurationMargins : NSDirectionalEdgeInsets { .zero }
        
        ///-----------------------------------------------------------------------------------
        /// Zusätzliche Daten für BasicType für  Parametrierungen
        ///
        var image: ImageSourceConvertible? {
            switch self {
            case .pdfColorSelect: "paintpalette.fill"
            default: nil
            }
        }
        
        var presentation: ContentPresentation? {       /// Defaultmäßig wird TITLE verwendet
            switch self {
            case .pdfColorSelect: .outlineDisclosure
            default: nil
            }
        }

        var widthUsage: WidthUsage?  { nil }           /// Defaultmäßig wirkt die Breite auf LABEL
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionPdfSettings(_ setting: Settings, forEditing: Bool) {
        typealias C = PdfSettings
        let rwo : ContentRWType = forEditing ? .rw : .ro

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        items.append(.basic(C.pdfTextSize.data(setting)))
        
        items.append(.basic([C.pdfMarginLeft  .data(setting),
                             C.pdfMarginRight .data(setting),
                             C.pdfMarginTop   .data(setting),
                             C.pdfMarginBottom.data(setting),
                            ]))
        
        let linkColorSelect = BasicType.stdLink(C.pdfColorSelect, type: rwo)
        items.append(linkColorSelect)
        
        
        /// SelectionContentView parametrieren
        let parameter = ContentEditType(style: nil, list: self.colorSelectContent)
        
        let selectionData = ContentData(viewType: .selection, rwo, setting, C.pdfTextColor.key, parameter: parameter)
        let selectColor = BasicType.basic(ContentDataLayout(selectionData, presentation: .plain))

        
        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        var sectionSnapshot = SectionSnapshot()
        sectionSnapshot.append(SectionContent.pdfSettings, items: items.itemType)
        sectionSnapshot.append([selectColor.itemType], to: linkColorSelect.itemType)
        dataSource.apply(sectionSnapshot, to: SectionContent.pdfSettings.title, animatingDifferences: true)
    }
}
