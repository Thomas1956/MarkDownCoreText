//
//  ColorPaletteViewController.swift
//  CommonCollection
//
//  Created by Thomas on 04.06.26.
//

import UIKit


//--------------------------------------------------------------------------------------------
// MARK: - Palette View Controller fuer Farbauswahl

final class ColorPaletteViewController: UIViewController {
    
    //----------------------------------------------------------------------------------------
    // MARK: - Initialisierung
    
    init(items: [KeyText], selectedColor: UIColor, onSelect: @escaping (UIColor) -> Void) {
        self.items = Self.colorItems(from: items)
        self.selectedColor = selectedColor
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = Self.preferredSize(for: self.items.count)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Parameter
    
    private struct PaletteItem: Hashable {
        let color: UIColor
        let name: String?
    }
    
    private let items: [PaletteItem]
    private var selectedColor: UIColor
    private let onSelect: (UIColor) -> Void
    
    private static let columns = 6
    private static let itemSize = CGSize(width: 56, height: 34)
    private static let spacing: CGFloat = 2
    private static let contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
    
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(ColorPaletteCell.self, forCellWithReuseIdentifier: ColorPaletteCell.reuseID)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    private static func colorItems(from keyTexts: [KeyText]) -> [PaletteItem] {
        let colors = keyTexts.compactMap { item -> PaletteItem? in
            let color = item.value as? UIColor ?? item.value?.base as? UIColor ?? item.color
            guard let color else { return nil }
            return PaletteItem(color: color, name: item.text)
        }
        
        if !colors.isEmpty { return colors }
        return defaultColors.map { PaletteItem(color: $0, name: nil) }
    }
    
    private static var defaultColors: [UIColor] {
        [.black, .darkGray, .gray, .lightGray, .white,
         .systemBlue, .systemMint, .systemGreen, .systemYellow, .systemOrange, .systemRed, .systemPink,
         .systemIndigo, .systemTeal, .systemPurple]
    }
    
    private static func preferredSize(for count: Int) -> CGSize {
        let rows = max(1, Int(ceil(Double(count) / Double(columns))))
        let width = contentInsets.leading + contentInsets.trailing + CGFloat(columns) * itemSize.width + CGFloat(columns - 1) * spacing
        let height = contentInsets.top + contentInsets.bottom + CGFloat(rows) * itemSize.height + CGFloat(max(0, rows - 1)) * spacing
        return CGSize(width: width, height: height)
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    //----------------------------------------------------------------------------------------
    // MARK: - Layout
    
    private func createLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(Self.itemSize.width),
                                              heightDimension: .absolute(Self.itemSize.height))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(Self.itemSize.width * CGFloat(Self.columns) + Self.spacing * CGFloat(Self.columns - 1)),
                                               heightDimension: .absolute(Self.itemSize.height))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: Self.columns)
        group.interItemSpacing = .fixed(Self.spacing)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = Self.spacing
        section.contentInsets = Self.contentInsets
        return UICollectionViewCompositionalLayout(section: section)
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - UICollectionViewDataSource / UICollectionViewDelegate

extension ColorPaletteViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ColorPaletteCell.reuseID, for: indexPath) as! ColorPaletteCell
        let item = items[indexPath.item]
        cell.configure(color: item.color, selected: item.color == selectedColor)
        cell.accessibilityLabel = item.name
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let color = items[indexPath.item].color
        selectedColor = color
        onSelect(color)
        dismiss(animated: true)
    }
}


//--------------------------------------------------------------------------------------------
// MARK: - ColorPaletteCell

private final class ColorPaletteCell: UICollectionViewCell {
    
    static let reuseID = "ColorPaletteCell"
    
    private let swatchView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        swatchView.translatesAutoresizingMaskIntoConstraints = false
        swatchView.layer.borderColor = UIColor.separator.cgColor
        swatchView.layer.borderWidth = 1
        contentView.addSubview(swatchView)
        NSLayoutConstraint.activate([
            swatchView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            swatchView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            swatchView.topAnchor.constraint(equalTo: contentView.topAnchor),
            swatchView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        swatchView.layer.borderColor = UIColor.separator.cgColor
        swatchView.layer.borderWidth = 1
    }
    
    func configure(color: UIColor, selected: Bool) {
        swatchView.backgroundColor = color
        swatchView.layer.borderColor = selected ? UIColor.label.cgColor : UIColor.separator.cgColor
        swatchView.layer.borderWidth = selected ? 4 : 1
    }
}
