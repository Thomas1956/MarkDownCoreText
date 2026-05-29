//
//  MarkdownParser+PresentationIntent.swift
//  MarkdownParser
//
//  Created by Thomas on 19.10.24.
//

import UIKit

//--------------------------------------------------------------------------------------------
// MARK: - Extension PresentationIntent

extension AttributeScopes.FoundationAttributes.PresentationIntentAttribute.Value {
    
    /// Indentity des Blocks, die verschiedenen Einträgen zugeordnet sein kann
    var blockIdentity: (kind: PresentationIntent.Kind, identity: Int)? { // TODO: Typo -> blockIdentity
        let identity: [(PresentationIntent.Kind, Int)] = self.components.compactMap( { intent in
            if case .header        = intent.kind { return (intent.kind, intent.identity) }
            if case .blockQuote    = intent.kind { return (intent.kind, intent.identity) }
            if case .codeBlock     = intent.kind { return (intent.kind, intent.identity) }
            if case .thematicBreak = intent.kind { return (intent.kind, intent.identity) }
            if case .paragraph     = intent.kind { return (intent.kind, intent.identity) }
            if case .table         = intent.kind { return (intent.kind, intent.identity) }
            return nil
        })
        return identity.first ?? nil
    }
    
    ///---------------------------------------------------------------------------------------
    /// P A R A G R A P H
    ///
    var hasParagraph: Bool {
        return self.components.contains(where: { $0.kind == .paragraph})
    }

    ///---------------------------------------------------------------------------------------
    /// T H E M A T I C   B R E A K   und   C O D E   B L O C K
    ///
    /// Ist ein Thematic Break in den Components des Presentation Intent  vorhanden ?
    var hasThematicBreak: Bool {
        return self.components.contains(where: { $0.kind == .thematicBreak})
    }
    
    /// Ist ein Code Block in den Components des Presentation Intent  vorhanden ?
    var hasCodeBlock: Bool {
        self.components.contains(where: { component in
            if case .codeBlock(_) = component.kind { return true }
            return false
        })
    }
    
    /// Wenn es einen Code Block gibt, dann den Language Hint zurückgeben (sonst NIL)
    var languageHint: String? {
        self.components.compactMap( { component in
            if case .codeBlock(let languageHint) = component.kind { return languageHint }
            return nil
        }).first
    }
    
