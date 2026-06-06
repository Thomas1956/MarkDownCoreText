//
//  Color.swift
//  
//
//  Created by Thomas on 12.05.23.
//

import UIKit


//--------------------------------------------------------------------------------------------
// MARK: - UIColor Extension

public extension UIColor {
    
    // Affinity nutzt HSL anstelle von HSB
    
    convenience init(hue: CGFloat, saturation: CGFloat, lightness: CGFloat, alpha: CGFloat) {
        precondition(0...1 ~= hue &&
                     0...3 ~= saturation &&
                     0...1 ~= lightness &&
                     0...1 ~= alpha, "input range is out of range 0...1")
        
        // From HSL TO HSB ---------
        var newSaturation: CGFloat = 0.0
        
        let brightness = lightness + saturation * min(lightness, 1-lightness)
        if brightness == 0    { newSaturation = 0.0 }
        else                  { newSaturation = 2 * (1 - lightness / brightness) }
        
        self.init(hue: hue, saturation: newSaturation, brightness: brightness, alpha: alpha)
    }
    
    /// Erzeugen einer UIColor aus einem Hexadezimal-String, der im Format `#123456` vorliegen muss.
    convenience init?(hexstring: String) {
        var cString:String = hexstring.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard cString.hasPrefix("#"), cString.count == 7 else { return nil }

        cString.remove(at: cString.startIndex)

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        let red   = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0
        let blue  = CGFloat (rgbValue & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    func getHSL(_ hue: UnsafeMutablePointer<CGFloat>?, saturation: UnsafeMutablePointer<CGFloat>?,
                     lightness: UnsafeMutablePointer<CGFloat>?, alpha: UnsafeMutablePointer<CGFloat>?) {

        var satura = CGFloat.zero
        var bright = CGFloat.zero
        getHue(hue, saturation: &satura, brightness: &bright, alpha: alpha)
        
        let light = bright * (1 - satura/2)
        if light > 0 && light < 1 { saturation?.pointee = (bright - light) / min(light, 1 - light) }
        else                       {    saturation?.pointee = 0 }
        
        lightness?.pointee = light
    }
    
    /// toleranter Vergleich von zwei Farben (Abweichung der Komponenten kleiner 1%)
    static func == (l: UIColor, r: UIColor) -> Bool {
        var r1 = CGFloat.zero
        var g1 = CGFloat.zero
        var b1 = CGFloat.zero
        var a1 = CGFloat.zero
        l.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        var r2 = CGFloat.zero
        var g2 = CGFloat.zero
        var b2 = CGFloat.zero
        var a2 = CGFloat.zero
        r.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        return abs(r1-r2) < 0.01 && abs(g1-g2) < 0.01 && abs(b1-b2) < 0.01 && abs(a1-a2) < 0.01
    }
    
    /// Rückgabe der Helligkeit der Farbe
    var lightness : CGFloat {
        get {
            var light = CGFloat.zero
            getHSL(nil, saturation: nil, lightness: &light, alpha: nil)
            return light
        }
    }
    
    /// Rückgabe des Alphawertes der Farbe
    var alphavalue : CGFloat {
        get {
            var a = CGFloat.zero
            self.getWhite(nil, alpha: &a)
            return a
        }
    }
    
    /// String mit Anzeige der RGBA-Komponenten
    var stringRGB : String {
        get {
            var red   = CGFloat.zero
            var green = CGFloat.zero
            var blue  = CGFloat.zero
            var alpha = CGFloat.zero
            self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return "RGB-Color: r=\(Int(256*red)) g=\(Int(256*green)) b=\(Int(256*blue)) a=\(Int(256*alpha))"
        }
    }
    
    /// String mit Anzeige der HSB-Komponenten
    var stringHSB : String {
        get {
            var hue    = CGFloat.zero
            var satura = CGFloat.zero
            var bright = CGFloat.zero
            getHue(&hue, saturation: &satura, brightness: &bright, alpha: nil)
            return "HSB-Color: h=\(Int(360*hue)) s=\(Int(100*satura)) b=\(Int(100*bright))"
        }
    }
    
    /// String mit Anzeige der HSL-Komponenten
    var stringHSL : String {
        get {
            var hue    = CGFloat.zero
            var satura = CGFloat.zero
            var light  = CGFloat.zero
            getHSL(&hue, saturation: &satura, lightness: &light, alpha: nil)
            return "HSL-Color: h=\(Int(360*hue)) s=\(Int(100*satura)) l=\(Int(100*light))"
        }
    }

    /// Aufhellung `lightness` (HSL) auf `lightness * 0.4 + 0.6 ` [0.6 ... 1.0]
    var highlight : UIColor {
        get {
            var hue    = CGFloat.zero
            var satura = CGFloat.zero
            var light  = CGFloat.zero
            var alpha  = CGFloat.zero
            getHSL(&hue, saturation: &satura, lightness: &light, alpha: &alpha)
            let fak : CGFloat = 0.6
            return UIColor(hue: hue, saturation: satura, lightness: light*(1-fak)+fak, alpha: alpha)
        }
    }
    
    /// Aus der Textfarbe abgeleitete Balkenfarbe für BlockQuotes.
    var blockQuoteBarColor: UIColor {
        highlight
    }
    
    /// Aus der Textfarbe abgeleitete Hintergrundfarbe für BlockQuotes.
    var blockQuoteBackgroundColor: UIColor {
        var hue    = CGFloat.zero
        var satura = CGFloat.zero
        var light  = CGFloat.zero
        getHSL(&hue, saturation: &satura, lightness: &light, alpha: nil)
        return UIColor(hue: hue, saturation: satura * 0.35, lightness: light * 0.12 + 0.88, alpha: 0.8)
    }
    
    /// Aus der Textfarbe abgeleitete Rahmenfarbe für CodeBlocks.
    var codeBlockBorderColor: UIColor {
        var hue    = CGFloat.zero
        var satura = CGFloat.zero
        var light  = CGFloat.zero
        getHSL(&hue, saturation: &satura, lightness: &light, alpha: nil)
        return UIColor(hue: hue, saturation: satura * 0.45, lightness: light * 0.25 + 0.65, alpha: 0.85)
    }
    
    /// Aus der Textfarbe abgeleitete Hintergrundfarbe für CodeBlocks.
    var codeBlockBackgroundColor: UIColor {
        var hue    = CGFloat.zero
        var satura = CGFloat.zero
        var light  = CGFloat.zero
        getHSL(&hue, saturation: &satura, lightness: &light, alpha: nil)
        return UIColor(hue: hue, saturation: satura * 0.20, lightness: light * 0.08 + 0.92, alpha: 0.20)
    }
    
    /// Aufhellung `lightness` (HSL) auf `lightness * 0.5 + 0.5 ` [0.5 ... 1.0]
    var lightlight : UIColor {
        get {
            var hue    = CGFloat.zero
            var satura = CGFloat.zero
            var light  = CGFloat.zero
            var alpha  = CGFloat.zero
            getHSL(&hue, saturation: &satura, lightness: &light, alpha: &alpha)
            let fak : CGFloat = 0.5
            return UIColor(hue: hue, saturation: satura, lightness: light*(1-fak)+fak, alpha: alpha)
        }
    }
    
    /// Reduktion der `lightness` (HSL) auf 80% des Originalwertes
    var lowlight : UIColor {
        get {
            var hue    = CGFloat.zero
            var satura = CGFloat.zero
            var light  = CGFloat.zero
            var alpha  = CGFloat.zero
            getHSL(&hue, saturation: &satura, lightness: &light, alpha: &alpha)
            return UIColor(hue: hue, saturation: satura, lightness: 0.8*light, alpha: alpha)
        }
    }
    
    /// Reduktion der `lightness` (HSL) auf 50% des Originalwertes
    var darklight : UIColor {
        get {
            var hue    = CGFloat.zero
            var satura = CGFloat.zero
            var light  = CGFloat.zero
            var alpha  = CGFloat.zero
            getHSL(&hue, saturation: &satura, lightness: &light, alpha: &alpha)
            return UIColor(hue: hue, saturation: satura, lightness: 0.5*light, alpha: alpha)
        }
    }
    
    /// Reduktion der `lightness` (HSB) auf 55% des Originalwertes
    var btHighlighted : UIColor {
        get {
            var hue    = CGFloat.zero
            var satura = CGFloat.zero
            var bright = CGFloat.zero
            var alpha  = CGFloat.zero
            getHue(&hue, saturation: &satura, brightness: &bright, alpha: &alpha)
            return UIColor(hue: hue, saturation: satura, brightness: 0.55*bright, alpha: alpha)
        }
    }
}


