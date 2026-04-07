//
//  PriceHistoryViewController.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import UIKit

final class PriceHistoryViewController: UIViewController {

    var wishlistItem: WishlistItem?
    private var priceHistory: GamePriceHistory?
    private var currentRange: TimeRange = .oneYear
    private var rangeButtons: [UIButton] = []

    enum TimeRange: String, CaseIterable {
        case sevenDays  = "7D"
        case thirtyDays = "30D"
        case sixMonths  = "6M"
        case oneYear    = "1Y"
        case all        = "All"
    }

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let contentStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 16
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let timeRangeStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        sv.distribution = .fillEqually
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let statsStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.spacing = 10
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let chartView: PriceChartView = {
        let cv = PriceChartView()
        cv.backgroundColor = .secondarySystemBackground
        cv.layer.cornerRadius = 12
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let recommendationCard: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 12
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let recommendationTitle: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let recommendationSubtitle: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.numberOfLines = 0
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var buyNowButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Buy Now"
        config.cornerStyle = .large
        config.baseBackgroundColor = .systemBlue
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: #selector(buyNowTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var addToWishlistButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.cornerStyle = .large
        let btn = UIButton(configuration: config)
        btn.addTarget(self, action: #selector(addToWishlistTapped), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Price History"
        setupNavigationBar()
        setupTimeRangePills()
        setupLayout()
        loadData()
        updateAddToWishlistButton()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain, target: self, action: #selector(moreTapped)
        )
    }

    private func setupTimeRangePills() {
        for (index, range) in TimeRange.allCases.enumerated() {
            var config = UIButton.Configuration.filled()
            config.title = range.rawValue
            config.cornerStyle = .capsule
            config.baseForegroundColor = range == currentRange ? .white : .label
            config.baseBackgroundColor = range == currentRange ? .systemBlue : .secondarySystemBackground
            let btn = UIButton(configuration: config)
            btn.tag = index
            btn.addTarget(self, action: #selector(rangeButtonTapped(_:)), for: .touchUpInside)
            rangeButtons.append(btn)
            timeRangeStack.addArrangedSubview(btn)
        }
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
        ])

