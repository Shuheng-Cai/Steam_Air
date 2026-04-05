//
//  LibraryGameCell.swift
//  Steam_Air
//
//  Created by  Lucy K Y XU on 4/5/26.
//

import UIKit

final class LibraryGameCell: UICollectionViewCell {

    static let reuseID = "LibraryGameCell"

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(white: 0.88, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let statusLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(coverImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            coverImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            coverImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            coverImageView.heightAnchor.constraint(equalTo: coverImageView.widthAnchor, multiplier: 3.0 / 2.0),

            nameLabel.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 6),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            statusLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
        nameLabel.text = nil
        statusLabel.text = nil
    }

    func configure(with game: Game) {
        nameLabel.text = game.name
        statusLabel.text = game.libraryStatusText
        GameImageCache.loadImage(from: game.iconURL, into: coverImageView)
    }
}

private extension Game {
    var libraryStatusText: String {
        if let lastPlayed = lastPlayedDate {
            let days = Int(Date().timeIntervalSince(lastPlayed) / 86400)
            switch days {
            case 0:      return "Last played today"
            case 1:      return "Last played yesterday"
            case 2..<7:  return "Last played \(days) days ago"
            case 7..<30:
                let w = days / 7
                return "Last played \(w) week\(w == 1 ? "" : "s") ago"
            case 30..<365:
                let m = days / 30
                return "Last played \(m) month\(m == 1 ? "" : "s") ago"
            default:
                let y = days / 365
                return "Last played \(y) year\(y == 1 ? "" : "s") ago"
            }
        }
        if playtime_2weeks > 0 { return "Played recently" }
        let hours = playtime_forever / 60
        return hours > 0 ? "\(hours) hrs played" : "Never played"
    }
}
