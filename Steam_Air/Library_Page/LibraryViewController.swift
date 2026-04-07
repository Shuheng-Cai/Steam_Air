//
//  LibraryViewController.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import UIKit

final class LibraryViewController: UIViewController {

    // MARK: - Achievement load state (Collections tab)
    private enum AchievementLoadState {
        case idle, loading, loaded(GameAchievements?)
    }
    private var achievementsStates: [Int: AchievementLoadState] = [:]
    
    private var allGames: [Game] = []
    private var searchText = ""

    private var displayedGames: [Game] {
        searchText.isEmpty
            ? allGames
            : allGames.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var steamID: String?

    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Search your games"
        sb.searchBarStyle = .minimal
        sb.translatesAutoresizingMaskIntoConstraints = false
        return sb
    }()

    private let segmentControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: ["Library", "Collections"])
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()

    private let gameCountLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.keyboardDismissMode = .onDrag
        cv.register(LibraryGameCell.self, forCellWithReuseIdentifier: LibraryGameCell.reuseID)
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var collectionsTableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.backgroundColor = .systemBackground
        tv.keyboardDismissMode = .onDrag
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 84
        tv.register(CollectionsGameCell.self, forCellReuseIdentifier: CollectionsGameCell.reuseID)
        tv.isHidden = true
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionsTableView.dataSource = self
        collectionsTableView.delegate = self
        searchBar.delegate = self
        segmentControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        fetchGames()
    }

    private func setupNavigationBar() {
        title = "Library"
        navigationController?.navigationBar.prefersLargeTitles = false

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(moreTapped)
        )
    }

    private func setupLayout() {
        view.addSubview(searchBar)
        view.addSubview(segmentControl)
        view.addSubview(gameCountLabel)
        view.addSubview(collectionView)
        view.addSubview(collectionsTableView)
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            segmentControl.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.widthAnchor.constraint(equalToConstant: 210),

            gameCountLabel.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 12),
            gameCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),

            // Library grid and Collections list share the same frame; toggled via isHidden
            collectionView.topAnchor.constraint(equalTo: gameCountLabel.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            collectionsTableView.topAnchor.constraint(equalTo: gameCountLabel.bottomAnchor, constant: 4),
            collectionsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc private func segmentChanged(_ sender: UISegmentedControl) {
        let isLibrary = sender.selectedSegmentIndex == 0
        collectionView.isHidden = !isLibrary
        collectionsTableView.isHidden = isLibrary
        updateGameCount()
        if !isLibrary { collectionsTableView.reloadData() }
    }

    private func fetchGames() {
        spinner.startAnimating()
        collectionView.isHidden = true

        guard let steamID = steamID else {
            print("steamID is nil")
            spinner.stopAnimating()
            collectionView.isHidden = false
            return
        }

        fetchGame().fetchOwnedGames(steamID: steamID) { [weak self] games in
            guard let self else { return }
            self.spinner.stopAnimating()
            self.collectionView.isHidden = false
            self.allGames = games.sortedByLastPlayed()
            self.updateGameCount()
            self.collectionView.reloadData()
        }
    }

    private func updateGameCount() {
        let n = displayedGames.count
        gameCountLabel.text = "\(n) game\(n == 1 ? "" : "s")"
    }

    @objc private func moreTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Sort by Recently Played", style: .default) { [weak self] _ in
            self?.allGames = self?.allGames.sortedByLastPlayed() ?? []
            self?.collectionView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Sort by Name", style: .default) { [weak self] _ in
            self?.allGames.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
            self?.collectionView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Sort by Most Played", style: .default) { [weak self] _ in
            self?.allGames.sort { $0.playtime_forever > $1.playtime_forever }
            self?.collectionView.reloadData()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
}

extension LibraryViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        displayedGames.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: LibraryGameCell.reuseID,
            for: indexPath
        ) as! LibraryGameCell
        cell.configure(with: displayedGames[indexPath.item])
        return cell
    }
}

extension LibraryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16
        let gap: CGFloat = 12
        let cellWidth = (collectionView.bounds.width - padding * 2 - gap) / 2
        let imageHeight = cellWidth * (3.0 / 2.0)   // library_600x900 portrait 2:3
        return CGSize(width: cellWidth, height: imageHeight + 52)
    }
}

extension LibraryViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let game = displayedGames[indexPath.item]
        let storyboard = UIStoryboard(name: "HomePageScreen", bundle: nil)
        guard let detailVC = storyboard.instantiateViewController(
            withIdentifier: "DetailViewController"
        ) as? DetailViewController else { return }
        detailVC.Game = game
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension LibraryViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText = searchText
        updateGameCount()
        collectionView.reloadData()
        collectionsTableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource (Collections tab)

extension LibraryViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedGames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: CollectionsGameCell.reuseID, for: indexPath
        ) as! CollectionsGameCell

        let game = displayedGames[indexPath.row]

        guard let steamID = steamID else {
            cell.configure(game: game, achievements: nil, isLoading: false)
            return cell
        }

        switch achievementsStates[game.appid] ?? .idle {
        case .idle:
            // First time this cell appears — kick off the fetch
            achievementsStates[game.appid] = .loading
            cell.configure(game: game, achievements: nil, isLoading: true)
            AchievementFetch().fetchAchievements(appid: game.appid, steamID: steamID) { [weak self] result in
                guard let self else { return }
                self.achievementsStates[game.appid] = .loaded(result)
                // Reload only this row to avoid full-table flicker
                if let row = self.displayedGames.firstIndex(where: { $0.appid == game.appid }) {
                    self.collectionsTableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
                }
            }
        case .loading:
            cell.configure(game: game, achievements: nil, isLoading: true)
        case .loaded(let achievements):
            cell.configure(game: game, achievements: achievements, isLoading: false)
        }
        return cell
    }
}

// MARK: - UITableViewDelegate (Collections tab)

extension LibraryViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let game = displayedGames[indexPath.row]
        let achievementsVC = GameAchievementsViewController()
        achievementsVC.game = game
        achievementsVC.steamID = steamID
        navigationController?.pushViewController(achievementsVC, animated: true)
    }
}

// MARK: - Sort helper

private extension Array where Element == Game {
    // Most-recently played first; ties broken by total playtime, then name.
    func sortedByLastPlayed() -> [Game] {
        sorted {
            switch ($0.lastPlayedDate, $1.lastPlayedDate) {
            case let (a?, b?): return a > b
            case (_?, nil):   return true
            case (nil, _?):   return false
            default:          return $0.playtime_forever > $1.playtime_forever
            }
        }
    }
}
