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

        let reviewsTap = UITapGestureRecognizer(target: self, action: #selector(reviewsTapped))
        reviewsCard.addGestureRecognizer(reviewsTap)
        reviewsCard.isUserInteractionEnabled = true

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
        reviewsCard.updateSubtitle("Loading reviews...")

        GameImageCache.loadImage(from: game.iconURL, into: heroImageView)
        GameImageCache.loadImage(from: game.iconURL, into: gameIconImageView)
        fetchReviewSummary(appid: game.appid)
    }

    private func fetchReviewSummary(appid: Int) {
        var components = URLComponents(string: "https://store.steampowered.com/appreviews/\(appid)")
        components?.queryItems = [
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "language", value: "all"),
            URLQueryItem(name: "purchase_type", value: "all"),
            URLQueryItem(name: "filter", value: "all"),
            URLQueryItem(name: "num_per_page", value: "0"),
            URLQueryItem(name: "cursor", value: "*"),
        ]

        guard let url = components?.url else {
            reviewsCard.updateSubtitle("No review data")
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let data = data, error == nil else {
                    self.reviewsCard.updateSubtitle("No review data")
                    return
                }

                do {
                    let response = try JSONDecoder().decode(SteamReviewSummaryResponse.self, from: data)
                    guard response.success == 1, let summary = response.query_summary else {
                        self.reviewsCard.updateSubtitle("No review data")
                        return
                    }

                    let score = summary.review_score_desc.trimmingCharacters(in: .whitespacesAndNewlines)
                    let reviewCount = NumberFormatter.localizedString(from: NSNumber(value: summary.total_reviews), number: .decimal)
                    self.reviewsCard.updateSubtitle("\(score) · \(reviewCount) reviews")
                } catch {
                    self.reviewsCard.updateSubtitle("No review data")
                }
            }
        }.resume()
    }

    @objc private func reviewsTapped() {
        guard let game = Game else { return }
        let vc = ReviewsListViewController(appid: game.appid)
        navigationController?.pushViewController(vc, animated: true)
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

private struct SteamReviewSummaryResponse: Decodable {
    let success: Int
    let query_summary: SteamReviewQuerySummary?
}

private struct SteamReviewQuerySummary: Decodable {
    let review_score_desc: String
    let total_reviews: Int
}

private struct SteamReviewsPageResponse: Decodable {
    let success: Int
    let reviews: [SteamReviewItem]
}

private struct SteamReviewItem: Decodable {
    let author: SteamReviewAuthor
    let review: String
    let timestamp_created: TimeInterval
    let voted_up: Bool
}

private struct SteamReviewAuthor: Decodable {
    let steamid: String
}

private struct SteamPlayerSummariesResponse: Decodable {
    let response: SteamPlayerContainer
}

private struct SteamPlayerContainer: Decodable {
    let players: [SteamPlayer]
}

private struct SteamPlayer: Decodable {
    let steamid: String
    let personaname: String
}

private struct DisplayReview {
    let userName: String
    let content: String
    let createdAt: Date
    let recommended: Bool
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

    func updateSubtitle(_ text: String) {
        subtitleLabel.text = text
    }
}

private final class ReviewsListViewController: UIViewController {

    private let appid: Int
    private var reviews: [DisplayReview] = []

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.estimatedRowHeight = 120
        tv.rowHeight = UITableView.automaticDimension
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No reviews found"
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 14)
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    init(appid: Int) {
        self.appid = appid
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Reviews"

        setupLayout()
        tableView.dataSource = self
        tableView.register(ReviewItemCell.self, forCellReuseIdentifier: ReviewItemCell.reuseID)
        loadReviews()
    }

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func loadReviews() {
        spinner.startAnimating()

        var components = URLComponents(string: "https://store.steampowered.com/appreviews/\(appid)")
        components?.queryItems = [
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "language", value: "all"),
            URLQueryItem(name: "purchase_type", value: "all"),
            URLQueryItem(name: "filter", value: "recent"),
            URLQueryItem(name: "num_per_page", value: "30"),
            URLQueryItem(name: "cursor", value: "*"),
        ]

        guard let url = components?.url else {
            spinner.stopAnimating()
            showEmpty()
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let data = data, error == nil else {
                    self.spinner.stopAnimating()
                    self.showEmpty()
                    return
                }

                do {
                    let page = try JSONDecoder().decode(SteamReviewsPageResponse.self, from: data)
                    guard page.success == 1, !page.reviews.isEmpty else {
                        self.spinner.stopAnimating()
                        self.showEmpty()
                        return
                    }

                    let steamIDs = Array(Set(page.reviews.map { $0.author.steamid }))
                    self.resolveUserNames(for: steamIDs) { nameMap in
                        self.spinner.stopAnimating()
                        self.reviews = page.reviews.map { item in
                            let cleanText = item.review.trimmingCharacters(in: .whitespacesAndNewlines)
                            return DisplayReview(
                                userName: nameMap[item.author.steamid] ?? "User \(item.author.steamid.suffix(6))",
                                content: cleanText.isEmpty ? "(No text)" : cleanText,
                                createdAt: Date(timeIntervalSince1970: item.timestamp_created),
                                recommended: item.voted_up
                            )
                        }
                        self.emptyLabel.isHidden = !self.reviews.isEmpty
                        self.tableView.reloadData()
                    }
                } catch {
                    self.spinner.stopAnimating()
                    self.showEmpty()
                }
            }
        }.resume()
    }

    private func resolveUserNames(for steamIDs: [String], completion: @escaping ([String: String]) -> Void) {
        guard !steamIDs.isEmpty else {
            completion([:])
            return
        }

        guard let key = Bundle.main.object(forInfoDictionaryKey: "SteamWebAPIKey") as? String,
              !key.isEmpty else {
            completion([:])
            return
        }

        var components = URLComponents(string: "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v2/")
        components?.queryItems = [
            URLQueryItem(name: "key", value: key),
            URLQueryItem(name: "steamids", value: steamIDs.joined(separator: ",")),
        ]

        guard let url = components?.url else {
            completion([:])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            DispatchQueue.main.async {
                guard let data else {
                    completion([:])
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(SteamPlayerSummariesResponse.self, from: data)
                    let map = Dictionary(uniqueKeysWithValues: decoded.response.players.map { ($0.steamid, $0.personaname) })
                    completion(map)
                } catch {
                    completion([:])
                }
            }
        }.resume()
    }

    private func showEmpty() {
        reviews = []
        tableView.reloadData()
        emptyLabel.isHidden = false
    }
}

