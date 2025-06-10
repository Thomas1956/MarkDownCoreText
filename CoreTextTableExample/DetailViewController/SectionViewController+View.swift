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
    enum ViewSettings: String, BasicDetail, CaseIterable {
 
        /// Die Strings sollen den Namen der Properties entsprechen (Beispiel löschen und EIGENE Case's ergänzen)
        case viewHeadIndent, viewTailIndent, viewLineHeight, viewTextSize, viewColor,
             viewSoftBreaks, viewSpacing, viewSpacingBefore,
             viewColorSelect,
             message

        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .viewHeadIndent:    "Linker Einzug"
            case .viewTailIndent:    "Rechter Einzug"
            case .viewLineHeight:    "Zeilenhöhe"
            case .viewTextSize:      "Größe Editor"
            case .viewSoftBreaks:    "Soft-Breaks nutzen"
            case .viewSpacing:       "Abstand nach Absatz"
            case .viewSpacingBefore: "Abstand vor Absatz"
            default: nil
            }
        }
        
        /// Platzhalter bei Texteingaben
        var placeholder: String? {
            switch self {            
            case .viewColorSelect: "Textfarbe auswählen"
            default: nil
            }
        }
                
        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            case .viewSoftBreaks: .alignLeading
            default: .einsNachkomma
            }
        }
        
        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            case .viewSoftBreaks: .button
            default: .number
            }
        }
        
        ///-----------------------------------------------------------------------------------
        /// Textstil und Größen für die Positionierung
        ///
        var textstyle            : UIFont.TextStyle?       { .body }
        var configurationWidth   : CGFloat?                {
            switch self {
            case .viewSoftBreaks : 62.0
            default: nil
            }
        }
        var configurationHeight  : CGFloat?                {  nil  }
        var configurationMargins : NSDirectionalEdgeInsets { .zero }
        
        ///-----------------------------------------------------------------------------------
        /// Zusätzliche Daten für BasicType für  Parametrierungen
        ///
        var image: ImageSourceConvertible? {
            switch self {
            case .viewColorSelect: "paintpalette.fill"
            default: nil
            }
        }
        
        var presentation: ContentPresentation? {       /// Defaultmäßig wird TITLE verwendet
            switch self {
            case .viewColorSelect: .outlineDisclosure
            default: nil
            }
        }

        var widthUsage: WidthUsage?  {
            switch self {
            case .viewSoftBreaks: .content
            default: nil
            }
        }           /// Defaultmäßig wirkt die Breite auf LABEL
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionViewSettings(_ setting: Settings, forEditing: Bool) {
        typealias Content = ViewSettings
        let rwo : ContentRWType = forEditing ? .rw : .ro

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        
        items.append(.basic([Content.viewHeadIndent.data(setting),
                             Content.viewTailIndent.data(setting),
                             Content.viewLineHeight.data(setting),
                            ]))
        
        items.append(.basic([Content.viewSpacing.data(setting),
                             Content.viewSpacingBefore.data(setting),
                            ]))
        
        items.append(.basic([Content.viewTextSize.data(setting)]))
        items.append(.basic([Content.viewSoftBreaks.data(setting, presentation: .line)]))

        let linkColorSelect = BasicType.stdLink(Content.viewColorSelect, type: rwo)
        items.append(linkColorSelect)
        
        
        /// SelectionContentView parametrieren
        let parameter = self.colorSelectContent
        
        let selectionData = ContentData(viewType: .selection, rwo, setting, Content.viewColor.key, parameter: parameter)
        let selectColor = BasicType.basic(ContentDataLayout(selectionData, presentation: .plain))

        items.append(.basic(.lineSpace(height: 8, color: .secondarySystemBackground)))
        items.append(.stdItem(ContentData(key: Content.message.key), height: 80))
         
        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        var sectionSnapshot = SectionSnapshot()
        sectionSnapshot.append(SectionContent.ViewSettings, items: items.itemType)
        sectionSnapshot.append([selectColor.itemType], to: linkColorSelect.itemType)
        dataSource.apply(sectionSnapshot, to: SectionContent.ViewSettings.title, animatingDifferences: true)
    }
}
