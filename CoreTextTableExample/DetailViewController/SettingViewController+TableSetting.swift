//
//  SettingViewController+TableSetting.swift
//  CoreTextTableExample
//
//  Created by Thomas on 08.06.26.
//

import UIKit
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension SettingViewController für die Tabellen-Farben

extension SettingViewController  {

    //----------------------------------------------------------------------------------------
    // MARK: - Definition der Inhalte einer Sektion

    enum TableSetting: String, @MainActor BasicDetail, CaseIterable {

        case tableIndentLeft, tableIndentRight,
             tableUseDefaultGridColor,            tableGridColor,
             tableUseDefaultHeaderBackgroundColor, tableHeaderBackgroundColor,
             tableUseDefaultBackgroundColor,       tableBackgroundColor

        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .tableIndentLeft:                      "Linker Einzug" .markdown(size: 15)
            case .tableIndentRight:                     "Rechter Einzug".markdown(size: 15)
            case .tableUseDefaultGridColor:             "Standardfarbe" .markdown(size: 15)
            case .tableGridColor:                       "Eigene Farbe"  .markdown(size: 15)
            case .tableUseDefaultHeaderBackgroundColor: "Standardfarbe" .markdown(size: 15)
            case .tableHeaderBackgroundColor:           "Eigene Farbe"  .markdown(size: 15)
            case .tableUseDefaultBackgroundColor:       "Standardfarbe" .markdown(size: 15)
            case .tableBackgroundColor:                 "Eigene Farbe"  .markdown(size: 15)
            }
        }

        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            case .tableIndentLeft, .tableIndentRight:
                    .start.fraction(1).symbol("Pt").minimumValue(0).maximumValue(80).stepValue(1)

            case .tableUseDefaultGridColor,
                 .tableUseDefaultHeaderBackgroundColor,
                 .tableUseDefaultBackgroundColor:
                    .alignLeading

            case .tableGridColor:
                    .start.blockAlignment(.leading).list(Settings.tableGridColorPalette)
            case .tableHeaderBackgroundColor:
                    .start.blockAlignment(.leading).list(Settings.tableHeaderBackgroundColorPalette)
            case .tableBackgroundColor:
                    .start.blockAlignment(.leading).list(Settings.tableBackgroundColorPalette)
            }
        }

        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            case .tableIndentLeft, .tableIndentRight: .stepper
            case .tableUseDefaultGridColor,
                 .tableUseDefaultHeaderBackgroundColor,
                 .tableUseDefaultBackgroundColor: .button
            case .tableGridColor,
                 .tableHeaderBackgroundColor,
                 .tableBackgroundColor: .colorpalettewell
            }
        }
    }

    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen

    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionTableSetting(_ setting: Settings, forEditing: Bool) {
        typealias Content = TableSetting

        let layoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom:  0, trailing: 8)
        let w : CGFloat = 120

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()

        var info1 = "Einzüge".markdown(size: 17, weight: .semibold, textcolor: .textGray).asContentDataLayout()
        info1.layoutMargins = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        items.append(.basic(info1))

        items.append(.basic(Content.tableIndentLeft  .line(setting, .rw, labelWidth: w).leadingMargin(10)))
        items.append(.basic(Content.tableIndentRight .line(setting, .rw, labelWidth: w).leadingMargin(10)))

        let textGitter = "Gitterlinien".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkGitter = BasicType.stdItem(textGitter, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkGitter)

        let itemsGitter: [BasicType] = [
            .basic([Content.tableUseDefaultGridColor.line(setting, .rw, contentWidth: 37, labelWidth: w),
                    Content.tableGridColor          .line(setting, .rw, labelWidth: 100), HSPACE]),
        ]

        let textHeader = "Header-Hintergrund".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkHeader = BasicType.stdItem(textHeader, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkHeader)

        let itemsHeader: [BasicType] = [
            .basic([Content.tableUseDefaultHeaderBackgroundColor.line(setting, .rw, contentWidth: 37, labelWidth: w),
                    Content.tableHeaderBackgroundColor          .line(setting, .rw, labelWidth: 100), HSPACE]),
        ]

        let textBody = "Body-Hintergrund".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkBody = BasicType.stdItem(textBody, presentation: .outlineDisclosure)
        items.append(.vDivider(6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkBody)

        let itemsBody: [BasicType] = [
            .basic([Content.tableUseDefaultBackgroundColor.line(setting, .rw, contentWidth: 37, labelWidth: w),
                    Content.tableBackgroundColor          .line(setting, .rw, labelWidth: 100), HSPACE]),
            .vSpace(20),
        ]

        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        dataSource.makeSection(SectionContent.TableSetting, items: items.itemType) { snapshot in
            snapshot.append(itemsGitter.itemType, to: linkGitter.itemType)
            snapshot.append(itemsHeader.itemType, to: linkHeader.itemType)
            snapshot.append(itemsBody  .itemType, to: linkBody  .itemType)
        }
    }
}