extension ReviewsListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reviews.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: ReviewItemCell.reuseID,
            for: indexPath
        ) as! ReviewItemCell
        cell.configure(with: reviews[indexPath.row])
        return cell
    }
}

private final class ReviewItemCell: UITableViewCell {

    static let reuseID = "ReviewItemCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 10
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let userLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let recommendationBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textAlignment = .center
        l.layer.cornerRadius = 6
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let contentLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14)
        l.textColor = .label
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(userLabel)
        cardView.addSubview(dateLabel)
        cardView.addSubview(recommendationBadge)
        cardView.addSubview(contentLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            userLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            userLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            userLabel.trailingAnchor.constraint(lessThanOrEqualTo: dateLabel.leadingAnchor, constant: -8),

            dateLabel.centerYAnchor.constraint(equalTo: userLabel.centerYAnchor),
            dateLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            recommendationBadge.topAnchor.constraint(equalTo: userLabel.bottomAnchor, constant: 6),
            recommendationBadge.leadingAnchor.constraint(equalTo: userLabel.leadingAnchor),
            recommendationBadge.heightAnchor.constraint(equalToConstant: 22),
            recommendationBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 110),

            contentLabel.topAnchor.constraint(equalTo: recommendationBadge.bottomAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: userLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: dateLabel.trailingAnchor),
            contentLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        userLabel.text = nil
        dateLabel.text = nil
        recommendationBadge.text = nil
        contentLabel.text = nil
    }

    func configure(with review: DisplayReview) {
        userLabel.text = review.userName
        dateLabel.text = Self.dateFormatter.string(from: review.createdAt)
        contentLabel.text = review.content
        if review.recommended {
            recommendationBadge.text = "Recommended"
            recommendationBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.18)
            recommendationBadge.textColor = .systemGreen
        } else {
            recommendationBadge.text = "Not Recommended"
            recommendationBadge.backgroundColor = UIColor.systemRed.withAlphaComponent(0.16)
            recommendationBadge.textColor = .systemRed
        }
    }
}
