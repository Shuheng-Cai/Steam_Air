//
//  StoreViewController.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

internal import UIKit

final class StoreViewController: UIViewController {

    private enum StoreTab: Int, CaseIterable {
        case specials
        case topSellers
        case newReleases

        var title: String {
            switch self {
            case .specials:
                return "Specials"
            case .topSellers:
                return "Top Sellers"
            case .newReleases:
                return "New Releases"
            }
        }
    }

    private var sections = StoreSections(specials: [], topSellers: [], newReleases: [])
    private var searchText = ""
    private var searchResults: [SteamDeal] = []
    private var searchWorkItem: DispatchWorkItem?
    private var activeSearchTerm = ""

    private var displayedDeals: [SteamDeal] {
        if !searchText.isEmpty {
            return searchResults
        }

        guard let tab = StoreTab(rawValue: segmentControl.selectedSegmentIndex) else { return [] }
        switch tab {
        case .specials:
            return sections.specials
        case .topSellers:
            return sections.topSellers
        case .newReleases:
            return sections.newReleases
        }
    }

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search in Store"
        sb.searchBarStyle = .minimal
        sb.autocapitalizationType = .none
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No games found"
        l.font = .systemFont(ofSize: 14)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private func updateEmptyState() {
        emptyLabel.isHidden = !displayedDeals.isEmpty
        tableView.isHidden = displayedDeals.isEmpty
    }

    private func refreshList() {
        updateCountLabel()
        tableView.reloadData()
        updateEmptyState()
    }

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.searchTextField.returnKeyType = .done
    }

    private let segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: StoreTab.allCases.map(\.title))
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let countLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .systemBackground
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.rowHeight = 112
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Store"

        setupLayout()
        setupSearchBar()
        setupTableView()
        fetchStoreData()
    }

    private func setupLayout() {
        view.addSubview(searchBar)
        view.addSubview(segmentControl)
        view.addSubview(countLabel)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            segmentControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            countLabel.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 12),
            countLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            tableView.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 40),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        segmentControl.addTarget(self, action: #selector(tabChanged(_:)), for: .valueChanged)
    }

    private func setupTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(StoreDealCell.self, forCellReuseIdentifier: StoreDealCell.reuseID)
    }

    private func fetchStoreData() {
        spinner.startAnimating()

        DealsFetch().fetchStoreSections { [weak self] sections in
            guard let self else { return }
            self.spinner.stopAnimating()
            self.sections = sections
            self.refreshList()
        }
    }

    private func performRemoteSearch(term: String) {
        let query = term.trimmingCharacters(in: .whitespacesAndNewlines)
        activeSearchTerm = query

        guard !query.isEmpty else {
            spinner.stopAnimating()
            searchResults = []
            refreshList()
            return
        }

        spinner.startAnimating()
        DealsFetch().searchStoreGames(term: query) { [weak self] results in
            guard let self else { return }
            guard self.activeSearchTerm == query else { return }
            self.spinner.stopAnimating()
            self.searchResults = results
            self.refreshList()
        }
    }

    @objc private func tabChanged(_ sender: UISegmentedControl) {
        refreshList()
    }

    private func updateCountLabel() {
        let count = displayedDeals.count
        countLabel.text = "\(count) game\(count == 1 ? "" : "s")"
    }

    private func openStorePage(for appid: Int) {
        guard let url = URL(string: "https://store.steampowered.com/app/\(appid)") else { return }
        UIApplication.shared.open(url)
    }
}

extension StoreViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedDeals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: StoreDealCell.reuseID,
            for: indexPath
        ) as! StoreDealCell
        cell.configure(with: displayedDeals[indexPath.row])
        return cell
    }
}

extension StoreViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        openStorePage(for: displayedDeals[indexPath.row].appid)
    }
}

extension StoreViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        searchWorkItem?.cancel()

        let query = self.searchText
        let work = DispatchWorkItem { [weak self] in
            self?.performRemoteSearch(term: query)
        }
        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchWorkItem?.cancel()
        performRemoteSearch(term: searchText)
    }
}

private final class StoreDealCell: UITableViewCell {

    static let reuseID = "StoreDealCell"

    private let cardView: UIView = {
        let v = UIView()
        v.backgroundColor = .secondarySystemBackground
        v.layer.cornerRadius = 10
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.separator.withAlphaComponent(0.2).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

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
        l.font = .systemFont(ofSize: 16, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let discountBadge: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textAlignment = .center
        l.layer.cornerRadius = 6
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let finalPriceLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .label
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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.addSubview(cardView)
        cardView.addSubview(coverImageView)
        cardView.addSubview(nameLabel)
        cardView.addSubview(discountBadge)
        cardView.addSubview(finalPriceLabel)
        cardView.addSubview(originalPriceLabel)

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            coverImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            coverImageView.centerYAnchor.constraint(equalTo: cardView.centerYAnchor),
            coverImageView.widthAnchor.constraint(equalToConstant: 76),
            coverImageView.heightAnchor.constraint(equalToConstant: 76),

            nameLabel.topAnchor.constraint(equalTo: coverImageView.topAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: coverImageView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),

            discountBadge.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            discountBadge.bottomAnchor.constraint(equalTo: coverImageView.bottomAnchor),
            discountBadge.heightAnchor.constraint(equalToConstant: 24),
            discountBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 52),

            finalPriceLabel.leadingAnchor.constraint(equalTo: discountBadge.trailingAnchor, constant: 8),
            finalPriceLabel.centerYAnchor.constraint(equalTo: discountBadge.centerYAnchor),

            originalPriceLabel.leadingAnchor.constraint(equalTo: finalPriceLabel.trailingAnchor, constant: 8),
            originalPriceLabel.centerYAnchor.constraint(equalTo: finalPriceLabel.centerYAnchor),
            originalPriceLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -12),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        coverImageView.image = nil
        nameLabel.text = nil
        discountBadge.text = nil
        finalPriceLabel.text = nil
        originalPriceLabel.attributedText = nil
    }

    func configure(with deal: SteamDeal) {
        nameLabel.text = deal.name
        GameImageCache.loadImage(from: deal.headerImageURL, into: coverImageView)

        if deal.discountPercent > 0 {
            discountBadge.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.18)
            discountBadge.textColor = .systemGreen
            discountBadge.text = "-\(deal.discountPercent)%"

            finalPriceLabel.text = deal.formattedFinalPrice
            originalPriceLabel.isHidden = false
            originalPriceLabel.attributedText = NSAttributedString(
                string: deal.formattedOriginalPrice,
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.secondaryLabel,
                ]
            )
        } else {
            discountBadge.backgroundColor = UIColor.tertiarySystemFill
            discountBadge.textColor = .secondaryLabel
            discountBadge.text = "No discount"

            finalPriceLabel.text = deal.formattedFinalPrice
            originalPriceLabel.isHidden = true
        }
    }
}
