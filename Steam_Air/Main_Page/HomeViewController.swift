//
//  HomeViewController.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/30/26.
//

internal import UIKit

class HomeViewController: UIViewController {

    // Kept to avoid storyboard outlet breakage while moving to table-based layout.
    @IBOutlet weak var recommendedCollectionView: UICollectionView?
    @IBOutlet weak var newsCollectionView: UICollectionView?

    var games: [Game] = []
    var news: [News] = []
    var steamID: String?

    private enum Section: Int, CaseIterable {
        case promo
        case recommended
        case updates

        var title: String? {
            switch self {
            case .promo:
                return nil
            case .recommended:
                return "RECOMMENDED"
            case .updates:
                return "UPDATES"
            }
        }
    }

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        hideLegacyStoryboardViews()
        setupTableView()
        fetchHomeData()
    }

    private func configureNavigationBar() {
        title = "Home"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: nil,
            action: nil
        )
    }

    private func hideLegacyStoryboardViews() {
        recommendedCollectionView?.isHidden = true
        newsCollectionView?.isHidden = true
    }

    private func setupTableView() {
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        tableView.dataSource = self
        tableView.delegate = self

        tableView.register(HomePromoBannerCell.self, forCellReuseIdentifier: HomePromoBannerCell.reuseID)
        tableView.register(HomeRecommendedRowCell.self, forCellReuseIdentifier: HomeRecommendedRowCell.reuseID)
        tableView.register(HomeUpdateCell.self, forCellReuseIdentifier: HomeUpdateCell.reuseID)
    }

    private func fetchHomeData() {
        guard let steamID = steamID else {
            print("HomeViewController: steamID is nil")
            return
        }

        fetchGame().fetchOwnedGames(steamID: steamID) { [weak self] games in
            guard let self else { return }

            self.games = games
                .sorted { $0.playtime_forever > $1.playtime_forever }
            self.tableView.reloadData()

            self.fetchUpdates(for: self.games)
        }
    }

    private func fetchUpdates(for games: [Game]) {
        let seedGames = Array(games.prefix(8))
        guard !seedGames.isEmpty else {
            news = []
            tableView.reloadData()
            return
        }

        news = []
        var pending = seedGames.count

        for game in seedGames {
            fetchNews().fetchNews(appid: game.appid) { [weak self] items in
                guard let self else { return }

                if let first = items.first {
                    self.news.append(first)
                }

                pending -= 1
                if pending == 0 {
                    var seenTitles = Set<String>()
                    self.news = self.news.filter { item in
                        let key = item.title.lowercased()
                        if seenTitles.contains(key) {
                            return false
                        }
                        seenTitles.insert(key)
                        return true
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func openDealsTab() {
        tabBarController?.selectedIndex = 2
    }

    private func showGameDetail(_ game: Game) {
        let storyboard = UIStoryboard(name: "HomePageScreen", bundle: nil)
        guard let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else {
            return
        }
        detailVC.Game = game
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func showNewsDetail(_ item: News) {
        let storyboard = UIStoryboard(name: "HomePageScreen", bundle: nil)
        guard let detailVC = storyboard.instantiateViewController(withIdentifier: "NewsDetailViewController") as? NewsDetailViewController else {
            return
        }
        detailVC.news = item
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension HomeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .promo:
            return 1
        case .recommended:
            return 1
        case .updates:
            return min(news.count, 6)
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }

        switch section {
        case .promo:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HomePromoBannerCell.reuseID,
                for: indexPath
            ) as! HomePromoBannerCell
            cell.configure(
                title: "Spring Sale is Live",
                subtitle: "Find discounts, trending titles, and new releases.",
                buttonTitle: "Explore Deals"
            ) { [weak self] in
                self?.openDealsTab()
            }
            return cell

        case .recommended:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HomeRecommendedRowCell.reuseID,
                for: indexPath
            ) as! HomeRecommendedRowCell
            cell.configure(games: Array(games.prefix(12))) { [weak self] game in
                self?.showGameDetail(game)
            }
            return cell

        case .updates:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: HomeUpdateCell.reuseID,
                for: indexPath
            ) as! HomeUpdateCell
            let item = news[indexPath.row]
            cell.configure(with: item)
            return cell
        }
    }
}

extension HomeViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let section = Section(rawValue: indexPath.section) else { return 0 }
        switch section {
        case .promo:
            return 128
        case .recommended:
            return 214
        case .updates:
            return 100
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section), section == .updates else { return }
        let item = news[indexPath.row]
        showNewsDetail(item)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let section = Section(rawValue: section), let title = section.title else { return nil }

        let container = UIView()
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let section = Section(rawValue: section), section.title != nil else { return 10 }
        return 26
    }
}

private final class HomePromoBannerCell: UITableViewCell {

    static let reuseID = "HomePromoBannerCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 10
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 20, weight: .semibold)
        l.textColor = .label
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let actionButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 14, weight: .semibold)
            return outgoing
        }

        let btn = UIButton(configuration: config)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private var tapAction: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(actionButton)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            titleLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

            actionButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            actionButton.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            actionButton.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            actionButton.heightAnchor.constraint(equalToConstant: 38),
        ])

        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(title: String, subtitle: String, buttonTitle: String, onTap: @escaping () -> Void) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        actionButton.configuration?.title = buttonTitle
        tapAction = onTap
    }

    @objc private func buttonTapped() {
        tapAction?()
    }
}

private final class HomeRecommendedRowCell: UITableViewCell {

    static let reuseID = "HomeRecommendedRowCell"

    private var games: [Game] = []
    private var onSelectGame: ((Game) -> Void)?

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.dataSource = self
        cv.delegate = self
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(HomeRecommendedGameCardCell.self, forCellWithReuseIdentifier: HomeRecommendedGameCardCell.reuseID)
        return cv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(games: [Game], onSelect: @escaping (Game) -> Void) {
        self.games = games
        self.onSelectGame = onSelect
        collectionView.reloadData()
    }
}

extension HomeRecommendedRowCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        games.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomeRecommendedGameCardCell.reuseID,
            for: indexPath
        ) as! HomeRecommendedGameCardCell

        cell.configure(with: games[indexPath.row])
        return cell
    }
}

extension HomeRecommendedRowCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onSelectGame?(games[indexPath.row])
    }
}

extension HomeRecommendedRowCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: 146, height: 198)
    }
}

private final class HomeRecommendedGameCardCell: UICollectionViewCell {

    static let reuseID = "HomeRecommendedGameCardCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(cardView)
        cardView.addSubview(posterImageView)
        cardView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            posterImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 8),
            posterImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 8),
            posterImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            posterImageView.heightAnchor.constraint(equalToConstant: 150),

            titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: posterImageView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: posterImageView.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: cardView.bottomAnchor, constant: -8),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.image = nil
    }

    func configure(with game: Game) {
        titleLabel.text = game.name
        GameImageCache.loadImage(from: game.iconURL, into: posterImageView)
    }
}

private final class HomeUpdateCell: UITableViewCell {

    static let reuseID = "HomeUpdateCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 10
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 9
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.numberOfLines = 2
        l.lineBreakMode = .byWordWrapping
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(iconImageView)
        cardView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            iconImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 56),
            iconImageView.heightAnchor.constraint(equalToConstant: 56),

            titleLabel.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconImageView.image = nil
    }

    func configure(with item: News) {
        titleLabel.text = item.title
        GameImageCache.loadImage(from: item.iconURL, into: iconImageView)
    }
}
