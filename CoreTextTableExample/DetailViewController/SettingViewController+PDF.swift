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
    enum PdfSettings: String, @MainActor BasicDetail, CaseIterable {
        case  pdfTextSize, pdfTextColor, pdfMarginLeft, pdfMarginRight, pdfMarginTop, pdfMarginBottom,
              pdfColorSelect
        
        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .pdfTextSize:     "Textgröße".markdown(size: 15)
            case .pdfTextColor:    "Textfarbe"
            case .pdfMarginLeft:   "Linker Rand".markdown(size: 15)
            case .pdfMarginRight:  "Rechter Rand".markdown(size: 15)
            case .pdfMarginTop:    "Oberer Rand".markdown(size: 15)
            case .pdfMarginBottom: "Unterer Rand".markdown(size: 15)
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
        var parameter: [KeyText]? {
            switch self {
            case .pdfTextSize:
                    .start.blockAlignment(.leading).fraction(0).symbol("Pt")
                    .minimumValue(5.0).maximumValue(100.0).stepValue(1)
 
            case .pdfMarginLeft, .pdfMarginRight, .pdfMarginTop, .pdfMarginBottom:
                    .start.blockAlignment(.leading).fraction(1).symbol("cm")
                    .minimumValue(0).maximumValue(10.0).stepValue(0.1)

            case .pdfTextColor:
                    .start.chipWidth(80).backgroundColor(.systemGray6)
                    .list(Settings.textColorPalette)

            default: .editClear
            }
        }
        
        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            case .pdfTextSize,  .pdfMarginLeft, .pdfMarginRight,
                 .pdfMarginTop, .pdfMarginBottom: .stepper
            case .pdfTextColor: .colorchip
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
        
//        var presentation: ContentPresentation? {       /// Defaultmäßig wird TITLE verwendet
//            switch self {
//            case .pdfTextColor: .line
//            case .pdfColorSelect: .outlineDisclosure
//            default: nil
//            }
//        }
//
//        var widthUsage: WidthUsage?  { nil }           /// Defaultmäßig wirkt die Breite auf LABEL
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionPdfSettings(_ setting: Settings, forEditing: Bool) {
        typealias C = PdfSettings

        let layoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom:  0, trailing: 8)
        
        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        
        var info1 = "Schrift".markdown(size: 17, weight: .semibold, textcolor: .textGray).asContentDataLayout()
        info1.layoutMargins = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        items.append(.basic(info1))
        
        items.append(.basic(C.pdfTextSize .line(setting, .rw, labelWidth: 120)))
        items.append(.basic(C.pdfTextColor.line(setting, .rw, labelWidth: 120)))
        
        let textRaender = "Seitenränder".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkRaender = BasicType.stdItem(textRaender, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkRaender)
        
        let itemsRaender: [BasicType] = [
            .basic(C.pdfMarginLeft  .line(setting, .rw, labelWidth: 120)),
            .basic(C.pdfMarginRight .line(setting, .rw, labelWidth: 120)),
            .basic(C.pdfMarginTop   .line(setting, .rw, labelWidth: 120)),
            .basic(C.pdfMarginBottom.line(setting, .rw, labelWidth: 120)),
        ]
        
        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        dataSource.makeSection(SectionContent.PdfSettings, items: items.itemType) { snapshot in
            snapshot.append(itemsRaender.itemType, to: linkRaender.itemType)
        }
    }
}
