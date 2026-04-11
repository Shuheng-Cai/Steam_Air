//
//  DetailViewController.swift
//  Steam_Air
//
//  Created by  csh's computer on 4/3/26.
//

internal import UIKit

class DetailViewController: UIViewController {

    var Game: Game?

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 14
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let heroImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private var heroHeightConstraint: NSLayoutConstraint?

    private let gameInfoCard = UIView()
    private let gameIconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = UIColor(white: 0.88, alpha: 1)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let gameNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let gameMetaLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var viewOnSteamButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "View on Steam"
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .large

        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(viewOnSteamTapped(_:)), for: .touchUpInside)
        return btn
    }()

    private lazy var wishlistPrimaryButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.cornerStyle = .large
        config.baseForegroundColor = .systemBlue
        config.baseBackgroundColor = .secondarySystemBackground

        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(wishlistButtonTapped(_:)), for: .touchUpInside)
        return btn
    }()

    private let reviewsCard = DetailInfoCardView(title: "Reviews", subtitle: "Very Positive · 1.4M reviews")
    private let priceHistoryCard = DetailInfoCardView(title: "Price History", subtitle: "Track sales and lowest price")

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "Detail"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: nil,
            action: nil
        )

        setupLayout()
        bindData()
        updateWishlistButton()
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])

        contentStack.addArrangedSubview(heroImageView)
        heroHeightConstraint = heroImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.33)
        heroHeightConstraint?.isActive = true

        setupGameInfoCard()
        contentStack.addArrangedSubview(gameInfoCard)

        contentStack.addArrangedSubview(reviewsCard)
        contentStack.addArrangedSubview(priceHistoryCard)

        let tap = UITapGestureRecognizer(target: self, action: #selector(priceHistoryTapped))
        priceHistoryCard.addGestureRecognizer(tap)
        priceHistoryCard.isUserInteractionEnabled = true
    }

    private func setupGameInfoCard() {
        styleCard(gameInfoCard)

        gameInfoCard.addSubview(gameIconImageView)
        gameInfoCard.addSubview(gameNameLabel)
        gameInfoCard.addSubview(gameMetaLabel)
        gameInfoCard.addSubview(viewOnSteamButton)
        gameInfoCard.addSubview(wishlistPrimaryButton)

        NSLayoutConstraint.activate([
            gameIconImageView.topAnchor.constraint(equalTo: gameInfoCard.topAnchor, constant: 12),
            gameIconImageView.leadingAnchor.constraint(equalTo: gameInfoCard.leadingAnchor, constant: 12),
            gameIconImageView.widthAnchor.constraint(equalToConstant: 56),
            gameIconImageView.heightAnchor.constraint(equalToConstant: 56),

            gameNameLabel.topAnchor.constraint(equalTo: gameIconImageView.topAnchor),
            gameNameLabel.leadingAnchor.constraint(equalTo: gameIconImageView.trailingAnchor, constant: 12),
            gameNameLabel.trailingAnchor.constraint(equalTo: gameInfoCard.trailingAnchor, constant: -12),

            gameMetaLabel.topAnchor.constraint(equalTo: gameNameLabel.bottomAnchor, constant: 2),
            gameMetaLabel.leadingAnchor.constraint(equalTo: gameNameLabel.leadingAnchor),
            gameMetaLabel.trailingAnchor.constraint(equalTo: gameNameLabel.trailingAnchor),

            viewOnSteamButton.topAnchor.constraint(equalTo: gameIconImageView.bottomAnchor, constant: 14),
            viewOnSteamButton.leadingAnchor.constraint(equalTo: gameInfoCard.leadingAnchor, constant: 12),
            viewOnSteamButton.trailingAnchor.constraint(equalTo: gameInfoCard.trailingAnchor, constant: -12),
            viewOnSteamButton.heightAnchor.constraint(equalToConstant: 46),

            wishlistPrimaryButton.topAnchor.constraint(equalTo: viewOnSteamButton.bottomAnchor, constant: 10),
            wishlistPrimaryButton.leadingAnchor.constraint(equalTo: gameInfoCard.leadingAnchor, constant: 12),
            wishlistPrimaryButton.trailingAnchor.constraint(equalTo: gameInfoCard.trailingAnchor, constant: -12),
            wishlistPrimaryButton.heightAnchor.constraint(equalToConstant: 46),
            wishlistPrimaryButton.bottomAnchor.constraint(equalTo: gameInfoCard.bottomAnchor, constant: -12),
        ])
    }

    private func bindData() {
        guard let game = Game else { return }

        gameNameLabel.text = game.name
        gameMetaLabel.text = game.metaDetailText

        GameImageCache.loadImage(from: game.iconURL, into: heroImageView)
        GameImageCache.loadImage(from: game.iconURL, into: gameIconImageView)
    }

    private func styleCard(_ view: UIView) {
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    private func updateWishlistButton() {
        guard let appid = Game?.appid else { return }
        let inWishlist = LocalWishlistManager.shared.contains(appid)

        var config = wishlistPrimaryButton.configuration ?? UIButton.Configuration.tinted()
        config.title = inWishlist ? "Added to Wishlist" : "Add to Wishlist"
        config.baseForegroundColor = inWishlist ? .systemBlue : .systemBlue
        config.baseBackgroundColor = .secondarySystemBackground
        config.cornerStyle = .large
        wishlistPrimaryButton.configuration = config
    }

    @IBAction func wishlistButtonTapped(_ sender: UIButton) {
        guard let game = Game else { return }
        let manager = LocalWishlistManager.shared
        if manager.contains(game.appid) {
            manager.remove(appid: game.appid)
        } else {
            manager.add(game: game)
        }
        updateWishlistButton()
    }

    @IBAction func viewOnSteamTapped(_ sender: UIButton) {
        guard let appid = Game?.appid,
              let url = URL(string: "https://store.steampowered.com/app/\(appid)") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func priceHistoryTapped() {
        guard let game = Game else { return }
        let vc = PriceHistoryViewController()
        vc.wishlistItem = WishlistItem(
            appid: game.appid,
            name: game.name,
            iconURL: game.iconURL,
            currentPrice: nil,
            originalPrice: nil,
            discountPercent: 0,
            isFreeGame: false,
            addedDate: nil,
            priority: 0
        )
        navigationController?.pushViewController(vc, animated: true)
    }
}

private extension Game {
    var metaDetailText: String {
        let hours = max(0, playtime_forever / 60)

        let playedText: String
        if hours == 0 {
            playedText = "Not played yet"
        } else {
            playedText = "\(hours) hrs played"
        }

        let lastPlayedText: String
        if let date = lastPlayedDate {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .none
            lastPlayedText = "Last played \(f.string(from: date))"
        } else {
            lastPlayedText = "Last played unknown"
        }

        return "\(playedText) · \(lastPlayedText)"
    }
}

private final class DetailInfoCardView: UIView {

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(title: String, subtitle: String) {
        super.init(frame: .zero)

        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        subtitleLabel.text = subtitle

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}
