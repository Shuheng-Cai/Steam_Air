//
//  NotificationsViewController.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import UIKit

final class NotificationsViewController: UIViewController {

    var wishlistItems: [WishlistItem] = []

    private var onSaleItems: [WishlistItem] {
        wishlistItems.filter { $0.isOnSale }
    }

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(PriceAlertCell.self, forCellReuseIdentifier: PriceAlertCell.reuseID)
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "BasicCell")
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Notifications"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain, target: self, action: #selector(moreTapped)
        )
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        tableView.dataSource = self
        tableView.delegate = self
    }

    @objc private func moreTapped() {}
}

extension NotificationsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 3 }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "PRICE ALERTS"
        case 1: return "NEW RELEASES"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return max(1, onSaleItems.count)
        case 1: return 1
        case 2: return 1
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            if onSaleItems.isEmpty {
                let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
                var config = cell.defaultContentConfiguration()
                config.text = "No active price alerts"
                config.textProperties.color = .secondaryLabel
                cell.contentConfiguration = config
                cell.selectionStyle = .none
                return cell
            }
            let cell = tableView.dequeueReusableCell(
                withIdentifier: PriceAlertCell.reuseID, for: indexPath
            ) as! PriceAlertCell
            cell.configure(with: onSaleItems[indexPath.row])
            return cell

        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = "New release notifications"
            config.secondaryText = "Based on your wishlist and follows"
            config.image = UIImage(systemName: "bell.badge")
            config.imageProperties.tintColor = .secondaryLabel
            cell.contentConfiguration = config
            cell.selectionStyle = .none
            return cell

        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)
            var config = cell.defaultContentConfiguration()
            config.text = "Notification Preferences"
            config.secondaryText = "Price drops, wishlist updates, and new releases."
            config.image = UIImage(systemName: "bell.badge.fill")
            config.imageProperties.tintColor = .systemBlue
            cell.contentConfiguration = config
            cell.accessoryType = .disclosureIndicator
            return cell

        default:
            return UITableViewCell()
        }
    }
}

extension NotificationsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == 0 && !onSaleItems.isEmpty ? 72 : UITableView.automaticDimension
    }
}

private final class PriceAlertCell: UITableViewCell {
    static let reuseID = "PriceAlertCell"

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 4
        iv.backgroundColor = .tertiarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(coverImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            coverImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            coverImageView.widthAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            subtitleLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            subtitleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with item: WishlistItem) {
        nameLabel.text = item.name
        subtitleLabel.text = "Now \(item.formattedCurrentPrice) · -\(item.discountPercent)% off"
        coverImageView.image = nil
        GameImageCache.loadImage(from: item.iconURL, into: coverImageView)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
    }
}
