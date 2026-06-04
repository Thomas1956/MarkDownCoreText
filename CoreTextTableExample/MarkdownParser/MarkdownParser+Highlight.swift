//  MarkdownParser+Highlight.swift
//  MarkdownParser
//
//  Created by Thomas on 18.04.25.
//

import Foundation
import UIKit
import SwiftSyntax
import SwiftParser


//--------------------------------------------------------------------------------------------
// MARK: - Klasse SyntaxHighlight

public class SyntaxHighlight {
 
    ///---------------------------------------------------------------------------------------
    /// Initialisieren mit dem Namen der JSON-Datei
    ///
    public init(filename json: String) {
        self.palette = loadPalette(filename: json)
        
//        print( "keyword ", TokenColor.keyword .hexString)
//        print( "string  ", TokenColor.string  .hexString)
//        print( "number  ", TokenColor.number  .hexString)
//        print( "comment ", TokenColor.comment .hexString)
//        print( "modifier", TokenColor.modifier.hexString)
//        print( "plain   ", TokenColor.plain   .hexString)
//        print( "-------------------------")
    }
    
    ///---------------------------------------------------------------------------------------
    /// Funktion zum Highlighten des Textes
    ///
    public func makeHighlighted(code: String, fontSize: CGFloat) -> AttributedString {
        return swiftHighlight(code: code, palette: palette, fontSize: fontSize)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Die optionale Palette mit den Zuordnungen der Farben zu den Identifiern (JSON-Import)
    private var palette:  [String : [String : String]] = [:]

    ///---------------------------------------------------------------------------------------
    /// Farbschema (System‑Farben für Dark/Light‑Mode)
    private enum TokenColor {
        static let keyword   = UIColor(red:  20/256, green:  49/256, blue: 245/256, alpha: 1)
        static let string    = UIColor(red: 165/256, green:  52/256, blue:  37/256, alpha: 1)
        static let number    = UIColor.systemBlue
        static let comment   = UIColor(red:  58/256, green: 140/256, blue:  38/256, alpha: 1)
        static let modifier  = UIColor.systemOrange
        static let plain     = UIColor.black
    }
    
    ///---------------------------------------------------------------------------------------
    /// Liefert einen String.Index aus einem UTF‑8‑Offset
    private func stringIndex(fromUTF8 offset: Int, in text: String) -> String.Index {
        let iUTF8 = text.utf8.index(text.utf8.startIndex, offsetBy: offset)
        // Force‑unwrap ist hier sicher, weil Parser‑Offsets garantiert gültig sind
        return String.Index(iUTF8, within: text)!
    }
    
    ///---------------------------------------------------------------------------------------
    /// Laden der Palette mit den Farbzuordnungen aus  JSON-Datei
    func loadPalette(filename fileName: String) -> [String : [String : String]] {
        if let url = Bundle.main.url(forResource: fileName, withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                return try decoder.decode([String : [String : String]].self, from: data)
             } catch {
                print("error:\(error)")
            }
        }
        return [String : [String : String]]()
    }

    ///---------------------------------------------------------------------------------------
    /// Einmal pro Parse-Call aufrufen - Sammelt alle TOP-LEVEL-Variablen, indem es nur die .item-Knoten filtert
    ///
    func collectGlobalVarNames(from tree: SourceFileSyntax) -> Set<String> {
        var globals = Set<String>()
        
        for stmt in tree.statements {                        // stmt: CodeBlockItemSyntax
            // stmt.item ist ein `Syntax`-Knoten – casten wir ihn in VariableDeclSyntax
            if let vd = stmt.item.as(VariableDeclSyntax.self) {
                for bind in vd.bindings {
                    if let id = bind.pattern.as(IdentifierPatternSyntax.self)?.identifier.text {
                        globals.insert(id)
                    }
                }
            }
        }
        return globals
    }
    
    var globalVarNames: Set<String> = []
    
    ///---------------------------------------------------------------------------------------
    // MARK: - Umwandlung eines Strings in einen AttributedString mit Syntax Highlight
    
