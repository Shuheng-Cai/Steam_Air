//
//  CollectionsGameCell.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//  Collections tab — table view cell showing a game's achievement progress.
//

import UIKit

final class CollectionsGameCell: UITableViewCell {

    static let reuseID = "CollectionsGameCell"

    private let coverImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        iv.backgroundColor = UIColor(white: 0.88, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let progressLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let progressBar: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .default)
        p.tintColor = .systemBlue
        p.translatesAutoresizingMaskIntoConstraints = false
        return p
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.hidesWhenStopped = true
        a.translatesAutoresizingMaskIntoConstraints = false
        return a
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator

        contentView.addSubview(coverImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(progressLabel)
        contentView.addSubview(progressBar)
        contentView.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            // Cover image: fixed 60×60 on the left
            coverImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            coverImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 60),
            coverImageView.heightAnchor.constraint(equalToConstant: 60),
            coverImageView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 12),
            coverImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            // Name
            nameLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            nameLabel.topAnchor.constraint(equalTo: coverImageView.topAnchor, constant: 2),

            // Progress text
            progressLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            progressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),

            // Progress bar
            progressBar.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            progressBar.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 6),
            progressBar.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            // Loading spinner (replaces progress when still fetching)
            loadingIndicator.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: coverImageView.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
        nameLabel.text = nil
        progressLabel.text = nil
        progressBar.progress = 0
        progressBar.isHidden = false
        loadingIndicator.stopAnimating()
    }

    // MARK: - Configure

    func configure(game: Game, achievements: GameAchievements?, isLoading: Bool) {
        nameLabel.text = game.name
        GameImageCache.loadImage(from: game.iconURL, into: coverImageView)

        if isLoading {
            progressLabel.text = ""
            progressBar.isHidden = true
            loadingIndicator.startAnimating()
        } else if let achievements {
            loadingIndicator.stopAnimating()
            if achievements.totalCount == 0 {
                progressLabel.text = "No achievements"
                progressBar.isHidden = true
            } else {
                let pct = Int(achievements.progress * 100)
                progressLabel.text = "\(achievements.unlockedCount) / \(achievements.totalCount) achievements · \(pct)%"
                progressBar.isHidden = false
                progressBar.setProgress(achievements.progress, animated: false)
            }
        } else {
            loadingIndicator.stopAnimating()
            progressLabel.text = "No achievement data"
            progressBar.isHidden = true
        }
    }
}