    /// Gerätespezifischen Font für den Level des Header zurückgeben
    func codeBlockFont(baseBodySize: CGFloat? = nil) -> UIFont {
        let codeSize = 0.9 * (baseBodySize ?? UIFont.preferredFont(forTextStyle: .body).pointSize)
 
        /// Monospaced Font holen und skalieren
        let baseCodeFont = UIFont.monospacedSystemFont(ofSize: codeSize, weight: .regular)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: baseCodeFont)
    }
    
    ///---------------------------------------------------------------------------------------
    /// B L O C K   Q U O T E
    ///
    /// Ist ein Block Quote in den Components des Presentation Intent  vorhanden ?
    var hasBlockQuote: Bool {
        return self.components.contains(where: { $0.kind == .blockQuote})
    }
        
    /// Identiy der Block Quote falls sie vorhanden ist. Ansonsten nil.
    var blockQuoteIdentity: Int? {
        /// Finde den Block Quote mit der niedrigsten Identity und gib diese als Identity zurück.
        let blockQuotes = self.components.filter( { $0.kind == .blockQuote })
        guard let lastQuote = blockQuotes.sorted(by: { $0.identity > $1.identity }).last else { return nil }
        return lastQuote.identity
    }

    /// EIn Block Quote kann in Mitten einer Hierarchie aus List-Items platziert sein. Die Position in dieser Hierarchie wird ermittelt
    var blockQuoteHierarchie: CGFloat? {
        /// Finde den Block Quote mit der niedrigsten Identity und merke diese. Filtere alle Listen mit einer niedrigeren Identiy als die
        /// des Block Quote. Die Anzahl dieser Listen ergibt die Hierarchie, die dem Block Quote zugeordnet werden soll.
        let blockQuotes = self.components.filter( { $0.kind == .blockQuote })
        guard let lastQuote = blockQuotes.sorted(by: { $0.identity > $1.identity }).last else { return nil }
        
        let listen = self.components.filter( {
            ($0.kind == .orderedList || $0.kind == .unorderedList) && $0.identity < lastQuote.identity })
        return CGFloat(listen.count)
    }

    ///---------------------------------------------------------------------------------------
    /// H E A D E R
    ///
    /// Ist ein Header in den Components des Presentation Intent  vorhanden ?
    var hasHeader: Bool {
        self.components.contains(where: { component in
            if case .header(_) = component.kind { return true }
            return false
        })
    }
    
    /// Wenn ein Header in den Components des Presentation Intent  vorhanden ist, dann den Level des Header zurückgeben
    var headerLevel: Int? {
        self.components.compactMap( { component in
            if case .header(let level) = component.kind { return level }
            return nil
        }).first
    }
    
    /// Gerätespezifischen Font für den Level des Header zurückgeben
    func headerFont(baseBodySize: CGFloat = 20) -> UIFont {
        enum HeaderLevel: Int {
            case h1 = 1, h2, h3, h4, h5, h6
            var textStyle: UIFont.TextStyle {
                switch self {
                case .h1: return .largeTitle
                case .h2: return .title1
                case .h3: return .title2
                case .h4: return .title3
                case .h5: return .headline
                case .h6: return .callout
                }
            }
        }
        /// Den Header Style auf die gewünschte Standardgröße umskalieren
        let style = HeaderLevel(rawValue: self.headerLevel ?? 1)?.textStyle ?? .body
        let defaultStyleSize = UIFont.preferredFont(forTextStyle: style).pointSize
        let defaultBodySize  = UIFont.preferredFont(forTextStyle: .body).pointSize
        let ratio            = defaultStyleSize / defaultBodySize
        let targetSize       = baseBodySize * ratio
        let baseFont         = UIFont.systemFont(ofSize: targetSize, weight: .bold)
        
        return UIFontMetrics(forTextStyle: style).scaledFont(for: baseFont)
    }
    
    ///---------------------------------------------------------------------------------------
    /// L I S T E
    ///
    /// Ist eine Liste in den Components des Presentation Intent  vorhanden ?
    var hasList: Bool { self.listParameter() != nil }
    
    /// Ist eine Sortierte Liste in den Components des Presentation Intent  vorhanden ?
    var hasOrderedList: Bool { self.listParameter()?.ordered ?? false }

    /// Hierarchie der Liste 1...n
    var listHierarchie: Int? { self.listParameter()?.hierarchie }
    
    /// Identität der Liste
    var listIdentity: Int { self.listParameter()?.identity ?? 0 }
    
    /// Ordinal einer sortierten Liste 1...n (bei 0 ist es keine sortierte Liste)
    var listOrdinal: Int { self.listParameter()?.ordinal ?? 0 }
        
    ///---------------------------------------------------------------------------------------
    /// T A B L E
    ///
    /// Ist eine Tabelle in den Components des Presentation Intent  vorhanden ?
    var hasTable: Bool { self.tableParameter != nil }

    /// Spalte der Tabelle
    var tableColumn: Int? {
        return self.components.compactMap( { component in
            if case .tableCell(let columnIndex) = component.kind {return columnIndex }
            return nil
        } ).first
    }
    
    /// Zeile der Tabelle (der Wert 0 beschreibt die Titelzeile)
    var tableRow: Int? {
        /// Testen, ob es eine Titelzeile ist
        if let headerRowIndex = self.components.compactMap( { component in
            if case .tableHeaderRow = component.kind { return 0 }
            return nil
        } ).first {
            return headerRowIndex
        }
        /// Testen, ob es eine Tabellenzeile ist
        return self.components.compactMap( { component in
            if case .tableRow(let rowIndex) = component.kind { return rowIndex }
            return nil
        } ).first
    }

    /// Identität der Tabelle
    var tableIdentity: Int? { self.tableParameter?.identity }
    
    /// Alignment der Spalte der Tabelle
    var tableAlignments: [NSTextAlignment]? { self.tableParameter?.alignments }
    
    ///---------------------------------------------------------------------------------------
    /// Aufbereitung der Daten für Listen (ordered / unordered)
    /// Rückgabe der Listen-Hierarchie (count), der Identity, Flag für Ordered-List, Ordinal
    ///
    private func listParameter() -> (hierarchie: Int, identity: Int, ordered: Bool, ordinal: Int)? 
    {
        let list = self.components.filter( { $0.kind == .orderedList || $0.kind == .unorderedList })
        guard let firstList = list.sorted(by: { $0.identity > $1.identity }).first else { return nil }
        
        var ordinal = 0
        if firstList.kind == .orderedList || firstList.kind == .unorderedList {
            let items: [(identity:Int, ordinal:Int)] = self.components.compactMap( { component in
                if case .listItem(ordinal: let ordinal) = component.kind {
                    return (component.identity, ordinal)
                }
                return nil
            })
            
            ordinal = items.sorted(by: { $0.identity > $1.identity }).first?.ordinal ?? 0
        }
        return (list.count, firstList.identity, firstList.kind == .orderedList, ordinal)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Aufbereitung der Daten für Tabellen
    /// Rückgabe der Tabellen-Identity, Alignments der Tabelle (damit auch Spaltenzahl)
    ///
    private func tableParameter_1() -> (identity: Int, alignments: [NSTextAlignment])?
    {
        if let table = self.components.compactMap( { component in
            if case .table(let columns) = component.kind {return (columns: columns, identity: component.identity) }
                return nil
            } ).first
        {
            let alignments = table.columns.map({ $0.alignment == .left ? NSTextAlignment.left :
                                                ($0.alignment == .center ? .center : .right ) })
            return (table.identity, alignments)
        }
        return nil
    }
    
    /// Aufbereitung der Daten für Tabellen
    private var tableParameter: (identity: Int, alignments: [NSTextAlignment])? {
        guard let component = tableComponent else { return nil }
        guard case .table(let columns) = component.kind else { return nil }
        
        let alignments = columns.map {
            switch $0.alignment {
                case .left:   return NSTextAlignment.left
                case .center: return .center
                default:      return .right
            }
        }
        
        return (identity: component.identity, alignments: alignments)
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: Helpers
    
    typealias PresentationType = PresentationIntent.IntentType
    
    /// Erste Component, die dem Test entspricht
    private func firstComponent(where matches: (PresentationType) -> Bool) -> PresentationType? {
        components.first(where: matches)
    }
    
    /// Alle Components, die dem Test entsprechen
    private func components(where matches: (PresentationType) -> Bool) -> [PresentationType] {
        components.filter(matches)
    }
    
    /// Liefert die Component mit der kleinsten Identity
    private func minIdentityComponent(from components: [PresentationType]) -> PresentationType? {
        components.min(by: { $0.identity < $1.identity })
    }
    
    /// Liefert die Component mit der größten Identity
    private func maxIdentityComponent(from components: [PresentationType]) -> PresentationType? {
        components.max(by: { $0.identity < $1.identity })
    }
    
    ///---------------------------------------------------------------------------------------
    /// Alle Listen-Container (ordered / unordered)
    private var listComponents: [PresentationType] {
        components(where: { $0.kind == .orderedList || $0.kind == .unorderedList })
    }
    
    /// Alle BlockQuote-Container
    private var blockQuoteComponents: [PresentationType] {
        components(where: { $0.kind == .blockQuote })
    }
    
    /// Erste CodeBlock-Component
    private var codeBlockComponent: PresentationType? {
        firstComponent {
            if case .codeBlock(_) = $0.kind { return true }
            return false
        }
    }
    
    /// Erste Header-Component
    private var headerComponent: PresentationType? {
        firstComponent {
            if case .header(_) = $0.kind { return true }
            return false
        }
    }
    
    /// Erste Table-Component
    private var tableComponent: PresentationType? {
        firstComponent {
            if case .table(_) = $0.kind { return true }
            return false
        }
    }
        
    /// Erste Paragraph-Component
    private var paragraphComponent: PresentationType? {
        firstComponent(where: { $0.kind == .paragraph })
    }
    
    var paragraphIdentity: Int? {
        paragraphComponent?.identity
    }
    
    ///---------------------------------------------------------------------------------------
    /// Identity des inhaltlichen Blocks - erstes Element in den `components` (i.A. `header`, `paragraph`, `codeBlock`)
    ///
    var firstIdentity: (kind: PresentationIntent.Kind, identity: Int)? {
        guard let intent = components.first else { return nil }
        return (intent.kind, intent.identity)
    }
    


}