    func swiftHighlight(code: String, palette: [String : [String : String]],
                        fontSize: CGFloat) -> AttributedString {
        
        var attr = AttributedString(code)
        attr.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        
        let tree = Parser.parse(source: code)
        
        /// alle 'echten' globalen Variablen ermitteln
        self.globalVarNames = collectGlobalVarNames(from: tree)
        
//        print("| Type | Subtype | Text | Ok |")
//        print("| :--  | :--     | :--  | :--: |")

        
        for token in tree.tokens(viewMode: .all) {
            
            ///-------------------------------------------------------------------------------
            /// Inhalt des Token
            ///
            let start = stringIndex(fromUTF8: token.positionAfterSkippingLeadingTrivia.utf8Offset,
                                    in: code)
            let end   = stringIndex(fromUTF8: token.endPositionBeforeTrailingTrivia.utf8Offset,
                                    in: code)
            
            if let aStart = AttributedString.Index(start, within: attr),
               let aEnd   = AttributedString.Index(end,   within: attr)
            {
                ///---------------------------------------------------------------------------
                /// Die Farbe für die **Token** und für die **Rollen** ermitteln
                ///
                let color : UIColor? = {
                    /// Durchsuchen der Token
                    switch token.tokenKind {
                    case .wildcard:                      return UIColor.systemTeal
                    case .keyword:                       return TokenColor.keyword
                    case .stringSegment,  .stringQuote:  return TokenColor.string
                    case .integerLiteral, .floatLiteral: return UIColor.systemBlue.lowlight
                        
                    case .identifier(let text):
                        let role = role(for: token)
                        
//                        print("\(role.type.name.fixedLength(to: 15)) \(role.subtype.fixedLength(to: 22)) \"\(text)\" ")
                        
                        var subcolor: UIColor?
                        
                        /// Durchsuchen der Rollen im Token Identifier
                        switch role.type {
                        /// Deklarationen
                        case .globalDecl:        subcolor = UIColor(hex: "#3495AF")
                        case .propertyDecl:      subcolor = UIColor(hex: "#3495AF")
                        case .localDecl:         subcolor = UIColor.black
                        /// Referenzen
                        case .globalRef:         subcolor = UIColor(hex: "#3495AF")
                        case .propertyAccess:    subcolor = UIColor(hex: "#3495AF")
                        case .propertyRef:       subcolor = UIColor(hex: "#3495AF")
                        case .localRef:          subcolor = UIColor.black
                        /// Parameter
                        case .parameterExt:      subcolor = UIColor(hex: "#057CB0")
                        case .parameterInt:      subcolor = UIColor.black
                        case .paramRef:          subcolor = UIColor.black
                        /// Funktionen
                        case .functionDecl:      subcolor = UIColor(hex: "#057CB0")
                        case .functionCall:      subcolor = UIColor(hex: "#3495AF")
                        /// Argumente und Typen
                        case .argumentLabel:     subcolor = UIColor(hex: "#3495AF")
                        case .typeRef:           subcolor = UIColor(hex: "#3495AF")
                        case .typeDecl:          subcolor = UIColor(hex: "#3495AF")
                        
                        default: break
                        }
                        
                        /// Bei Bedarf den JSON-Import nutzen, um die Farbe zu ermitteln
                        if let c = palette[role.type.name]?[text], let color = UIColor(hex: c) {
                            print(text, c)
                            subcolor = color
                        }
                        return subcolor

                    default: break
                    }
                    return .black
                }()
                
                ///---------------------------------------------------------------------------
                /// Setzen der Farbe für den Range im AttributedString
                let range = aStart..<aEnd
                attr[range].foregroundColor = color ?? .black
            }
            
            ///-------------------------------------------------------------------------------
            /// Bearbeiten der Leading‑ & Trailing‑Trivia (i.a. Kommentare)
            ///
            func colorTrivia(_ pieces: Trivia, baseOffset: Int) {
                var cursor = baseOffset
                for piece in pieces {
                    let len = piece.sourceLength.utf8Length
                    
                    /// Kommentare ausfiltern
                    if piece.isComment {
                        let s = stringIndex(fromUTF8: cursor,       in: code)
                        let e = stringIndex(fromUTF8: cursor + len, in: code)
                        
                        if let aS = AttributedString.Index(s, within: attr),
                           let aE = AttributedString.Index(e, within: attr) {
                            attr[aS..<aE].foregroundColor = TokenColor.comment
                            
                            ///---------------------------------------------------------------
                            /// Ist es ein Kommentar mit "///"  am Anfang
                            if case .docLineComment = piece {
                                let s1 = stringIndex(fromUTF8: cursor + 3, in: code)
                                let aS1 = AttributedString.Index(s1, within: attr) ?? aS
                                attr[aS1..<aE].font = UIFont(name: "Helvetica", size: fontSize)
                            }
                            
                            ///---------------------------------------------------------------
                            /// Ist es ein Kommentar mit einem "MARK:" nur in Zeilen mit "//"
                            if case .lineComment(let text) = piece,
                               let local = text.range(of: "MARK:") {

                                // 1.  Offset *im* Kommentar‑String
                                let rel = text.utf8.distance(from: text.startIndex, to: local.lowerBound)

                                // 2.  Globaler Offset = cursor + rel
                                let markStart = stringIndex(fromUTF8: cursor + rel, in: code)
                                let markEnd   = stringIndex(fromUTF8: cursor + rel + "MARK:".utf8.count, in: code)

                                if let mStart = AttributedString.Index(markStart, within: attr),
                                   let mEnd   = AttributedString.Index(markEnd,   within: attr) {
                                    // Fettschrift und/oder eigene Farbe
                                    attr[mStart..<aE].font = .monospacedSystemFont(ofSize: fontSize, weight: .bold)
                                    attr[mStart..<mEnd].foregroundColor = .systemOrange
                                }
                            }
                        }
                    }
                    cursor += len
                }
            }
            
            ///-------------------------------------------------------------------------------
            /// Die Trivia's umfärben
            ///
            colorTrivia(token.leadingTrivia,  baseOffset: token.position.utf8Offset)
            colorTrivia(token.trailingTrivia, baseOffset: token.endPositionBeforeTrailingTrivia.utf8Offset)
        }
        return attr
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Extension SyntaxHighlight

extension SyntaxHighlight {
    
    enum IdentifierRole: String {
        
        case globalDecl,   globalRef                    /// Globale Variablen, Referenzen
        case localDecl,    localRef                     /// Lokale Variablen, Referenzen
        case propertyDecl, propertyAccess, propertyRef  /// Klassen-/Struktur- Variablen, Zugriffe, Referenzen
        case parameterExt, parameterInt,   paramRef     /// Parameter Variablen (int/ext), Referenzen
        case functionDecl, functionCall                 /// Funktion Deklaration, Aufruf
        case typeDecl,     typeRef                      /// Typ Deklaration,
        case argumentLabel
        case externalRef,  other
        
        var name: String { rawValue }
    }
    
    private func role(for token: TokenSyntax) -> (type: IdentifierRole, subtype: String) {
        
        // —————————————— 1) PARAMETER ——————————————
        if let param = token.parent?.as(FunctionParameterSyntax.self) {
            // externer Name = firstName, interner = secondName
            let isExternal = (param.firstName.tokenKind == token.tokenKind)
            return (isExternal ? .parameterExt : .parameterInt, "")
        }
        
        // 2) ————————— VAR‑DECLARATIONS —————————
        if token.parent?.as(IdentifierPatternSyntax.self) != nil,
           let varDecl = token.parent?.ancestor(of: VariableDeclSyntax.self)
        {
            let isUnderSource   = varDecl.ancestor(of: SourceFileSyntax.self) != nil
            let isUnderCode     = varDecl.ancestor(of: CodeBlockSyntax.self)  != nil
            let isUnderStruct   = varDecl.ancestor(of: StructDeclSyntax.self) != nil
            let isUnderClass    = varDecl.ancestor(of: ClassDeclSyntax.self)  != nil
            
            // 2a) Property in Struct/Class (außerhalb von Funktionen)
            if (isUnderStruct || isUnderClass) && !isUnderCode {
                return (.propertyDecl, "")
            }
            // 2b) Top‑Level‑Variable (SourceFile, nicht in CodeBlock)
            if isUnderSource && !isUnderCode {
                return (.globalDecl, "")
            }
            // 2c) alle anderen sind lokale Variablen
            return (.localDecl, "")
        }
        
        if token.parent?.as(FunctionDeclSyntax.self) != nil {
            return (.functionDecl, "")
        }
        
        // 3) Parameter‑Namen (extern vs. intern)
        if let param = token.parent?.as(FunctionParameterSyntax.self) {
            if param.firstName.tokenKind == token.tokenKind {
                return (.parameterExt, "")
            }
            return (.parameterInt, "")
        }
        
        // ————————————— VERWENDUNGEN —————————————
        
        // 4) Argument‑Label im Aufruf
        if let labeled = token.parent?.as(LabeledExprSyntax.self),
           labeled.label?.tokenKind == token.tokenKind
        {
            return (.argumentLabel, "")
        }
        
        // ——————————— 5) References ———————————
        if let declRef = token.parent?.as(DeclReferenceExprSyntax.self) {
            let name = token.trimmedDescription

            // 5a) Funktions-Aufruf?
            if let call = declRef.ancestor(of: FunctionCallExprSyntax.self),
               call.calledExpression.trimmedDescription == name {
                return (.functionCall, "")
            }

            // 5b) Property-Zugriff (any MemberAccessExpr)
            if let member = declRef.parent?.as(MemberAccessExprSyntax.self),
               member.declName.trimmedDescription == name {
                return (.propertyAccess, "")
            }
            
            if isStoredProperty(name, from: declRef) {
                return (.propertyRef, "")
            }

            // 5c) Parameter-Reference?
            if parameterRole(for: name, at: declRef) != nil {
                return (.paramRef, "")
            }

            // 5d) Lokale Variable?
            if isLocallyDeclared(name, in: declRef) {
                return (.localRef, "")
            }

            // 5e) ECHTE Global-Variable? (nur wenn in globals-Set)
            if self.globalVarNames.contains(name) {
                return (.globalRef, "")
            }

            // 5f) External-Ref (alles, was nicht lokal/param/property/call ist)
            return (.externalRef, "")
        }
        
        
        // --------- Typ‑Verwendung -----------------------------------------
        
        if token.parent?.as(IdentifierTypeSyntax.self) != nil { return (.typeRef, "IdentifierTypeSyntax") }
        if token.parent?.as(MemberTypeSyntax    .self) != nil { return (.typeRef, "MemberTypeSyntax")     }
        if token.parent?.as(OptionalTypeSyntax  .self) != nil { return (.typeRef, "OptionalTypeSyntax")   }
        if token.parent?.as(ArrayTypeSyntax     .self) != nil { return (.typeRef, "ArrayTypeSyntax")      }
        if token.parent?.as(DictionaryTypeSyntax.self) != nil { return (.typeRef, "DictionaryTypeSyntax") }
        
        // --------- Eigene Typ‑Deklaration ---------------------------------
        
        if token.parent?.as(StructDeclSyntax   .self) != nil { return (.typeDecl, "StructDeclSyntax")    }
        if token.parent?.as(ClassDeclSyntax    .self) != nil { return (.typeDecl, "ClassDeclSyntax")     }
        if token.parent?.as(EnumDeclSyntax     .self) != nil { return (.typeDecl, "EnumDeclSyntax")      }
        if token.parent?.as(ProtocolDeclSyntax .self) != nil { return (.typeDecl, "ProtocolDeclSyntax")  }
        if token.parent?.as(TypeAliasDeclSyntax.self) != nil { return (.typeDecl, "TypeAliasDeclSyntax") }
        
        
        // ————————————— Fallback —————————————
        return (.other, "")
    }
    
    //----------------------------------------------------------------------------------------
    /// Identifizierung der Rolle von Parametern einer Funktion
    ///
    private func parameterRole( for name: String, at declRef: DeclReferenceExprSyntax) -> IdentifierRole? {
        // klettert alle umgebenden FunctionDeclSyntax hoch
        var node: SyntaxProtocol? = declRef
        
        while let n = node {
            if let fd = n.as(FunctionDeclSyntax.self) {
                let params = fd.signature.parameterClause.parameters
                for p in params {
                    if p.firstName  .text == name { return .parameterExt }
                    if p.secondName?.text == name { return .parameterInt }
                }
            }
            node = n.parent
        }
        return nil
    }
    
    //----------------------------------------------------------------------------------------
    /// Prüft, ob im übergeordneten Scope eine lokale Variable mit diesem Namen existiert
    
    private func isLocallyDeclared(_ name: String, in declRef: DeclReferenceExprSyntax) -> Bool {
        var node: SyntaxProtocol? = declRef
        
        while let n = node {
            if let fd = n.as(FunctionDeclSyntax.self),
               let body = fd.body {
                
                // 2a) Parameter auch hier nochmal prüfen (safety)
                let params = fd.signature.parameterClause.parameters
                if params.contains(where: { $0.firstName.text == name || $0.secondName?.text == name}) {
                    return true
                }
                
                // 2b) var‑Bindings in diesem Scope
                for stmt in body.statements {
                    if let vd = stmt.item.as(VariableDeclSyntax.self) {
                        for bind in vd.bindings {
                            if bind.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == name {
                                return true
                            }
                        }
                    }
                }
            }
            node = n.parent
        }
        return false
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Funktion, Helper
    
    private func isStoredProperty(_ ident: String, from ref: SyntaxProtocol) -> Bool {
        
        // versuche Struct- oder Class-Decl zu finden, castet beide auf SyntaxProtocol
        guard let typeNode = (ref.ancestor(of: StructDeclSyntax.self) as SyntaxProtocol?) ??
                             (ref.ancestor(of: ClassDeclSyntax.self)  as SyntaxProtocol?)
        else { return false }
        
        // jetzt typeNode wieder “entpacken” und Member durchsuchen
        let members = (typeNode.as(StructDeclSyntax.self)?.memberBlock.members  ??
                       typeNode.as(ClassDeclSyntax.self)? .memberBlock.members) ?? []
        
        return members.contains { item in
            guard let varDecl = item.decl.as(VariableDeclSyntax.self) else { return false }
            return varDecl.bindings.contains { bind in
                bind.pattern.as(IdentifierPatternSyntax.self)?.identifier.text == ident
            }
        }
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Extension TriviaPiece zum Ausfiltern von Kommentaren

private extension TriviaPiece {
    /// Hilfs‑Flag, um Kommentare schnell zu erkennen
    var isComment: Bool {
        switch self {
        case .lineComment, .blockComment, .docLineComment, .docBlockComment: return true
        default: return false
        }
    }
}

//--------------------------------------------------------------------------------------------
// MARK: - Extension SyntaxProtocol

private extension SyntaxProtocol {
    func ancestor<T: SyntaxProtocol>(of type: T.Type) -> T? {
        var node = parent
        while let n = node {
            if let match = n.as(T.self) { return match }
            node = n.parent
        }
        return nil
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - Extension UIColor für Einlesen von HEX-Strings (3 Stellen: "#3495AF")

private extension UIColor {
    convenience init?(hex: String) {
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])

            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0

                if scanner.scanHexInt64(&hexNumber) {
                    let r = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    let g = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    let b = CGFloat( hexNumber & 0x000000ff) / 255

                    self.init(red: r, green: g, blue: b, alpha: 1)
                    return
                }
            }
        }
        return nil
    }
    
    /// Erzeugen eines HEX-Strings aus der Farbe
    var hexString: String {
        var red = CGFloat.zero, green = CGFloat.zero, blue = CGFloat.zero
        self.getRed(&red, green: &green, blue: &blue, alpha: nil)
        let r = Int(round(red   * 255))
        let g = Int(round(green * 255))
        let b = Int(round(blue  * 255))
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

//--------------------------------------------------------------------------------------------
// MARK: - Extension StringProtocol, um Großschreibung des ersten Buchstabens zu erkennen

private extension StringProtocol {

    /**
     Testen, ob der erste Biuchstabe im String eine Großschreibung ist.
     */
    var startsWithUppercase: Bool { first.map(\.isUppercase) ?? false }
     
    
    // MARK: - Länge eines Strings auf eine feste Größe setzen
    
    /**
     Einen String auf eine definierte Länge setzen.
     - Parameters:
     - length: Die Länge, die eingestellt werden soll.
     - returns: Rückgabe des Strings mit der geforderten Länge.
     
     Wenn der String kürzer als `length` ist, wird der String mit Leerzeichen aufgefüllt.
     Ist er länger, wird der String abgeschnitten.
     
     ```
     let t1 = "ABCDEFG".fixedLength(to: 3)   // Ergibt "ABC"
     let t2 = "ABCDEFG".fixedLength(to: 10)  // Ergibt "ABCDEFG   "
     ```
     */
    func fixedLength(to length: Int) -> String {
        self.padding(toLength: length, withPad: " ", startingAt: 0)
    }
}
