//
//  MarkdownParser+BlockContent.swift
//  MarkdownParser
//
//  Created by Thomas on 19.10.24.
//

import UIKit
import Foundation

// TODO: - Noch einmal intensiv prüfen, ob das Zusammenspiel von Listen und Block Quote funktioniert.

//--------------------------------------------------------------------------------------------
// MARK: - BlockContent: Struktur für die Vorauswertung der PresentationIntentAttribute
    
struct BlockContent {
    var attrText = NSAttributedString()
    var block: AttributeScopes.FoundationAttributes.PresentationIntentAttribute.Value?
    var range: Range<AttributedString.Index>
    
    var kind     : PresentationIntent.Kind = .paragraph
    var identity : Int = 0
    
    var listBulletPointStr  : String
    var widthDefault        : CGFloat
    var headIndent          : CGFloat
    var firstLineHeadIndent : CGFloat
    var blockQuoteIndent    : CGFloat
    var tableBlock          : TableBlock
    
    var isFirstBlockQuote   : Bool
    var isLastBlockQuote    : Bool
    
    /// Spaltenspezifisch
    struct TableColumn {
        var lineText     : String = ""
        var lineWidth    : CGFloat = 0
        var lengthOffset : CGFloat = 0
        var alignment    : NSTextAlignment = .left
    }
    
    struct TableBlock {
        var lastRow      : Int = 0
        var lastColumn   : Int = 0
        
        var lineOben     : String = ""
        var lineMitte    : String = ""
        var lineUnten    : String = ""
        var tabStops     : [NSTextTab] = []
        
        var columns      : [TableColumn] = []
        
        /// Standard-Initialisierung
        init() {}
        
        /// Initialisierung mit Übergabe der Spalten und des Alignments
        init(_ alignments: [NSTextAlignment]?) {
            guard let alignments else { return }
            self.columns = alignments.map( { TableColumn(alignment: $0)})
            self.lastColumn = columns.count - 1
        }
    }
    
    ///-----------------------------------------------------------------------------------
    /// Initialisierung
    ///
    
    init(attrText: NSAttributedString,
         block: AttributeScopes.FoundationAttributes.PresentationIntentAttribute.Value?,
         range: Range<AttributedString.Index>)
    {
        self.attrText = attrText
        self.block = block
        self.range = range
        
        if let ident = self.block?.firstIdentity {
            self.identity = ident.identity
            self.kind     = ident.kind
        }
        
        /// Anführungszeichen vordefinieren
        self.listBulletPointStr = ""
        self.widthDefault       = 0
        
        /// Einzüge für die Listen und die Block Quote
        self.firstLineHeadIndent = 0
        self.headIndent          = 0
        self.blockQuoteIndent    = 5
        
        self.tableBlock = TableBlock()
        
        self.isFirstBlockQuote  = false
        self.isLastBlockQuote   = false
    }
    
    ///-----------------------------------------------------------------------------------
    /// Hilfsfunktionen
    ///
    var hasBlockQuote: Bool { block?.hasBlockQuote ?? false }
    
    ///-----------------------------------------------------------------------------------
    /// Index für das Dictionary der Listeneinträge
    var key: String {
        if let block = self.block {
            return "\(block.listIdentity)-\(block.listHierarchie ?? 0)-\(block.listOrdinal)"
        }
        return "??????"
    }
    
