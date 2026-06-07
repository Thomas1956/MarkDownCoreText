//
//  ColorPaletteWellContentView.swift
//  CommonCollection
//
//  Created by Thomas on 04.06.26.
//

import UIKit


//--------------------------------------------------------------------------------------------
// MARK: - Kombinierte Palette / UIColorWell Farbauswahl

public class ColorPaletteWellContentView: CommonContentView {
    
    ///---------------------------------------------------------------------------------------
    /// Strukur der Konfiguration, so wie sie TableView oder CollectionView genutzt wird
    public struct Configuration: BasicContentConfiguration {
        public init() {}
        public init(_ content     :  Any? = nil,
                    _ onChange    : ((Any, String?) -> Void)? = nil,
                    height        : CGFloat? = nil,
                    width         : CGFloat? = nil,
                    layoutMargins : LayoutMargins = .zero)
        {
            self.content       = content
            self.onChange      = onChange
            self.height        = height
            self.width         = width
            self.layoutMargins = layoutMargins
        }
        
        /// Daten für den ContentView
        public var content       : Any?
        public var onChange      : ((Any, String?) -> Void)?
        public var height        : CGFloat?
        public var width         : CGFloat?
        public var layoutMargins = LayoutMargins.zero
        
        /// Über diese Funktion wird aus der Konfiguration heraus der ContentView instantiiert
        public func makeContentView() -> UIView & UIContentView {
            return ColorPaletteWellContentView(self)
        }
        
        /// Aktualisierung der Konfiguration in Abhängigkeit vom `state`
        public func updated(for state: UIConfigurationState) -> Self {
            return self
        }
    }
    
