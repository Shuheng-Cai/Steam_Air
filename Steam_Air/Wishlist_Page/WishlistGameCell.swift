//
//  WishlistGameCell.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import UIKit

final class WishlistGameCell: UITableViewCell {
    static let reuseID = "WishlistGameCell"

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

        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            coverImageView.widthAnchor.constraint(equalToConstant: 46),

            discountBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
            discountBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            discountBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            discountBadge.heightAnchor.constraint(equalToConstant: 22),

            nameLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: discountBadge.leadingAnchor, constant: -8),

            priceLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            priceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

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
