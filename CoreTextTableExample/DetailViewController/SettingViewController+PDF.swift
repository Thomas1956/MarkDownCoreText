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
        case  pdfTextSize, pdfMarginLeft, pdfMarginRight, pdfMarginTop, pdfMarginBottom
        
        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .pdfTextSize:     "Textgröße"   .markdown(size: 15)
            case .pdfMarginLeft:   "Linker Rand" .markdown(size: 15)
            case .pdfMarginRight:  "Rechter Rand".markdown(size: 15)
            case .pdfMarginTop:    "Oberer Rand" .markdown(size: 15)
            case .pdfMarginBottom: "Unterer Rand".markdown(size: 15)
            }
        }
                
        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            case .pdfTextSize:
                    .start.fraction(0).symbol("Pt").minimumValue(5).maximumValue(100).stepValue(1)
 
            case .pdfMarginLeft, .pdfMarginRight, .pdfMarginTop, .pdfMarginBottom:
                    .start.fraction(1).symbol("cm").minimumValue(0).maximumValue(10).stepValue(0.1)
            }
        }
        
        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType { .stepper }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionPdfSetting(_ setting: Settings, forEditing: Bool) {
        typealias C = PdfSettings

        let layoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom:  0, trailing: 8)
        let w : CGFloat = 120

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        
        var info1 = "Schrift".markdown(size: 17, weight: .semibold, textcolor: .textGray).asContentDataLayout()
        info1.layoutMargins = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        items.append(.basic(info1))
        
        items.append(.basic(C.pdfTextSize .line(setting, .rw, labelWidth: w).leadingMargin(10)))
        
        let textRaender = "Seitenränder".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkRaender = BasicType.stdItem(textRaender, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkRaender)
        
        let itemsRaender: [BasicType] = [
            .basic(C.pdfMarginLeft  .line(setting, .rw, labelWidth: w)),
            .basic(C.pdfMarginRight .line(setting, .rw, labelWidth: w)),
            .basic(C.pdfMarginTop   .line(setting, .rw, labelWidth: w)),
            .basic(C.pdfMarginBottom.line(setting, .rw, labelWidth: w)),
            .vSpace(20),
        ]
        
        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        dataSource.makeSection(SectionContent.PdfSetting, items: items.itemType) { snapshot in
            snapshot.append(itemsRaender.itemType, to: linkRaender.itemType)
        }
    }
}
