//
//  MarkdownParser+Font.swift
//  MarkdownParser
//
//  Created by Thomas on 19.10.24.
//

import UIKit

//--------------------------------------------------------------------------------------------
// MARK: - Kursiver Font mit Bold

extension UIFont {
    
//    class func italicSystemFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular)-> UIFont {
//        let font = UIFont.systemFont(ofSize: size, weight: weight)
//        switch weight {
//        case .ultraLight, .light, .thin, .regular:
//            return font.withTraits(.traitItalic, ofSize: size)
//        case .medium, .semibold, .bold, .heavy, .black:
//            return font.withTraits(.traitBold, .traitItalic, ofSize: size)
//        default:
//            return UIFont.italicSystemFont(ofSize: size)
//        }
//    }
//    
//    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits..., ofSize size: CGFloat) -> UIFont {
//        let descriptor = self.fontDescriptor
//            .withSymbolicTraits(UIFontDescriptor.SymbolicTraits(traits))
//        return UIFont(descriptor: descriptor!, size: size)
//    }
//    
    var weight: UIFont.Weight {
        guard let traits = fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any],
              let weightValue = traits[.weight] as? CGFloat else { return .regular }
        
        let weight = UIFont.Weight(rawValue: weightValue)
        return weight
    }
}

