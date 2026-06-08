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
    
    ///---------------------------------------------------------------------------------------
    /// Aus der Textfarbe abgeleitete Farbe für Balken / Striche / Rahmen / Ruler
    /// bzw. für Hintergründe. Beide Properties teilen sich denselben Algorithmus mit
    /// unterschiedlichen Parameter-Sätzen (Sättigung + Ziel-Helligkeit) und führen bei
    /// neutralen Textfarben (Original-Sättigung < 5 %) den iOS-typischen leichten
    /// Blaustich (Hue 240°) ein.

    private func derived(saturation saturationFactor: CGFloat,
                         minimum    minimumSaturation: CGFloat,
                         lightness  targetLightness:  CGFloat) -> UIColor {
        var hue = CGFloat.zero, satura = CGFloat.zero, light = CGFloat.zero, alpha = CGFloat.zero
        getHSL(&hue, saturation: &satura, lightness: &light, alpha: &alpha)

        let systemHue: CGFloat = 240.0 / 360.0
        let finalHue = satura < 0.05 ? systemHue : hue
        let finalSaturation = max(satura * saturationFactor, minimumSaturation)
        return UIColor(hue: finalHue, saturation: finalSaturation,
                       lightness: targetLightness, alpha: 1)
    }

    /// Aus der Textfarbe abgeleitete Farbe für Balken, Striche, Rahmen und den Ruler.
    /// Ziel-Anker bei neutraler Textfarbe ≈ `systemGray4` (RGB 209, 209, 214).
    var derivedStrokeColor: UIColor {
        derived(saturation: 0.30, minimum: 0.06, lightness: 0.83)
    }

    /// Aus der Textfarbe abgeleitete Hintergrundfarbe für BlockQuote und CodeBlock.
    /// Ziel-Anker bei neutraler Textfarbe ≈ `systemGray6` (RGB 242, 242, 247).
    var derivedFillColor: UIColor {
        derived(saturation: 0.20, minimum: 0.238, lightness: 0.96)
    }

    /// Aus der Textfarbe abgeleitete Tabellen-Header-Hintergrundfarbe.
    /// Ziel-Anker bei neutraler Textfarbe ≈ `systemGray5` (RGB 229, 229, 233).
    var derivedHeaderFillColor: UIColor {
        derived(saturation: 0.25, minimum: 0.083, lightness: 0.906)
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


