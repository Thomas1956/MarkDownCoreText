//
//  SettingViewController+RulerSetting.swift
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
    enum RulerSetting: String, @MainActor BasicDetail, CaseIterable {

        case rulerHeight, rulerLineHeight, rulerLeftIndent, rulerRightIndent,
             rulerUseHighlightColor, rulerColor

        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .rulerHeight:            "Höhe des Absatzes"
            case .rulerLineHeight:        "Höhe des Trennstriches"
            case .rulerLeftIndent:        "Linker Abstand"
            case .rulerRightIndent:       "Rechter Abstand"
            case .rulerUseHighlightColor: "Standardfarbe"
            case .rulerColor:             "Eigene Farbe"
            }
        }

        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            case .rulerHeight:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(30).stepValue(0.5)
            case .rulerLineHeight:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(30).stepValue(0.5)
            case .rulerLeftIndent, .rulerRightIndent:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(80).stepValue(1)

            case .rulerUseHighlightColor: .alignLeading
            case .rulerColor: .start.blockAlignment(.leading).list(Settings.rulerColorPalette)
            }
        }

        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            case .rulerHeight, .rulerLineHeight, .rulerLeftIndent, .rulerRightIndent: .stepper
            case .rulerUseHighlightColor: .button
            case .rulerColor: .colorpalettewell
            }
        }
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionRulerSetting(_ setting: Settings, forEditing: Bool) {
        typealias Content = RulerSetting

        let w : CGFloat = 120

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        
        var info1 = "Trennlinie".markdown(size: 17, weight: .semibold, textcolor: .textGray).asContentDataLayout()
        info1.layoutMargins = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        items.append(.basic(info1))
        
        items.append(.basic( Content.rulerHeight     .line(setting, .rw, labelWidth: w)))
        items.append(.basic( Content.rulerLineHeight .line(setting, .rw, labelWidth: w)))
        items.append(.basic( Content.rulerLeftIndent .line(setting, .rw, labelWidth: w)))
        items.append(.basic( Content.rulerRightIndent.line(setting, .rw, labelWidth: w)))
        items.append(.basic([Content.rulerUseHighlightColor.line(setting, .rw, contentWidth: 37, labelWidth: w),
                             Content.rulerColor            .line(setting, .rw, labelWidth: 100), HSPACE]))

        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        dataSource.makeSection(SectionContent.RulerSetting, items: items.itemType)
    }
}
