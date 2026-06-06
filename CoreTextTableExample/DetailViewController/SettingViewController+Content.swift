//
//  SettingViewController+Content.swift
//  CoreTextTableExample
//
//  Created by Thomas on 09.05.25.
//

import UIKit
import CommonCollection
import UsefulExtensions


//--------------------------------------------------------------------------------------------
// MARK: - Extension für Inhalt der Sektionen und Zeilen

extension SettingViewController  {
    
    //----------------------------------------------------------------------------------------
    // MARK: - Definition der Sektionen
    
    enum SectionContent: String, BasicSection, CaseIterable {
        case ViewSetting, PdfSetting, BlockQuoteSetting, CodeBlockSetting, RulerSetting, DefaultSetting, HelpSetting
        
        var title : String {
            switch self {
            case .ViewSetting:       "Anzeige"
            case .PdfSetting:        "PDF"
            case .BlockQuoteSetting: "Block"
            case .CodeBlockSetting:  "Code"
            case .RulerSetting:      "Ruler"
            case .DefaultSetting:    "Drucken"
            case .HelpSetting:       "Hilfe"
            }
        }
        
        var appearance: UICollectionLayoutListConfiguration.Appearance {
            switch self {
            default: .insetGrouped
            }
        }
        
        var headerMode: UICollectionLayoutListConfiguration.HeaderMode {
            switch self {
            default: .none
            }
        }
        
        var showsSeparators: Bool {
            switch self {
            default: false
            }
        }
        
        var trailingSwipeActionsConfigurationProvider: UICollectionLayoutListConfiguration.SwipeActionsConfigurationProvider? {
            switch self {
            default: nil
            }
        }
    }
}