    ///---------------------------------------------------------------------------------------
    /// Konfiguration des ContentView
    public override func configure(configuration: UIContentConfiguration) {
        guard let contentData else { return }
        
        selectedColor = contentData.color ?? .black
        paletteItems = contentData.listContent ?? []
        isEditable = contentData.isEditable
        alignment = contentData.blockAlignment ?? .leading
        placement = contentData.contentPlacement ?? .automatic
        paletteWidth = contentData.chipWidth ?? 82
        
        colorWell.isEnabled = isEditable
        colorWell.title = contentData.placeholder ?? contentData.title?.toString() ?? "Farbe"
        colorWell.supportsAlpha = true
        
        isConfiguring = true
        colorWell.selectedColor = selectedColor
        isConfiguring = false
        
        updateSwatch()
        
        /// Ist die Höhe gesetzt ?
        controlHeight = minControlHeight
        if let height = contentConfiguration.height {
            controlHeight = max(height, minControlHeight)
        }
        
        /// Ist die Breite gesetzt ?
        controlWidth = minControlWidth
        if let width = contentConfiguration.width {
            controlWidth = max(width, minControlWidth)
        }
        
        paletteWidthConstraint?.constant = paletteWidth
        paletteHeightConstraint?.constant = controlHeight
        contentWidthConstraint?.constant = contentWidth
        leadingConstraint?.isActive = alignment == .leading
        trailingConstraint?.isActive = alignment != .leading
        
        /// Debug-Info auswerten
        checkDebugInfo(contentData.title)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Controls und Variablen im Content
    
    private let stackView = UIStackView()
    private let backgroundView = UIView()
    private let paletteButton = UIButton(type: .custom)
    private let swatchView = UIView()
    private let colorWell = UIColorWell()
    
    private var selectedColor: UIColor = .black
    private var paletteItems = [KeyText]()
    private var isEditable = true
    private var isConfiguring = false
    private var paletteWidth: CGFloat = 82
    
    private var paletteWidthConstraint: NSLayoutConstraint?
    private var paletteHeightConstraint: NSLayoutConstraint?
    private var contentWidthConstraint: NSLayoutConstraint?
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?
    
    /// Minimale Breite und Höhe des Controls
    var minControlWidth: CGFloat { paletteWidth + UIColorWell().intrinsicContentSize.width }
    var minControlHeight: CGFloat { max(UIColorWell().intrinsicContentSize.height, 30) }
    
    var alignment : ContentParam.Alignment = .leading       /// Alignment des Controls (default: leading)
    var placement : ContentParam.Placement = .automatic     /// Lage der Komponenten im Control
    
    ///---------------------------------------------------------------------------------------
    /// Initialisieren
    public override init(_ configuration: UIContentConfiguration) {
        super.init(configuration)
        
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false

        /// Gemeinsame Kapsel-Hülle hinter Swatch und ColorWell (analog zum Pages-Control).
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.backgroundColor = .tertiarySystemFill
        backgroundView.isUserInteractionEnabled = false
        backgroundView.layer.cornerCurve = .continuous

        paletteButton.translatesAutoresizingMaskIntoConstraints = false
        paletteButton.backgroundColor = .clear
        paletteButton.addTarget(self, action: #selector(actionPalette(_:)), for: .touchUpInside)

        swatchView.translatesAutoresizingMaskIntoConstraints = false
        swatchView.isUserInteractionEnabled = false
        swatchView.layer.cornerRadius = 6
        swatchView.layer.cornerCurve = .continuous

        colorWell.setContentCompressionResistancePriority(.required, for: .horizontal)
        colorWell.setContentCompressionResistancePriority(.required, for: .vertical)
        colorWell.translatesAutoresizingMaskIntoConstraints = false
        colorWell.addTarget(self, action: #selector(actionColorChanged(_:)), for: .valueChanged)

        addSubview(backgroundView)
        addSubview(stackView)
        stackView.addArrangedSubview(paletteButton)
        stackView.addArrangedSubview(colorWell)
        paletteButton.addSubview(swatchView)
        
        let layoutMargins = contentConfiguration.layoutMargins
        let offset = (layoutMargins.top - layoutMargins.bottom) / 2
        
        let paletteWidthConstraint = paletteButton.widthAnchor.constraint(equalToConstant: paletteWidth)
        let paletteHeightConstraint = paletteButton.heightAnchor.constraint(equalToConstant: controlHeight)
        let contentWidthConstraint = widthAnchor.constraint(greaterThanOrEqualToConstant: contentWidth)
        let leadingConstraint = stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: layoutMargins.leading)
        let trailingConstraint = stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -layoutMargins.trailing-2)
        
        self.paletteWidthConstraint = paletteWidthConstraint
        self.paletteHeightConstraint = paletteHeightConstraint
        self.contentWidthConstraint = contentWidthConstraint
        self.leadingConstraint = leadingConstraint
        self.trailingConstraint = trailingConstraint
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: offset),
            paletteWidthConstraint,
            paletteHeightConstraint,
            contentWidthConstraint,

            /// Kapsel-Hülle umschließt Swatch und ColorWell mit etwas Spiel.
            backgroundView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -2),
            backgroundView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 2),
            backgroundView.topAnchor.constraint(equalTo: stackView.topAnchor, constant: -1),
            backgroundView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 1),

            swatchView.leadingAnchor.constraint(equalTo: paletteButton.leadingAnchor, constant: 4),
            swatchView.trailingAnchor.constraint(equalTo: paletteButton.trailingAnchor, constant: -4),
            swatchView.topAnchor.constraint(equalTo: paletteButton.topAnchor, constant: 4),
            swatchView.bottomAnchor.constraint(equalTo: paletteButton.bottomAnchor, constant: -4),
        ])
        
        if alignment == .leading {
            leadingConstraint.isActive = true
        } else {
            trailingConstraint.isActive = true
        }
        
        setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        configure(configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    ///---------------------------------------------------------------------------------------
    /// Kapsel-Eckenradius dynamisch an die Höhe anpassen
    public override func layoutSubviews() {
        super.layoutSubviews()
        backgroundView.layer.cornerRadius = backgroundView.bounds.height / 2
    }

    ///---------------------------------------------------------------------------------------
    /// Darstellung des Swatches aktualisieren
    private func updateSwatch() {
        paletteButton.isEnabled = isEditable
        backgroundView.alpha = isEditable ? 1 : 0.45
        swatchView.backgroundColor = selectedColor
    }
    
    ///---------------------------------------------------------------------------------------
    /// Auswahl übernehmen
    private func setColor(_ color: UIColor) {
        selectedColor = color
        updateSwatch()
        
        isConfiguring = true
        colorWell.selectedColor = color
        isConfiguring = false
        
        contentConfiguration.onChange?(color, contentData?.key)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Aktion des Palette Buttons
    @objc private func actionPalette(_ sender: UIButton) {
        guard isEditable, let parentViewController else { return }
        
        let viewController = ColorPaletteViewController(items: paletteItems, selectedColor: selectedColor) { [weak self] color in
            self?.setColor(color)
        }
        viewController.modalPresentationStyle = .popover
        viewController.popoverPresentationController?.sourceView = sender
        viewController.popoverPresentationController?.sourceRect = sender.bounds
        viewController.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        
        parentViewController.present(viewController, animated: true)
    }
    
    ///---------------------------------------------------------------------------------------
    /// Aktion des Color Wells
    @objc private func actionColorChanged(_ sender: UIColorWell) {
        guard !isConfiguring,
              let color = sender.selectedColor
        else { return }
        
        setColor(color)
    }
}
