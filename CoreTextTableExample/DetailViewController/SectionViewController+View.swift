//
//  SectionViewController+View.swift
//  CoreTextTableExample
//
//  Created by Thomas on 23.05.25.
//

import UIKit
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension SectionViewController für den Inhalt einer Sektion

extension SettingViewController  {
    
    //----------------------------------------------------------------------------------------
    // MARK: - Definition der Inhalte einer Sektion

    /// Alle Attribute von BasicDetail sind in der Extension des Protokolls mit Defaultwerten vorbelegt. Demzufolge können alle
    /// standardmäßig genutzten, nicht benötigten Attribute aus dem ENUM gelöscht werden.
    ///
    enum ViewSetting: String, @MainActor BasicDetail, CaseIterable {
 
        /// Die Strings sollen den Namen der Properties entsprechen (Beispiel löschen und EIGENE Case's ergänzen)
        case viewTextSize,
             viewColor, viewSoftBreaks,
             viewLineHeight, viewSpacing, viewSpacingBefore,
             viewHeadIndent, viewTailIndent,
             message

        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .viewTextSize:       "Textgröße"   .markdown(size: 15)
            case .viewColor:          "Textfarbe"   .markdown(size: 15)
            case .viewSoftBreaks:     "Soft-Breaks" .markdown(size: 15)

            case .viewLineHeight:     "Zeilen"      .markdown(size: 15)
            case .viewSpacing:        "nach Absatz" .markdown(size: 15)
            case .viewSpacingBefore:  "vor Absatz"  .markdown(size: 15)

            case .viewHeadIndent:     "Linker Rand" .markdown(size: 15)
            case .viewTailIndent:     "Rechter Rand".markdown(size: 15)
            default: nil
            }
        }
                
        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            case .viewTextSize:
                    .start.fraction(0).symbol("Pt").minimumValue(5).maximumValue(100).stepValue(1)

            case .viewColor:
                    .start.list(Settings.textColorPalette)

            case .viewLineHeight:
                    .start.fraction(2).symbol("").minimumValue(1).maximumValue(5).stepValue(0.1)
            
            case .viewHeadIndent, .viewTailIndent, .viewSpacing, .viewSpacingBefore:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(30).stepValue(1)

            default: .einsNachkomma
            }
        }
        
        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            case .viewHeadIndent, .viewTailIndent, .viewLineHeight,
                 .viewSpacing,    .viewSpacingBefore, .viewTextSize: .stepper
            case .viewSoftBreaks: .button
            case .viewColor:      .colorpalettewell
            default: .number
            }
        }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionViewSetting(_ setting: Settings, forEditing: Bool) {
        typealias Content = ViewSetting
        
        let layoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom:  0, trailing: 8)
        let w : CGFloat = 120

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        
        var info1 = "Schrift".markdown(size: 17, weight: .semibold, textcolor: .textGray).asContentDataLayout()
        info1.layoutMargins = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        items.append(.basic(info1))

        items.append(.basic( Content.viewTextSize  .line(setting, .rw, labelWidth: w).leadingMargin(10)))
        items.append(.basic( Content.viewColor     .line(setting, .rw, labelWidth: w).leadingMargin(10)))
        items.append(.basic( Content.viewSoftBreaks.line(setting, .rw, labelWidth: w).leadingMargin(10)))
        
        let textAbstand = "Abstände".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkAbstand = BasicType.stdItem(textAbstand, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkAbstand)
        
        let itemsAbstand: [BasicType] = [
            .basic( Content.viewLineHeight   .line(setting, .rw, labelWidth: w)),
            .basic( Content.viewSpacing      .line(setting, .rw, labelWidth: w)),
            .basic( Content.viewSpacingBefore.line(setting, .rw, labelWidth: w)),
        ]
        
        let textEinzug = "Einzüge".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkEinzug = BasicType.stdItem(textEinzug, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkEinzug)
        
        let itemsEinzug: [BasicType] = [
            .basic(Content.viewHeadIndent.line(setting, .rw, labelWidth: w)),
            .basic(Content.viewTailIndent.line(setting, .rw, labelWidth: w)),
            .vSpace(20),
        ]

        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        ///
        dataSource.makeSection(SectionContent.ViewSetting, items: items.itemType) { snapshot in
            snapshot.append(itemsAbstand.itemType, to: linkAbstand.itemType)
            snapshot.append(itemsEinzug .itemType, to: linkEinzug .itemType)
        }
    }
}
