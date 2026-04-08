//
//  WishlistGameCell.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

internal import UIKit

final class WishlistGameCell: UITableViewCell {
    static let reuseID = "WishlistGameCell"

    private static let coverWidth: CGFloat  = 60
    private static let coverHeight: CGFloat = 90   // 60 × 1.5

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let priceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .bold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let originalPriceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let discountBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .bold)
        l.textColor = .white
        l.backgroundColor = .systemGreen
        l.textAlignment = .center
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        contentView.addSubview(coverImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(originalPriceLabel)
        contentView.addSubview(discountBadge)

        let vPad: CGFloat = 10

        NSLayoutConstraint.activate([
            // Cover: fixed size anchored to leading + vertically centred
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: Self.coverWidth),
            coverImageView.heightAnchor.constraint(equalToConstant: Self.coverHeight),

            // Cell must be tall enough to fit the cover
            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: Self.coverHeight + vPad * 2),

            // Discount badge — right edge, vertically centred
            discountBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            discountBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            discountBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            discountBadge.heightAnchor.constraint(equalToConstant: 22),

            // Name label — top-aligned next to cover
            nameLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: discountBadge.leadingAnchor, constant: -8),

            // Price label — bottom-aligned next to cover
            priceLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            priceLabel.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),

            originalPriceLabel.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 6),
            originalPriceLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
        ])
    }

    func configure(with item: WishlistItem) {
        nameLabel.text = item.name
        priceLabel.text = item.formattedCurrentPrice
        coverImageView.image = nil
        GameImageCache.loadImage(from: item.iconURL, into: coverImageView)

        if item.isOnSale {
            discountBadge.isHidden = false
            discountBadge.text = "  -\(item.discountPercent)%  "
        } else {
            discountBadge.isHidden = true
        }

        if let original = item.originalPrice {
            let attrs: [NSAttributedString.Key: Any] = [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.secondaryLabel
            ]
            originalPriceLabel.attributedText = NSAttributedString(
                string: String(format: "$%.2f", original),
                attributes: attrs
            )
        } else {
            originalPriceLabel.attributedText = nil
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
        discountBadge.isHidden = true
        originalPriceLabel.attributedText = nil
    }
}
