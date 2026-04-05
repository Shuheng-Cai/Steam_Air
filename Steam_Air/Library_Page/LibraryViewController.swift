//
//  LibraryViewController.swift
//  Steam_Air
//
//  Created by  Lucy K Y XU on 4/5/26.
//

import UIKit

final class LibraryViewController: UIViewController {

    private var allGames: [Game] = []
    private var searchText = ""

    private var displayedGames: [Game] {
        searchText.isEmpty
            ? allGames
            : allGames.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavigationBar()
        setupLayout()
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
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

            collectionView.topAnchor.constraint(equalTo: gameCountLabel.bottomAnchor, constant: 4),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func fetchGames() {
        spinner.startAnimating()
        collectionView.isHidden = true

        fetchGame().fetchOwnedGames(
            apiKey: "CD89B4D216CF0A68E8970744826761AF",
            steamID: "76561198803168936"
        ) { [weak self] games in
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
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

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
