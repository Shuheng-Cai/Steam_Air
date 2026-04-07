//
//  DealCell.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

internal import UIKit

final class DealCell: UITableViewCell {
    static let reuseID = "DealCell"

    private let thumbImageView: UIImageView = {
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
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let finalPriceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .bold)
        l.textColor = .systemGreen
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
        l.font = .systemFont(ofSize: 12, weight: .bold)
        l.textColor = .white
        l.backgroundColor = .systemGreen
        l.textAlignment = .center
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        contentView.addSubview(thumbImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(finalPriceLabel)
        contentView.addSubview(originalPriceLabel)
        contentView.addSubview(discountBadge)

        NSLayoutConstraint.activate([
            thumbImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            thumbImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            thumbImageView.widthAnchor.constraint(equalToConstant: 100),

            discountBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            discountBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            discountBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 48),
            discountBadge.heightAnchor.constraint(equalToConstant: 24),

            nameLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: discountBadge.leadingAnchor, constant: -8),

            finalPriceLabel.leadingAnchor.constraint(equalTo: thumbImageView.trailingAnchor, constant: 12),
            finalPriceLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            originalPriceLabel.leadingAnchor.constraint(equalTo: finalPriceLabel.trailingAnchor, constant: 6),
            originalPriceLabel.centerYAnchor.constraint(equalTo: finalPriceLabel.centerYAnchor),
        ])
    }

    func configure(with deal: SteamDeal) {
        nameLabel.text = deal.name
        finalPriceLabel.text = deal.formattedFinalPrice
        discountBadge.text = "  -\(deal.discountPercent)%  "
        thumbImageView.image = nil
        if !deal.headerImageURL.isEmpty {
            GameImageCache.loadImage(from: deal.headerImageURL, into: thumbImageView)
        }

        let attrs: [NSAttributedString.Key: Any] = [
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: UIColor.secondaryLabel
        ]
        originalPriceLabel.attributedText = NSAttributedString(
            string: deal.formattedOriginalPrice,
            attributes: attrs
        )
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbImageView.image = nil
        originalPriceLabel.attributedText = nil
    }
}
