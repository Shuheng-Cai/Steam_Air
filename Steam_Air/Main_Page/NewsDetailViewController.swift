//
//  NewsDetailViewController.swift
//  Steam_Air
//
//  Created by  csh's computer on 4/6/26.
//

internal import UIKit

class NewsDetailViewController: UIViewController {

    var news: News?

    private var latestNews: [News] = []

    private let posterCard = UIView()
    private let posterImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 10
        iv.backgroundColor = .secondarySystemBackground
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let titleCard = UIView()
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 18, weight: .semibold)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Tap any item to open full news on Steam"
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let listCard = UIView()
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.dataSource = self
        tv.delegate = self
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(NewsListItemCell.self, forCellReuseIdentifier: NewsListItemCell.reuseID)
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        title = "News"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: nil,
            action: nil
        )

        setupLayout()
        loadNewsList()
    }

    private func setupLayout() {
        styleCard(posterCard)
        styleCard(titleCard)
        styleCard(listCard)

        view.addSubview(posterCard)
        view.addSubview(titleCard)
        view.addSubview(listCard)

        posterCard.addSubview(posterImageView)
        titleCard.addSubview(titleLabel)
        titleCard.addSubview(subtitleLabel)
        listCard.addSubview(tableView)

        NSLayoutConstraint.activate([
            posterCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            posterCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            posterCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            posterImageView.topAnchor.constraint(equalTo: posterCard.topAnchor, constant: 10),
            posterImageView.leadingAnchor.constraint(equalTo: posterCard.leadingAnchor, constant: 10),
            posterImageView.trailingAnchor.constraint(equalTo: posterCard.trailingAnchor, constant: -10),
            posterImageView.bottomAnchor.constraint(equalTo: posterCard.bottomAnchor, constant: -10),
            posterImageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.24),

            titleCard.topAnchor.constraint(equalTo: posterCard.bottomAnchor, constant: 12),
            titleCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            titleLabel.topAnchor.constraint(equalTo: titleCard.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: titleCard.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: titleCard.trailingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: titleCard.bottomAnchor, constant: -12),

            listCard.topAnchor.constraint(equalTo: titleCard.bottomAnchor, constant: 12),
            listCard.leadingAnchor.constraint(equalTo: titleCard.leadingAnchor),
            listCard.trailingAnchor.constraint(equalTo: titleCard.trailingAnchor),
            listCard.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            tableView.topAnchor.constraint(equalTo: listCard.topAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: listCard.leadingAnchor, constant: 8),
            tableView.trailingAnchor.constraint(equalTo: listCard.trailingAnchor, constant: -8),
            tableView.bottomAnchor.constraint(equalTo: listCard.bottomAnchor, constant: -6),
        ])
    }

    private func styleCard(_ view: UIView) {
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    private func loadNewsList() {
        guard let news else {
            titleLabel.text = "Latest News"
            latestNews = []
            tableView.reloadData()
            return
        }

        titleLabel.text = news.title
        latestNews = [news]
        GameImageCache.loadImage(from: news.iconURL, into: posterImageView)
        tableView.reloadData()

        guard let appid = extractAppID(from: news) else { return }

        fetchNews().fetchNews(appid: appid, count: 6) { [weak self] items in
            guard let self else { return }
            if items.isEmpty {
                self.latestNews = [news]
            } else {
                self.latestNews = items
            }
            self.tableView.reloadData()
        }
    }

    private func extractAppID(from news: News) -> Int? {
        if let match = news.iconURL.range(of: #"/apps/(\d+)/"#, options: .regularExpression) {
            let part = String(news.iconURL[match])
            let digits = part.filter(\.isNumber)
            if let appid = Int(digits) {
                return appid
            }
        }

        if let match = news.url.range(of: #"/app/(\d+)"#, options: .regularExpression) {
            let part = String(news.url[match])
            let digits = part.filter(\.isNumber)
            if let appid = Int(digits) {
                return appid
            }
        }

        return nil
    }

}

extension NewsDetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        latestNews.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewsListItemCell.reuseID, for: indexPath) as! NewsListItemCell
        let item = latestNews[indexPath.row]
        cell.configure(title: item.title, publishedAt: item.publishedAt)
        return cell
    }
}

extension NewsDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = latestNews[indexPath.row]
        guard let url = URL(string: item.url) else { return }
        UIApplication.shared.open(url)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        74
    }
}

private final class NewsListItemCell: UITableViewCell {

    static let reuseID = "NewsListItemCell"

    private let rowCard: UIView = {
        let v = UIView()
        v.backgroundColor = .systemBackground
        v.layer.cornerRadius = 10
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let publishedLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(rowCard)
        rowCard.addSubview(titleLabel)
        rowCard.addSubview(publishedLabel)

        NSLayoutConstraint.activate([
            rowCard.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            rowCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 2),
            rowCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
            rowCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            titleLabel.topAnchor.constraint(equalTo: rowCard.topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: rowCard.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: rowCard.trailingAnchor, constant: -10),

            publishedLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            publishedLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            publishedLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            publishedLabel.bottomAnchor.constraint(equalTo: rowCard.bottomAnchor, constant: -10),
        ])

        accessoryType = .disclosureIndicator
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        publishedLabel.text = nil
    }

    func configure(title: String, publishedAt: Date?) {
        titleLabel.text = title
        if let publishedAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            publishedLabel.text = "Published \(formatter.string(from: publishedAt))"
        } else {
            publishedLabel.text = "Published date unavailable"
        }
    }
}
