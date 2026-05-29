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
    enum ViewSettings: String, @MainActor BasicDetail, CaseIterable {
 
        /// Die Strings sollen den Namen der Properties entsprechen (Beispiel löschen und EIGENE Case's ergänzen)
        case viewTextSize, codeTextSizeFactor,
             viewColor, viewSoftBreaks,
             viewLineHeight, viewSpacing, viewSpacingBefore,
             viewHeadIndent, viewTailIndent,
             message

        /// Titel des Items
        var title: TextSourceConvertible? {
            switch self {
            case .viewTextSize:       "Textgröße".markdown(size: 15)
            case .codeTextSizeFactor: "Textfaktor\nCode Block".markdown(size: 15)
            case .viewColor:          "Textfarbe"
            case .viewSoftBreaks:     "Soft-Breaks"

            case .viewLineHeight:     "Zeilen".markdown(size: 15)
            case .viewSpacing:        "nach Absatz".markdown(size: 15)
            case .viewSpacingBefore:  "vor Absatz".markdown(size: 15)

            case .viewHeadIndent:     "Linker Rand".markdown(size: 15)
            case .viewTailIndent:     "Rechter Rand".markdown(size: 15)
            default: nil
            }
        }
        
        /// Platzhalter bei Texteingaben
        var placeholder: String? {
            switch self {            
            default: nil
            }
        }
                
        /// Zusätzliche Parameter, die im Wesentlichen für Images, Selektion, ... benötigt werden.
        var parameter: [KeyText]? {
            switch self {
            case .viewTextSize:
                    .make(alignment: .leading, fraction: 0, symbol: "Pt", minimum: 5.0, maximum: 100.0, stepValue: 1)

            case .codeTextSizeFactor:
                    .make(alignment: .leading, fraction: 0, symbol: "%", minimum: 50, maximum: 120.0, stepValue: 5)

            case .viewColor: .make(list: [
                    /// Optionale Parameter
                    ("chipWidth"      , 80.0                  ),
                    ("backgroundColor", UIColor.systemGray6   ),
                   
                    /// Liste der Farben
                    ("Schwarz"        , UIColor.black         ),
                    ("Dunkelgrau"     , UIColor.textDarkgray  ),
                    ("Grau"           , UIColor.textGray      ),
                    ("Hellgrau"       , UIColor.textLightgray ),
                    ("Blau"           , UIColor.textBlue      ),
                    ("Mint"           , UIColor.textMint      ),
                    ("Grün"           , UIColor.textGreen     ),
                    ("Orange"         , UIColor.textOrange    ),
                    ("Rot"            , UIColor.textRed       ),
                    ("Purpur"         , UIColor.textPurple    ),
                ].keyTextArray)
               
            case .viewSoftBreaks: .alignTrailing

            case .viewLineHeight:
                    .make(alignment: .leading, fraction: 2, symbol: "", minimum: 1.0, maximum: 5.0, stepValue: 0.1)
            
            case .viewHeadIndent, .viewTailIndent, .viewSpacing, .viewSpacingBefore:
                    .make(alignment: .leading, fraction: 1, symbol: "Pt", minimum: 0, maximum: 30, stepValue: 0.5)

            default: .einsNachkomma
            }
        }
        
        /// Konfiguration entsprechend des Datentyps
        var contentViewType: ContentViewType {
            switch self {
            case .viewHeadIndent, .viewTailIndent, .  viewLineHeight,
                 .viewSpacing,    .viewSpacingBefore, .viewTextSize, .codeTextSizeFactor: .stepper
            case .viewColor:      .colorchip
            case .viewSoftBreaks: .button
            default: .number
            }
        }
        
        ///-----------------------------------------------------------------------------------
        /// Textstil und Größen für die Positionierung
        ///
        var textstyle            : UIFont.TextStyle?       { .body }
        var configurationHeight  : CGFloat?                {  nil  }
        var configurationMargins : NSDirectionalEdgeInsets { .zero }
        
        ///-----------------------------------------------------------------------------------
        /// Zusätzliche Daten für BasicType für  Parametrierungen
        ///
        var image: ImageSourceConvertible? {
            switch self {
            default: nil
            }
        }
        
        ///-----------------------------------------------------------------------------------

        var configurationWidth   : CGFloat?                {
            switch self {
            case .viewSoftBreaks : 120.0
//            case .viewTextSize,   .codeTextSizeFactor,
//                 .viewLineHeight, .viewSpacing, .viewSpacingBefore,
//                 .viewHeadIndent, .viewTailIndent
//                : 300.0
            default: nil
            }
        }

        var presentation: ContentPresentation? {       /// Defaultmäßig wird TITLE verwendet
            switch self {
            case .viewSoftBreaks, .viewColor          : .line
//            case .viewTextSize,   .codeTextSizeFactor,
//                 .viewLineHeight, .viewSpacing, .viewSpacingBefore,
//                 .viewHeadIndent, .viewTailIndent
//                : .line
            default: nil
            }
        }

        var widthUsage: WidthUsage?  {
            switch self {
            case .viewSoftBreaks : .container
//            case .viewTextSize,   .codeTextSizeFactor,
//                 .viewLineHeight, .viewSpacing, .viewSpacingBefore,
//                 .viewHeadIndent, .viewTailIndent
//                : .container
            default: nil
            }
        }           /// Defaultmäßig wirkt die Breite auf LABEL
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Den Inhalt der Section zusammenstellen
    
    /// Der Name der Sektion MUSS manuell im SectionContent definiert werden
    func sectionViewSettings(_ setting: Settings, forEditing: Bool) {
        typealias Content = ViewSettings
        
        let layoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 8, bottom:  0, trailing: 8)

        ///-----------------------------------------------------------------------------------
        /// items als BasicType anlegen
        var items = [BasicType]()
        
        var info1 = "Schrift".markdown(size: 17, weight: .semibold, textcolor: .textGray).asContentDataLayout()
        info1.layoutMargins = .init(top: 8, leading: 0, bottom: 8, trailing: 0)
        items.append(.basic(info1))
        
//        let stepper1 = Content.leftIndent .line(person, labelWidth: 120)
//        let stepper2 = Content.rightIndent.line(person, contentWidth: 170, labelWidth: 120)
//        items.append(.basic([stepper1, SPACE, stepper2]))


        items.append(.basic( Content.viewTextSize      .line(setting, contentWidth: 180)))
        items.append(.basic( Content.codeTextSizeFactor.line(setting, contentWidth: 180)))
        items.append(.basic( Content.viewColor         .data(setting)))
        items.append(.basic( Content.viewSoftBreaks    .line(setting, contentWidth: 180)))
        
        let textAbstand = "Abstände".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkAbstand = BasicType.stdItem(textAbstand, presentation: .outlineDisclosure)
        items.append(.lineSpace(height: 6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkAbstand)
        
        let itemsAbstand: [BasicType] = [
            .basic( Content.viewLineHeight   .line(setting, contentWidth: 180)),
            .basic( Content.viewSpacing      .line(setting, contentWidth: 180)),
            .basic( Content.viewSpacingBefore.line(setting, contentWidth: 180)),
        ]
        
        let textEinzug = "Einzüge".markdown(size: 17, weight: .semibold, textcolor: .textGray)
        let linkEinzug = BasicType.stdItem(textEinzug, presentation: .outlineDisclosure)
        items.append(.lineSpace(height: 6, color: .systemGray5, layoutMargins: layoutMargins))
        items.append(linkEinzug)
        
        let itemsEinzug: [BasicType] = [
            .basic(Content.viewHeadIndent.line(setting, contentWidth: 180)),
            .basic(Content.viewTailIndent.line(setting, contentWidth: 180)),
        ]

        ///-----------------------------------------------------------------------------------
        /// Einen Section Snapshot zusammenstellen und der Data Source zuweisen
        ///
        dataSource.makeSection(SectionContent.ViewSettings, items: items.itemType) { snapshot in
            snapshot.append(itemsAbstand.itemType, to: linkAbstand.itemType)
            snapshot.append(itemsEinzug .itemType, to: linkEinzug .itemType)
        }
    }
}
