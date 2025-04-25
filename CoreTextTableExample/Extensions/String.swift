//
//  String.swift
//  CoreTextTableExample
//
//  Created by Thomas on 24.04.25.
//

import UIKit

extension StringProtocol {
    
    /**
     Einen String auf eine definierte Länge setzen.
     - Parameters:
         - length: Die Länge, die eingestellt werden soll.
     - returns: Rückgabe des Strings mit der geforderten Länge.
     
     Wenn der String kürzer als `length` ist, wird der String mit Leerzeichen aufgefüllt.
     Ist er länger, wird der String abgeschnitten.
     
     ```
     let t1 = "ABCDEFG".padding(to: 3)   // Ergibt "ABC"
     let t2 = "ABCDEFG".padding(to: 10)  // Ergibt "ABCDEFG   "
     ```
     */
    public func padding(to length: Int) -> String {
        self.padding(toLength: length, withPad: " ", startingAt: 0)
    }
}

extension String {
    
    /**
     Ermittlung der Breite eines Strings für einen Font .
     - Parameters:
        - font: Font, für den die Länge ermittelt werden soll.
     - returns: Die Breite des Strings.
     
     ```
     let w = "ABC".width(.systemFont(ofSize: 16)) // Ergibt 31.8
     ```
     */
    
    public func width(_ font: UIFont) -> CGFloat {
        self.size(withAttributes: [NSAttributedString.Key.font: font]).width
    }
}