    ///-----------------------------------------------------------------------------------
    /// Debug-Anzeige
    ///
    var debugString: String {
        let bulletPoint = listBulletPointStr.dropLast().padding(to: 3)
        
        var listString = "??????"
        if let block = self.block {
            
            listString =  String(!block.hasList ? "" :
                                 String(format: "%2d ",    block.listIdentity) +
                                 String(format: "%2d ",    block.listHierarchie ?? 0) + "List" +
                                 String(format: "%2d -> ", block.listOrdinal) +
                                 String(format: "%2.1f  ", headIndent) +
                                 bulletPoint
            ).padding(to: 24)
        }
        listString = String(format: " %2d  ", identity) + "\(kind)".padding(to: 15) + listString
        if let block = self.block {
            listString += "\t \(isFirstBlockQuote ? 1 : 0) \(isLastBlockQuote ? 1 : 0) \(String(describing: block))"
        }
        return listString
    }
    
    
    ///---------------------------------------------------------------------------------------
    /// Alle Block Content eines AttributedString ermittlen und aufbereiten (Indent der Listen)
    ///
    static func allBlockContents(attrText: AttributedString, typography: MarkdownTypography) -> [BlockContent] {
        var allBlocks: [BlockContent] = []
        
        for (intentBlock, intentRange) in attrText.runs[\.presentationIntent] {
            guard let intentBlock,
                  intentBlock.components.contains(where: { intent in
                      if case .header(_)     = intent.kind { return true }
                      if case .paragraph     = intent.kind { return true }
                      if case .codeBlock(_)  = intent.kind { return true }
                      if case .thematicBreak = intent.kind { return true }
                      if case .table(_)      = intent.kind { return true }
                      if case .tableHeaderRow = intent.kind { return true }
                      if case .tableRow(_)   = intent.kind { return true }
                      if case .tableCell(_)  = intent.kind { return true }
                      return false
                  })
            else { continue }
            
            let text = NSAttributedString(AttributedString(attrText[intentRange]))
            allBlocks.append(BlockContent(attrText: text, block: intentBlock, range: intentRange))
        }
        
        prepareBlocks(allBlocks: &allBlocks, attrText: attrText, typography: typography)
        return allBlocks
    }
    
    
    private static func prepareBlocks(allBlocks: inout [BlockContent],
                                      attrText: AttributedString, typography: MarkdownTypography)
    {
        let textSize = typography.bodyFont.pointSize
        typealias M = Markdown
        typealias MB = Markdown.BlockQuote
        typealias ML = Markdown.List
        typealias MT = Markdown.Table
        typealias MC = Markdown.CodeBlock
        
        ///-----------------------------------------------------------------------------------
        /// 1 .  D U R C H L A U F  :   Berechnen der Arrays für die Tabellen und Listen
        ///
        var arrIndent       = [ML.leftIndent]           /// Array der Einzüge nach Hierarchie (Summe bilden)
        var dictHeadIndent  = [String: CGFloat]()       /// Dictionary der Einzüge in der Hierachie für gleiche Absätze
        var dictBlockIndent = [Int: CGFloat]()          /// Dictionary der Einzüge für den Block Indent
        var dictTableBlock  = [Int: BlockContent.TableBlock]()
        var prevKey         = ""                        /// Key des vorherigen Blocks
        
        for (index, blockContent) in allBlocks.enumerated() {
            let block = blockContent.block
            
            ///-------------------------------------------------------------------------------
            /// T A B E L L E
            ///
            if let block, let id = block.tableIdentity,
               let col = block.tableColumn, let row = block.tableRow  {
                
                /// TableBlock aus Dictionary laden. Wenn der TableBlock nicht existiert, ihn neu initialiseren und
                /// und die Anzahl der Spalten und Alignments setzen
                var tableBlock = dictTableBlock[id] ?? BlockContent.TableBlock(block.tableAlignments)
                
                /// Getrennte Fonts für Header, Text und Rahmen
                let fontText   = UIFont.systemFont          (ofSize: textSize, weight: MT.weightText)
                let fontHeader = UIFont.systemFont          (ofSize: textSize, weight: MT.weightHeader)
                let fontBoxes  = UIFont.monospacedSystemFont(ofSize: textSize, weight: MT.weightBox)
                
                /// Die Breite des Textes in der Zelle mit dem richtigen Font ermitteln
                let text = String(AttributedString(attrText[blockContent.range]).characters)
                let textWidth = text.width(row == 0 ? fontHeader: fontText)
                
                /// Anzahl der '━' für die Linien der Spalte ermittlen (Textbreite mit Verbreiterung versehen)
                var textLine = ""
                while textWidth + 3 > textLine.width(fontBoxes) { textLine += .ho }
                /// Die Breite des Rahmen für den Text
                let lineWidth = textLine.width(fontBoxes)
                
                /// Wenn die Zeilennummer größer ist als die Nummer im TableBlock, die neue Nummer merken
                tableBlock.lastRow = max(row, tableBlock.lastRow)
                
                /// Wenn die Zelle breiter ist als die Breite im TableBlock, die neue Breite und die Zusatzinformationen merken
                if lineWidth > tableBlock.columns[col].lineWidth {
                    tableBlock.columns[col].lineText     = textLine
                    tableBlock.columns[col].lineWidth    = lineWidth
                    tableBlock.columns[col].lengthOffset = lineWidth - textWidth
                }
                
                /// Den TableBlock in das Dictionary zurückspeichern
                dictTableBlock[id] = tableBlock
            }
            
            ///-------------------------------------------------------------------------------
            /// L I S T E   -  Ein Array mit den Breiten der einzelnen Hierarchie-Level erzeugen
            /// Es darf immer nur der erste Block in einem Paragraph ausgewertet werden. Ein anderer Font, der auch im
            /// Paragraph ist, kann zu einer falsche Berechnung der Einzüge führen.
            ///
            if let block, let id = block.listHierarchie, prevKey != blockContent.key  {
                prevKey = blockContent.key
                
                /// Anführungszeichen (-zahl) für die Liste
                let listBulletPoint = block.hasOrderedList ? "\(block.listOrdinal)." :
                ML.bulletPoint[(id-1) % ML.bulletPoint.count]
                
                /// Ermitteln der Breite der Anführungszeichen der Liste (oder Ordnungszahlen)
                let font = UIFont.systemFont(ofSize: textSize)
                let widthDefault = " ".width(font)
                let width = listBulletPoint.width(font) + 3 * widthDefault
                
                /// Die maximale Breite entsprechend der Hierarchie in das Array einfügen (oder anhängen)
                if arrIndent.count <= id { arrIndent.append(width) }
                arrIndent[id] = max(arrIndent[id], width)
                
                /// Die Standard-Breite für ein Leerzeichen merken, die für die Festlegung des rechten und linken Randes
                /// des Anführungszeichen benötigt wird
                allBlocks[index].widthDefault = widthDefault
            }
        }
        
        ///-----------------------------------------------------------------------------------
        /// 2  .  D U R C H L A U F   D E R    L I S T E  :   Berechnen der Werte für den Block Content
        ///
        for (index, blockContent) in allBlocks.enumerated() {
            guard let block = blockContent.block, let id = block.listHierarchie else { continue }
            
            /// Der Einzug des Listenelements ist die Summe der Indents in der Hierarchie
            var headIndent          = arrIndent[0...id].reduce(0, +)
            var firstLineHeadIndent = arrIndent[0..<id].reduce(0, +)
            var blockQuoteIndent    = blockContent.blockQuoteIndent
            
            /// Anführungszeichen (-zahl) für die Liste
            var listBulletPoint = block.hasOrderedList ? "\(block.listOrdinal)." :
            ML.bulletPoint[(id-1) % ML.bulletPoint.count]
            
            /// Es muss geprüft werden, ob im Dictionary schon ein Eintrag mit dem gleichen Key existiert.
            /// Der Key wird aus `identity`, `hierarchie`und `ordinal`gebildet.
            /// Bei Absätzen, die zur gleichen Aufzählung gehören, das Aufzählungszeichen löschen und den Einzug korrigieren
            ///
            if let dictIndent = dictHeadIndent[blockContent.key]
            {
                listBulletPoint = ""                            /// Aufzählungszeichen löschen
                firstLineHeadIndent = dictIndent                /// Einzüge aus dem vorigen Absatz holen
                headIndent = dictIndent
            } else {
                listBulletPoint = "\t" + listBulletPoint + "\t" /// Aufzählungszeichen mit TAB ergänzen
                dictHeadIndent[blockContent.key] = headIndent   /// Einzug dieses Absatzes merken
            }
            
            ///-------------------------------------------------------------------------------
            /// Block Quote berücksichtigen
            ///
            if let hierarchie = block.blockQuoteHierarchie, hierarchie > 0,
               let blockIdentity = block.blockQuoteIdentity
            {
                /// Wenn ein Block Quote über eine Hierarchie geht, müssen alle Einzüge mit der gleichen Block
                /// Identity gleich sein. Merken in einem Dictionary und wählen des kleinsten Wertes.
                if let blockIndent = dictBlockIndent[blockIdentity] {
                    if firstLineHeadIndent < blockIndent {
                        blockQuoteIndent = firstLineHeadIndent
                        dictBlockIndent[blockIdentity] = firstLineHeadIndent
                        assert(false)
                    }
                    blockQuoteIndent = blockIndent
                }
                else {
                    dictBlockIndent[blockIdentity] = firstLineHeadIndent
                    blockQuoteIndent = firstLineHeadIndent
                }
            }
            
            ///-------------------------------------------------------------------------------
            /// Speichern der berechneten Werte für die Einzüge
            ///
            allBlocks[index].firstLineHeadIndent = firstLineHeadIndent
            allBlocks[index].headIndent          = headIndent
            allBlocks[index].blockQuoteIndent    = blockQuoteIndent
            allBlocks[index].listBulletPointStr  = listBulletPoint
            
            ///-------------------------------------------------------------------------------
            /// D E B U G G I N G
            ///
            let debugText = AttributedString(attrText[blockContent.range]).debugString
            
            let hierarchie:String = {
                guard let val = blockContent.block?.blockQuoteHierarchie else { return "nil"}
                return "\(val)"
            }()
            /// Text    -    Key    -    Block Quote Hierarchie    -     Identity    -     KIND    -    List Identity    -    List Hierarchie    -     List Ordinal   -->   FirstLineHeadIndent    -    Bullet Point
            //            print("\(debugText) \t \(blockContent.key.padding(to:10)) \(hierarchie) \(allBlocks[index].debugString.padding(to: 70)) )")
        }
        
        
        ///-----------------------------------------------------------------------------------
        /// T A B E L L E
        ///
        for table in dictTableBlock {
            let tableBlock = table.value
            
            ///-------------------------------------------------------------------------------
            /// Die Rahmen werden in Light oder Heavy gezeichnet
            String.heavy = false
            var oben  = String.ol            ///┏━━━━━┳━━┳━━━━━━━┓
            var mitte = String.ml            ///┣━━━━━╋━━╋━━━━━━━┫
            var unten = String.ul            ///┗━━━━━┻━━┻━━━━━━━┛
            
            var tabStops: [NSTextTab] = []
            let fontBoxes = UIFont.monospacedSystemFont(ofSize: textSize, weight: MT.weightBox)
            
            ///-------------------------------------------------------------------------------
            /// Berechnung der Breiten der Tabelle, der Linien und der Tabulatoren
            ///
            for (index, column) in tableBlock.columns.enumerated() {
                /// Offset aus der Linienbreite und der Textbreite
                let lengthOffset = column.lengthOffset
                let lineText     = column.lineText
                let alignment    = column.alignment
                
                /// Positionen für den linken und rechten Rand der Spalte
                let locationLeft  = oben.width(fontBoxes)
                let locationRight = (oben + lineText).width(fontBoxes)
                
                /// Die Linien für oben, mitte und unten zusammenstellen
                oben  += lineText + (index == tableBlock.lastColumn ? .or : .om)
                mitte += lineText + (index == tableBlock.lastColumn ? .mr : .mi)
                unten += lineText + (index == tableBlock.lastColumn ? .ur : .um)
                
                /// Position der Tabulatoren für den Text aus dem Alignment heraus ermitteln. Der hälftige Offset der Breiten
                /// wird links und rechts bei der Position berücksichtigt.
                let location = {
                    switch alignment {
                    case .right:  locationRight - lengthOffset/2
                    case .center: (locationLeft + locationRight)/2
                    default:      locationLeft  + lengthOffset/2
                    }
                }()
                
                /// Der Tabulator für den Text in der Spalte und der Tabulator für den rechten Trennstrich
                tabStops.append(NSTextTab(textAlignment: alignment, location: location))
                tabStops.append(NSTextTab(textAlignment: .left,     location: locationRight))
            }
            
            /// Berechnete Größen für die ganze Tabelle in dem TableBlock speichern
            dictTableBlock[table.key]?.tabStops  = tabStops
            dictTableBlock[table.key]?.lineOben  = oben
            dictTableBlock[table.key]?.lineMitte = mitte
            dictTableBlock[table.key]?.lineUnten = unten
        }
        
        ///-----------------------------------------------------------------------------------
        /// Für die Tabellen die korrekten Werte in den BlockContent eintragen
        ///
        for (index, blockContent) in allBlocks.enumerated() {
            guard let block = blockContent.block, let id = block.tableIdentity else  { continue }
            
            if let tableBlock = dictTableBlock[id] {
                allBlocks[index].tableBlock = tableBlock
            }
        }
        
//        for table in dictTableBlock {
//            for column in table.value.columns {
//                print(table.key, table.value.lastRow, table.value.lastColumn, "|", column.alignment.rawValue, column.lineWidth)
//            }
//        }
        
        //        return allBlocks
        
        ///-----------------------------------------------------------------------------------
        /// 3  .  D U R C H L A U F   D E R    L I S T E
        ///
        for (index, blockContent) in allBlocks.enumerated() {
            guard let block = blockContent.block else { continue }
            
            /// Den Font des Attributed String ermitteln. Wenn es keinen Font gibt, den System Font erstellen. Zusätzlich die
            /// Sonderfälle Header und Code Block berücksichtigen und den Font für diese Fälle setzen.
            var font = blockContent.attrText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont ?? typography.paragraph.font
            font = block.hasHeader ? typography.header(level: block.headerLevel ?? 1).font : font
            font = block.hasCodeBlock ? typography.codeBlock.font : font
            
            let paragraphMetrics = typography.paragraph

            var attrText = NSMutableAttributedString(attributedString: blockContent.attrText)
            var tabulators         : [NSTextTab]  =  []
            /// Im Block Quote liefert `contentRect` bereits die vollständige Textposition
            /// (inkl. `viewMarginLeft` / `viewMarginRight`). Die Paragraph-Indents sind dort 0,
            /// damit die Werte nicht doppelt wirken. Außerhalb gelten die globalen Dokument-Ränder.
            /// NSParagraphStyle.tailIndent erwartet einen negativen Wert (Abstand vom rechten Rand).
            var firstLineHeadIndent    : CGFloat  =  block.hasBlockQuote ? 0 :  CGFloat(M.marginLeft)
            var headIndent             : CGFloat  =  block.hasBlockQuote ? 0 :  CGFloat(M.marginLeft)
            var tailIndent             : CGFloat  =  block.hasBlockQuote ? 0 : -CGFloat(M.marginRight)
            var paragraphSpacing       : CGFloat  =  paragraphMetrics.paragraphSpacing
            var paragraphSpacingBefore : CGFloat  =  paragraphMetrics.paragraphSpacingBefore
            var lineHeightMultiple     : CGFloat  =  paragraphMetrics.lineHeightMultiple
            let alignment      : NSTextAlignment  =  .natural
            
            ///-------------------------------------------------------------------------------
            /// Blockerkennung, um Abstände nach Bedarf einzustellen
            ///
            let prevBlockQuote = index > 0                   && allBlocks[index-1].hasBlockQuote
            let nextBlockQuote = index < allBlocks.count - 1 && allBlocks[index+1].hasBlockQuote
            let currBlockQuote = block.hasBlockQuote
            
            /// Start eines BlockQuote
            if  currBlockQuote && !prevBlockQuote {
                allBlocks[index].isFirstBlockQuote = true
//                attrText.addAttributes([.foregroundColor: UIColor.systemPurple], range: NSRange(location: 0, length: 1))
            }
            
            /// Ende eines BlockQuote
            if currBlockQuote && !nextBlockQuote {
                allBlocks[index].isLastBlockQuote = true
//                attrText.addAttributes([.foregroundColor: UIColor.systemTeal], range: NSRange(location: 1, length: 1))
            }
            
            /// Absatz nach einer BlockQuote
            if !currBlockQuote && prevBlockQuote {
                
            }
            
            /// Absatz vor einer BlockQuote
            if !currBlockQuote && nextBlockQuote {
                
            }
            
            ///-------------------------------------------------------------------------------
            /// Header erkennen und den Font des Headers ergänzen
            if block.hasHeader {
                let headerMetrics = typography.header(level: block.headerLevel ?? 1)
                attrText.addAttributes([.font: font])
                paragraphSpacingBefore = index > 0 ? headerMetrics.paragraphSpacingBefore : 0
                paragraphSpacing = headerMetrics.paragraphSpacing
            }
            
            ///-------------------------------------------------------------------------------
            /// Code Block erkennen und den Font des Code Block ergänzen.
            /// Die horizontalen Einzüge werden vom `CodeBlockRenderer` direkt aus den Metrics
            /// gesetzt; hier braucht es nur Font und vertikale Abstände.
            if block.hasCodeBlock {
                let codeMetrics = typography.codeBlock
                attrText.addAttributes([.font: font])
                paragraphSpacingBefore = codeMetrics.paragraphSpacingBefore
                paragraphSpacing       = codeMetrics.paragraphSpacing
                lineHeightMultiple     = codeMetrics.lineHeightMultiple
            }
            
            ///-------------------------------------------------------------------------------
            /// List erkennen und die Bullets voranstellen
            if block.hasList {
                let attrList = NSMutableAttributedString(       /// Bullet-Point dem Attributed String voranstellen
                    string:     blockContent.listBulletPointStr,
                    attributes: blockContent.attrText.attributes(at: 0, effectiveRange: nil))
                
                                                                /// Bullet muss auf den Standard-Font gesetzt werden
                attrList.addAttributes([.font: UIFont.systemFont(ofSize: textSize, weight: .regular) ])
                attrList.append(blockContent.attrText)          /// Original-Text anhängen
                attrText = attrList

                /// Die Defaultbreite eines SPACE x 3
                let w = 3 * blockContent.widthDefault
                
                /// Einzüge und Tab-Stops festlegen
                headIndent          = headIndent          + blockContent.headIndent
                firstLineHeadIndent = firstLineHeadIndent + blockContent.firstLineHeadIndent
                tabulators          = [NSTextTab(textAlignment: .right, location: headIndent - w),
                                       NSTextTab(textAlignment: .left,  location: headIndent) ]
            }
            
            ///-------------------------------------------------------------------------------
            /// Style einfügen
            ///
            let ps = NSMutableParagraphStyle()
            ps.lineHeightMultiple     = lineHeightMultiple
            ps.defaultTabInterval     = 100
            ps.headIndent             = headIndent
            ps.firstLineHeadIndent    = firstLineHeadIndent
            ps.tailIndent             = tailIndent
            ps.paragraphSpacing       = paragraphSpacing
            ps.paragraphSpacingBefore = paragraphSpacingBefore
            ps.alignment              = alignment
            ps.lineBreakMode          = .byWordWrapping
            ps.tabStops               = tabulators

            attrText.addAttribute(.paragraphStyle, value: ps,
                                  range: NSRange(location: 0, length: attrText.length))
            /// Sprache zufügen
            attrText.addAttributes([.languageIdentifier: "de-DE"])
            
            /// DEBUG
//            print(AttributedString(attrText).debugStringLong)
            assert(ps.tabStops.map(\.ctTab) == tabulators.map(\.ctTab) )
            
            allBlocks[index].attrText = attrText
        }
    }
}

