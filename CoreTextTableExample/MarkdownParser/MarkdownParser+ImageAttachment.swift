//
//  MarkdownParser+ImageAttachment.swift
//  CoreTextTableExample
//
//  Created by Thomas on 01.05.25.
//

import UIKit


// -------------------------------------------------------------------------------------------
// MARK: - Extension NSAttributedString.Key für die Image Attachments

public extension NSAttributedString.Key {
    /// Name für das Einfügen in den String
    static let myImageAttachment = NSAttributedString.Key("MyImageAttachment")
    
    /// Bridge-Name für Swift-Attribut \.imageURL
    static let imageURL = NSAttributedString.Key("NSImageURL")
    
    /// Alias für kCTRunDelegateAttributeName
    static let runDelegate = NSAttributedString.Key(kCTRunDelegateAttributeName as String)
}


//--------------------------------------------------------------------------------------------
// MARK: - Payload-Klasse, damit wir Größe + Bild parat haben

public final class ImageAttachment {
    let image: UIImage
    /// Native Bildgröße (so wie sie vom Markdown ohne Skalierung käme). Bleibt unverändert,
    /// damit `adjustImageSizes(maxWidth:)` auf das Original zurückgreifen kann.
    let nativeSize: CGSize
    /// Aktuell beim Rendern verwendete Größe. Wird vom Layout zur Anpassung an die
    /// verfügbare Spaltenbreite ggf. überschrieben (nur falls keine explizite Größe gesetzt).
    var size: CGSize
    let font: CTFont
    let baselineOffset: CGFloat
    /// `true`, wenn das Markdown eine explizite `:size`-Angabe enthält – dann wird die
    /// Größe vom Layout nicht angefasst.
    let hasExplicitSize: Bool

    init(image: UIImage,
         size: CGSize,
         font: CTFont,
         baselineOffset: CGFloat = 0,
         hasExplicitSize: Bool = false) {
        self.image           = image
        self.nativeSize      = size
        self.size            = size
        self.font            = font
        self.baselineOffset  = baselineOffset
        self.hasExplicitSize = hasExplicitSize
    }
}

//--------------------------------------------------------------------------------------------
// MARK: - Erzeugen der Delegate für die Image Attachments

@inline(__always)
public func makeRunDelegate(for attachment: ImageAttachment) -> CTRunDelegate {
    //  payload behalten, damit Core Text es im Callback erreicht
    let payloadPtr = Unmanaged.passRetained(attachment).toOpaque()
    //  callbacks zeigt auf die oben definierte Singleton-Struct
    return CTRunDelegateCreate(&runDelegateCallbacks, payloadPtr)!
}

///-------------------------------------------------------------------------------------------
/// Callbacks nur die Delegates (EINMAL anlegen)
///
private var runDelegateCallbacks: CTRunDelegateCallbacks = {
    var cb = CTRunDelegateCallbacks(
        version: kCTRunDelegateVersion1,
        dealloc: { ptr in
            Unmanaged<ImageAttachment>.fromOpaque(ptr).release()
        },
        /// Berechnung der Oberlänge
        getAscent: { ptr in
            let attach = Unmanaged<ImageAttachment>
                .fromOpaque(ptr)
                .takeUnretainedValue()

            let xh = CTFontGetXHeight(attach.font)            
            let baseAscent = attach.size.height / 2 + xh * 0.55 + 0.2
            return baseAscent + attach.baselineOffset // min(max(baseAscent + attach.baselineOffset, 0), attach.size.height)
        },
        
        /// Berechnung der Unterlänge
        getDescent: { ptr in
            let attach = Unmanaged<ImageAttachment>
                .fromOpaque(ptr)
                .takeUnretainedValue()

            let xh = CTFontGetXHeight(attach.font)
            let baseAscent = attach.size.height / 2 + xh * 0.55 + 0.2
            let ascent = baseAscent + attach.baselineOffset //min(max(baseAscent + attach.baselineOffset, 0), attach.size.height)
            return attach.size.height - ascent
        },

        /// Berechnung der Breite
        getWidth: { ptr in
            let attach = Unmanaged<ImageAttachment>
                         .fromOpaque(ptr)
                         .takeUnretainedValue()
            return attach.size.width
        }

    )
    return cb
}()

