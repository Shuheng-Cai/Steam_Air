//
//  GameAchievementsViewController.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//  Detail page: lists all achievements (unlocked + locked) for a single game.
//

internal import UIKit

final class GameAchievementsViewController: UIViewController {

    // Set by the caller before push
    var game: Game?
    var steamID: String?

    private var unlocked: [Achievement] = []
    private var locked:   [Achievement] = []

    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 72
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .large)
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private let emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No achievements for this game."
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 16)
        l.textAlignment = .center
        l.isHidden = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = game?.name
        setupLayout()
        tableView.dataSource = self
        tableView.register(AchievementRowCell.self, forCellReuseIdentifier: AchievementRowCell.reuseID)
        fetchAchievements()
    }

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(spinner)
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func fetchAchievements() {
        guard let game, let steamID = steamID else { return }
        spinner.startAnimating()
        tableView.isHidden = true

        AchievementFetch().fetchAchievements(appid: game.appid, steamID: steamID) { [weak self] result in
            guard let self else { return }
            self.spinner.stopAnimating()

            guard let result, result.totalCount > 0 else {
                self.emptyLabel.isHidden = false
                return
            }

            self.tableView.isHidden = false
            self.unlocked = result.achievements
                .filter { $0.achieved }
                .sorted { ($0.unlockTime ?? .distantPast) > ($1.unlockTime ?? .distantPast) }
            self.locked = result.achievements.filter { !$0.achieved }

            let pct = Int(result.progress * 100)
            self.title = "\(result.unlockedCount)/\(result.totalCount) (\(pct)%)"
            self.tableView.reloadData()
        }
    }
}

extension GameAchievementsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? unlocked.count : locked.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return unlocked.isEmpty ? nil : "Unlocked  (\(unlocked.count))" }
        return locked.isEmpty ? nil : "Locked  (\(locked.count))"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: AchievementRowCell.reuseID, for: indexPath
        ) as! AchievementRowCell
        let achievement = indexPath.section == 0 ? unlocked[indexPath.row] : locked[indexPath.row]
        cell.configure(with: achievement)
        return cell
    }
}

private final class AchievementRowCell: UITableViewCell {

    static let reuseID = "AchievementRowCell"

    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 6
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let nameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let descLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let dateLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 11)
        l.textColor = .systemBlue
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(iconView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descLabel)
        contentView.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
            iconView.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
            iconView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: iconView.topAnchor),

            descLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),
            descLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            dateLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            dateLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor, constant: 2),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(with a: Achievement) {
        nameLabel.text = a.name
        descLabel.text = a.description.isEmpty ? nil : a.description

        if a.achieved {
            iconView.image = UIImage(systemName: "star.fill")
            iconView.tintColor = .systemYellow
            if let t = a.unlockTime {
                let f = DateFormatter()
                f.dateStyle = .medium; f.timeStyle = .none
                dateLabel.text = "Unlocked \(f.string(from: t))"
            } else {
                dateLabel.text = "Unlocked"
            }
        } else {
            iconView.image = UIImage(systemName: "lock.fill")
            iconView.tintColor = .systemGray3
            dateLabel.text = nil
        }
    }
}
