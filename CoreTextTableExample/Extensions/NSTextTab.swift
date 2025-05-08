//
//  NSTextTab.swift
//  CoreTextTableExample
//
//  Created by Thomas on 07.05.25.
//

import CoreText
import UIKit       // für NSTextTab / NSTextAlignment

// MARK: - Alignment‑Mapping --------------------------------------------------

private extension NSTextAlignment {
    init(_ ct: CTTextAlignment) {
        switch ct {
        case .left:      self = .left
        case .right:     self = .right
        case .center:    self = .center
        case .justified: self = .justified
        default:         self = .natural
        }
    }
}

private extension CTTextAlignment {
    init(_ ns: NSTextAlignment) {
        switch ns {
        case .left:      self = .left
        case .right:     self = .right
        case .center:    self = .center
        case .justified: self = .justified
        default:         self = .natural
        }
    }
}

// MARK: - CTTextTab → NSTextTab ----------------------------------------------

extension CTTextTab {
    /// Convenience‑Getter: macht aus einem `CTTextTab` einen
    /// funktional identischen `NSTextTab`.
    var nsTab: NSTextTab {
        let align   = NSTextAlignment( CTTextTabGetAlignment(self) )
        let loc     = CGFloat( CTTextTabGetLocation(self) )
        let nsOpts: [NSTextTab.OptionKey : Any] = {
            guard let cf = CTTextTabGetOptions(self) else { return [:] }
            let dict = cf as NSDictionary
            var out: [NSTextTab.OptionKey: Any] = [:]
            for (k, v) in dict { out[NSTextTab.OptionKey(rawValue: k as! String)] = v }
            return out
        }()
        return NSTextTab(textAlignment: align, location: loc, options: nsOpts)
    }
}

// MARK: - NSTextTab → CTTextTab ----------------------------------------------

extension NSTextTab {
    /// Convenience‑Getter: wandelt einen `NSTextTab` in einen
    /// funktional identischen `CTTextTab` um.
    var ctTab: CTTextTab {
        let ctAlign = CTTextAlignment( self.alignment )
        let loc     = Double( self.location )
        let cfOpts: CFDictionary? = {
            guard !self.options.isEmpty else { return nil }
            var dict = [String: Any]()
            for (k, v) in self.options { dict[k.rawValue] = v }
            return dict as CFDictionary
        }()
        return CTTextTabCreate(ctAlign, loc, cfOpts)
    }
}
