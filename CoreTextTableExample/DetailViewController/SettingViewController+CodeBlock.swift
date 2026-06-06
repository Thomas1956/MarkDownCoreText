//
//  SettingViewController+CodeBlock.swift
//  CoreTextTableExample
//
//  Created by Thomas on 04.06.26.
//

import UIKit
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension SettingViewController fuer CodeBlock Settings

extension SettingViewController  {
    
    //----------------------------------------------------------------------------------------
    // MARK: - Definition der Inhalte einer Sektion

    enum CodeBlockSetting: String, @MainActor BasicDetail, CaseIterable {

        case codeTextSizeFactor,
             codeBackStandardColor, codeBackColor,
             codeBorderStandardColor, codeBorderColor,
             codeLineHeight, codeSpacing, codeSpacingBefore,
             codeHeadIndent, codeTailIndent
        
        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .codeTextSizeFactor:      "Textfaktor"   .markdown(size: 15)
            case .codeBackStandardColor:   "Standardfarbe".markdown(size: 15)
            case .codeBackColor:           "Eigene Farbe" .markdown(size: 15)
            case .codeBorderStandardColor: "Standardfarbe".markdown(size: 15)
            case .codeBorderColor:         "Eigene Farbe" .markdown(size: 15)
            case .codeLineHeight:          "Zeilen"       .markdown(size: 15)
            case .codeSpacing:             "nach Block"   .markdown(size: 15)
            case .codeSpacingBefore:       "vor Block"    .markdown(size: 15)
            case .codeHeadIndent:          "Linker Rand"  .markdown(size: 15)
            case .codeTailIndent:          "Rechter Rand" .markdown(size: 15)
            }
        }
        
        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            case .codeTextSizeFactor:
                    .start.fraction(0).symbol("%").minimumValue(50).maximumValue(120).stepValue(5)

            case .codeLineHeight:
                    .start.fraction(2).symbol("").minimumValue(0.7).maximumValue(2.0).stepValue(0.05)
            
            case .codeSpacing, .codeSpacingBefore:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(30).stepValue(1)
                
            case .codeHeadIndent, .codeTailIndent:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(80).stepValue(1)
                
            case .codeBackStandardColor, .codeBorderStandardColor:
                    .alignLeading
                
            case .codeBackColor, .codeBorderColor:
                    .start.blockAlignment(.leading)
                    .list(self == .codeBackColor ? Settings.codeBackColorPalette : Settings.codeBorderColorPalette)
            }
        }
        
        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            case .codeTextSizeFactor, .codeLineHeight, .codeSpacing, .codeSpacingBefore,
                 .codeHeadIndent, .codeTailIndent: .stepper
            case .codeBackStandardColor, .codeBorderStandardColor: .button
            case .codeBackColor, .codeBorderColor: .colorpalettewell
            }
        }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    func sectionCodeBlockSetting(_ setting: Settings, forEditing: Bool) {
        typealias Content = CodeBlockSetting
        
        let layoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom:  0, trailing: 8)
        let w : CGFloat = 120

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        
        var info1 = "Schrift".markdown(size: 17, weight: .semibold, textcolor: .textGray).asContentDataLayout()
        info1.layoutMargins = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        items.append(.basic(info1))
        
        items.append(.basic(Content.codeTextSizeFactor.line(setting, .rw, labelWidth: w).leadingMargin(10)))
        
        let textHintergrund = "Hintergrund".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkHintergrund = BasicType.stdItem(textHintergrund, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkHintergrund)
        
        let itemsHintergrund: [BasicType] = [
            .basic([Content.codeBackStandardColor.line(setting, .rw, contentWidth: 37, labelWidth: w),
                    Content.codeBackColor        .line(setting, .rw, labelWidth: 100), HSPACE]),
        ]
        
        let textRahmen = "Rahmen".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkRahmen = BasicType.stdItem(textRahmen, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkRahmen)
        
        let itemsRahmen: [BasicType] = [
            .basic([Content.codeBorderStandardColor.line(setting, .rw, contentWidth: 37, labelWidth: w),
                    Content.codeBorderColor        .line(setting, .rw, labelWidth: 100), HSPACE]),
        ]
        
        let textAbstand = "Abstände".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkAbstand = BasicType.stdItem(textAbstand, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkAbstand)
        
        let itemsAbstand: [BasicType] = [
            .basic(Content.codeLineHeight   .line(setting, .rw, labelWidth: w)),
            .basic(Content.codeSpacing      .line(setting, .rw, labelWidth: w)),
            .basic(Content.codeSpacingBefore.line(setting, .rw, labelWidth: w)),
        ]
        
        let textEinzug = "Einzüge".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkEinzug = BasicType.stdItem(textEinzug, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkEinzug)
        
        let itemsEinzug: [BasicType] = [
            .basic(Content.codeHeadIndent.line(setting, .rw, labelWidth: w)),
            .basic(Content.codeTailIndent.line(setting, .rw, labelWidth: w)),
            .vSpace(20),
        ]

        dataSource.makeSection(SectionContent.CodeBlockSetting, items: items.itemType) { snapshot in
            snapshot.append(itemsHintergrund.itemType, to: linkHintergrund.itemType)
            snapshot.append(itemsRahmen     .itemType, to: linkRahmen     .itemType)
            snapshot.append(itemsAbstand    .itemType, to: linkAbstand    .itemType)
            snapshot.append(itemsEinzug     .itemType, to: linkEinzug     .itemType)
        }
    }
}
