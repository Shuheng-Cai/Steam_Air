//
//  WishlistViewController.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

internal import UIKit

final class WishlistViewController: UIViewController {

    private enum Tab: Int { case wishlist = 0, deals = 1 }

    private var currentTab: Tab = .wishlist
    private var steamWishlistItems: [WishlistItem] = []   // from Steam API
    private var deals: [SteamDeal] = []
    private var isLoadingWishlist = false
    private var isLoadingDeals = false

    /// Merged list: Steam wishlist + locally-added games (deduplicated by appid)
    private var wishlistItems: [WishlistItem] {
        let steamIDs = Set(steamWishlistItems.map { $0.appid })
        let localItems = LocalWishlistManager.shared.localGames()
            .filter { !steamIDs.contains($0.appid) }
            .map { WishlistItem(
                appid: $0.appid,
                name: $0.name,
                iconURL: $0.iconURL,
                currentPrice: nil,
                originalPrice: nil,
                discountPercent: 0,
                isFreeGame: false,
                addedDate: nil,
                priority: Int.max
            )}
        return steamWishlistItems + localItems
    }

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(localWishlistChanged),
            name: .localWishlistChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
            self.steamWishlistItems = items
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
                ? "Your wishlist is empty.\nAdd games from the Library, or make your Steam wishlist Public."
                : "No deals available right now."
        }
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    @objc private func localWishlistChanged() {
        if currentTab == .wishlist {
            tableView.reloadData()
            updateEmptyState()
        }
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

        // Sort actions (wishlist tab only)
        if currentTab == .wishlist {
            sheet.addAction(UIAlertAction(title: "Sort by Priority", style: .default) { [weak self] _ in
                self?.steamWishlistItems.sort { $0.priority < $1.priority }
                self?.tableView.reloadData()
            })
            sheet.addAction(UIAlertAction(title: "Sort by Discount", style: .default) { [weak self] _ in
                self?.steamWishlistItems.sort { $0.discountPercent > $1.discountPercent }
                self?.tableView.reloadData()
            })
            sheet.addAction(UIAlertAction(title: "Sort by Price", style: .default) { [weak self] _ in
                self?.steamWishlistItems.sort {
                    ($0.currentPrice ?? .infinity) < ($1.currentPrice ?? .infinity)
                }
                self?.tableView.reloadData()
            })

            // Steam sync
            let syncTitle = SteamAuthManager.shared.isAuthenticated
                ? "Sync to Steam Wishlist"
                : "Sign in & Sync to Steam"
            sheet.addAction(UIAlertAction(title: syncTitle, style: .default) { [weak self] _ in
                self?.handleSyncToSteam()
            })

            // Sign out (only if logged in)
            if SteamAuthManager.shared.isAuthenticated {
                sheet.addAction(UIAlertAction(title: "Sign Out of Steam", style: .destructive) { _ in
                    SteamAuthManager.shared.logOut()
                })
            }
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }

    private func handleSyncToSteam() {
        if SteamAuthManager.shared.isAuthenticated {
            performSync()
        } else {
            let loginVC = SteamLoginViewController()
            loginVC.onAuthenticated = { [weak self] in
                self?.performSync()
            }
            let nav = UINavigationController(rootViewController: loginVC)
            present(nav, animated: true)
        }
    }

    private func performSync() {
        let hud = UIAlertController(title: "Syncing…", message: nil, preferredStyle: .alert)
        present(hud, animated: true)

        SteamAuthManager.shared.syncLocalWishlistToSteam { [weak self] synced, failed in
            hud.dismiss(animated: true) {
                guard let self else { return }
                let msg: String
                if synced == 0 && failed == 0 {
                    msg = "Your wishlist is already up to date on Steam."
                } else if failed == 0 {
                    msg = "\(synced) game\(synced == 1 ? "" : "s") synced to your Steam wishlist."
                } else {
                    msg = "\(synced) synced, \(failed) failed. Check your Steam session."
                }
                let result = UIAlertController(title: "Sync Complete", message: msg,
                                               preferredStyle: .alert)
                result.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(result, animated: true)
            }
        }
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
