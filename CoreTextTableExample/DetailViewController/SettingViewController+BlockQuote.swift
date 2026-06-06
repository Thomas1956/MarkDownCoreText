//
//  SettingViewController+BlockQuote.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.05.25.
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
    enum BlockQuoteSetting: String, @MainActor BasicDetail, CaseIterable {

        case blockHorizIndent, blockBarIndent, blockContentIndent, blockBarWidth,
             blockVerticalOffset, blockBarStandardColor, blockBarColor,
             blockBackStandardColor, blockBackColor
        
        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .blockHorizIndent:        "Horizontale Einzüge (A)".markdown(size: 15)
            case .blockBarIndent:          "Abstand zum Balken (B)" .markdown(size: 15)
            case .blockContentIndent:      "Abstand zum Inhalt (D)" .markdown(size: 15)
            case .blockBarWidth:           "Balkenbreite (C)"       .markdown(size: 15)
            case .blockVerticalOffset:     "Vertikaler Offset"      .markdown(size: 15)
            case .blockBarStandardColor:   "Standardfarbe"          .markdown(size: 15)
            case .blockBarColor:           "Eigene Farbe"           .markdown(size: 15)
            case .blockBackStandardColor:  "Standardfarbe"          .markdown(size: 15)
            case .blockBackColor:          "Eigene Farbe"           .markdown(size: 15)
            }
        }
                
        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            case .blockHorizIndent, .blockContentIndent:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(80).stepValue(1)
            case .blockBarIndent, .blockVerticalOffset:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(40).stepValue(1)
            case .blockBarWidth:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(30).stepValue(0.5)

            case .blockBarStandardColor, .blockBackStandardColor:
                    .alignLeading
            case .blockBarColor, .blockBackColor:
                    .start
                    .list(self == .blockBarColor ? Settings.blockBarColorPalette : Settings.blockBackColorPalette)
            }
        }
        
        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            case .blockHorizIndent, .blockBarIndent, .blockContentIndent,
                 .blockBarWidth, .blockVerticalOffset: .stepper
            case .blockBarStandardColor, .blockBackStandardColor: .button
            case .blockBarColor, .blockBackColor: .colorpalettewell
            }
        }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionBlockQuoteSetting(_ setting: Settings, forEditing: Bool) {
        typealias Content = BlockQuoteSetting

        let layoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom:  0, trailing: 8)
        let w : CGFloat = 180
        
        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        
        var info1 = "Einzüge".markdown(size: 17, weight: .semibold, textcolor: .textGray).asContentDataLayout()
        info1.layoutMargins = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        items.append(.basic(info1))
        
        /// Zeichnung mit den Maßen für BlockQuote
        let image = UIImage.maßeFürBlockQuote.aspectFillToSize(scaledToFill: CGSize(width: 300, height: 120))
        items.append(.info(" ", image: image))

        items.append(.basic(Content.blockHorizIndent  .line(setting, .rw, labelWidth: w).leadingMargin(10)))
        items.append(.basic(Content.blockContentIndent.line(setting, .rw, labelWidth: w).leadingMargin(10)))
        
        let textBalken = "Balken".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkBalken = BasicType.stdItem(textBalken, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkBalken)
        
        let itemsBalken: [BasicType] = [
            .basic( Content.blockBarIndent       .line(setting, .rw, labelWidth: w)),
            .basic( Content.blockBarWidth        .line(setting, .rw, labelWidth: w)),
            .basic([Content.blockBarStandardColor.line(setting, .rw, contentWidth: 92, labelWidth: w),
                    Content.blockBarColor        .line(setting, .rw, labelWidth: w)]),
        ]

        let textHintergrund = "Hintergrund".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkHintergrund = BasicType.stdItem(textHintergrund, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkHintergrund)
        
        let itemsHintergrund: [BasicType] = [
            .basic( Content.blockVerticalOffset    .line(setting, .rw, labelWidth: w)),
            .basic([Content.blockBackStandardColor .line(setting, .rw, contentWidth: 92, labelWidth: w),
                    Content.blockBackColor         .line(setting, .rw, labelWidth: w)]),
            .vSpace(20),
        ]

        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        dataSource.makeSection(SectionContent.BlockQuoteSetting, items: items.itemType) { snapshot in
            snapshot.append(itemsBalken     .itemType, to: linkBalken     .itemType)
            snapshot.append(itemsHintergrund.itemType, to: linkHintergrund.itemType)
        }
    }
}