        contentStack.addArrangedSubview(timeRangeStack)
        contentStack.addArrangedSubview(statsStack)
        contentStack.addArrangedSubview(chartView)
        chartView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        recommendationCard.addSubview(recommendationTitle)
        recommendationCard.addSubview(recommendationSubtitle)
        NSLayoutConstraint.activate([
            recommendationTitle.topAnchor.constraint(equalTo: recommendationCard.topAnchor, constant: 16),
            recommendationTitle.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 16),
            recommendationTitle.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -16),
            recommendationSubtitle.topAnchor.constraint(equalTo: recommendationTitle.bottomAnchor, constant: 4),
            recommendationSubtitle.leadingAnchor.constraint(equalTo: recommendationCard.leadingAnchor, constant: 16),
            recommendationSubtitle.trailingAnchor.constraint(equalTo: recommendationCard.trailingAnchor, constant: -16),
            recommendationSubtitle.bottomAnchor.constraint(equalTo: recommendationCard.bottomAnchor, constant: -16),
        ])
        contentStack.addArrangedSubview(recommendationCard)

        contentStack.addArrangedSubview(buyNowButton)
        contentStack.addArrangedSubview(addToWishlistButton)
        buyNowButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        addToWishlistButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }


    private func loadData() {
        guard let item = wishlistItem else { return }
        priceHistory = GamePriceHistory.mock(for: item)
        updateDisplayForCurrentRange()
        updateRecommendationCard()
    }

    private func updateDisplayForCurrentRange() {
        guard let history = priceHistory else { return }
        let points = filteredPoints(history.history)
        chartView.dataPoints = points
        buildStatsCards(from: points)
    }

    private func buildStatsCards(from points: [PricePoint]) {
        statsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !points.isEmpty else { return }

        let prices = points.map { $0.price }
        let low  = prices.min() ?? 0
        let high = prices.max() ?? 0
        let avg  = prices.reduce(0, +) / Double(prices.count)

        let stats: [(String, String)] = [
            ("Low",  String(format: "$%.2f", low)),
            ("High", String(format: "$%.2f", high)),
            ("Avg",  String(format: "$%.2f", avg)),
        ]
        for (title, value) in stats {
            statsStack.addArrangedSubview(makeStatCard(title: title, value: value))
        }
    }

    private func makeStatCard(title: String, value: String) -> UIView {
        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 10

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = .secondaryLabel
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 16, weight: .bold)
        valueLabel.textAlignment = .center
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.7
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(titleLabel)
        card.addSubview(valueLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            valueLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            valueLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
        ])
        return card
    }

    private func filteredPoints(_ points: [PricePoint]) -> [PricePoint] {
        let now = Date()
        let cal = Calendar.current
        switch currentRange {
        case .sevenDays:
            let cutoff = cal.date(byAdding: .day, value: -7, to: now)!
            return points.filter { $0.date >= cutoff }
        case .thirtyDays:
            let cutoff = cal.date(byAdding: .day, value: -30, to: now)!
            return points.filter { $0.date >= cutoff }
        case .sixMonths:
            let cutoff = cal.date(byAdding: .month, value: -6, to: now)!
            return points.filter { $0.date >= cutoff }
        case .oneYear:
            let cutoff = cal.date(byAdding: .year, value: -1, to: now)!
            return points.filter { $0.date >= cutoff }
        case .all:
            return points
        }
    }

    private func updateRecommendationCard() {
        guard let history = priceHistory else { return }
        if history.isRecommendedToBuy {
            recommendationTitle.text = "Recommended to Buy"
            recommendationSubtitle.text = "Current price is close to the all-time low and below the historical average."
        } else {
            recommendationTitle.text = "Not the Best Time"
            recommendationSubtitle.text = "The price may drop further during an upcoming sale. Consider waiting."
        }
    }

    private func updateAddToWishlistButton() {
        guard let appid = wishlistItem?.appid else { return }
        let inWishlist = LocalWishlistManager.shared.contains(appid)
        var config = addToWishlistButton.configuration ?? UIButton.Configuration.tinted()
        if inWishlist {
            config.title = "In Wishlist"
            config.image = UIImage(systemName: "checkmark")
            config.baseForegroundColor = .systemGreen
            config.baseBackgroundColor = .systemGreen
        } else {
            config.title = "Add to Wishlist"
            config.image = nil
            config.baseForegroundColor = .systemBlue
            config.baseBackgroundColor = .systemBlue
        }
        addToWishlistButton.configuration = config
    }

    @objc private func rangeButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        currentRange = TimeRange.allCases[index]

        for (i, btn) in rangeButtons.enumerated() {
            var config = btn.configuration ?? UIButton.Configuration.filled()
            config.baseForegroundColor = i == index ? .white : .label
            config.baseBackgroundColor = i == index ? .systemBlue : .secondarySystemBackground
            btn.configuration = config
        }
        // Refresh both chart and stats for the new range
        updateDisplayForCurrentRange()
    }

    @objc private func addToWishlistTapped() {
        guard let item = wishlistItem else { return }

        if LocalWishlistManager.shared.contains(item.appid) {
            // Already in wishlist — show notification
            let alert = UIAlertController(
                title: "Already in Wishlist",
                message: "\"\(item.name)\" is already in your wishlist.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        } else {
            // Add as a local wishlist item
            let game = Game(
                appid: item.appid,
                name: item.name,
                playtime_forever: 0,
                playtime_2weeks: 0,
                iconURL: item.iconURL,
                lastPlayedDate: nil
            )
            LocalWishlistManager.shared.add(game: game)
            updateAddToWishlistButton()

            // Sync to Steam if already authenticated
            SteamAuthManager.shared.addToSteamWishlist(appid: item.appid) { _ in }
        }
    }

    @objc private func buyNowTapped() {
        guard let appid = wishlistItem?.appid,
              let url = URL(string: "https://store.steampowered.com/app/\(appid)") else { return }
        UIApplication.shared.open(url)
    }

    @objc private func moreTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Open in Steam Store", style: .default) { [weak self] _ in
            self?.buyNowTapped()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}
