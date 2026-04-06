//
//  WishlistViewController.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import UIKit

final class WishlistViewController: UIViewController {

    private enum Tab: Int { case wishlist = 0, deals = 1 }

    private var currentTab: Tab = .wishlist
    private var wishlistItems: [WishlistItem] = []
    private var deals: [SteamDeal] = []
    private var isLoadingWishlist = false
    private var isLoadingDeals = false

    private let segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Wishlist", "Deals"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .systemBackground
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 90
        tv.register(WishlistGameCell.self, forCellReuseIdentifier: WishlistGameCell.reuseID)
        tv.register(DealCell.self, forCellReuseIdentifier: DealCell.reuseID)
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
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 16)
        l.textAlignment = .center
        l.numberOfLines = 0
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupLayout()
        tableView.dataSource = self
        tableView.delegate = self
        segmentControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        fetchWishlist()
        fetchDeals()
    }

    private func setupNavigationBar() {
        title = "Wishlist"
        navigationController?.navigationBar.prefersLargeTitles = false

        let heartItem = UIBarButtonItem(
            image: UIImage(systemName: "heart.fill"),
            style: .plain, target: nil, action: nil
        )
        heartItem.tintColor = .systemPink
        navigationItem.leftBarButtonItem = heartItem

        let notificationsItem = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain, target: self, action: #selector(notificationsTapped)
        )
        let moreItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain, target: self, action: #selector(moreTapped)
        )
        navigationItem.rightBarButtonItems = [moreItem, notificationsItem]
    }

    private func setupLayout() {
        view.addSubview(segmentControl)
        view.addSubview(tableView)
        view.addSubview(spinner)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.widthAnchor.constraint(equalToConstant: 180),

            tableView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
        ])
    }

    private func fetchWishlist() {
        isLoadingWishlist = true
        if currentTab == .wishlist { spinner.startAnimating() }

        WishlistFetch().fetchWishlist(steamID: "76561198803168956") { [weak self] items in
            guard let self else { return }
            self.isLoadingWishlist = false
            self.wishlistItems = items
            if self.currentTab == .wishlist {
                self.spinner.stopAnimating()
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        }
    }

    private func fetchDeals() {
        isLoadingDeals = true
        DealsFetch().fetchDeals { [weak self] deals in
            guard let self else { return }
            self.isLoadingDeals = false
            self.deals = deals
            if self.currentTab == .deals {
                self.spinner.stopAnimating()
                self.tableView.reloadData()
                self.updateEmptyState()
            }
        }
    }

    private func updateEmptyState() {
        let isEmpty = currentTab == .wishlist ? wishlistItems.isEmpty : deals.isEmpty
        if isEmpty {
            emptyLabel.text = currentTab == .wishlist
                ? "Your wishlist is empty.\nMake sure your Steam wishlist is set to Public."
                : "No deals available right now."
        }
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        currentTab = Tab(rawValue: sender.selectedSegmentIndex) ?? .wishlist
        tableView.reloadData()

        let isLoading = currentTab == .wishlist ? isLoadingWishlist : isLoadingDeals
        if isLoading {
            spinner.startAnimating()
            tableView.isHidden = true
            emptyLabel.isHidden = true
        } else {
            spinner.stopAnimating()
            updateEmptyState()
        }
    }

    @objc private func notificationsTapped() {
        let vc = NotificationsViewController()
        vc.wishlistItems = wishlistItems
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func moreTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Sort by Priority", style: .default) { [weak self] _ in
            self?.wishlistItems.sort { $0.priority < $1.priority }
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Sort by Discount", style: .default) { [weak self] _ in
            self?.wishlistItems.sort { $0.discountPercent > $1.discountPercent }
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Sort by Price", style: .default) { [weak self] _ in
            self?.wishlistItems.sort {
                ($0.currentPrice ?? .infinity) < ($1.currentPrice ?? .infinity)
            }
            self?.tableView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}

extension WishlistViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentTab == .wishlist ? wishlistItems.count : deals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentTab {
        case .wishlist:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: WishlistGameCell.reuseID, for: indexPath
            ) as! WishlistGameCell
            cell.configure(with: wishlistItems[indexPath.row])
            return cell
        case .deals:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DealCell.reuseID, for: indexPath
            ) as! DealCell
            cell.configure(with: deals[indexPath.row])
            return cell
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        currentTab == .deals ? "DISCOUNTS" : nil
    }
}

extension WishlistViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch currentTab {
        case .wishlist:
            let vc = PriceHistoryViewController()
            vc.wishlistItem = wishlistItems[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        case .deals:
            let deal = deals[indexPath.row]
            guard let url = URL(string: "https://store.steampowered.com/app/\(deal.appid)") else { return }
            UIApplication.shared.open(url)
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        currentTab == .deals ? 80 : UITableView.automaticDimension
    }
}
