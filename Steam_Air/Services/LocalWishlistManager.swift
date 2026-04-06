//
//  LocalWishlistManager.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//
//  Persists user-added wishlist appids to UserDefaults.
//

import Foundation

final class LocalWishlistManager {

    static let shared = LocalWishlistManager()
    private init() {}

    private let appidsKey   = "localWishlist_appids"
    private let gamesKey    = "localWishlist_games"

    private(set) var appids: Set<Int> {
        get {
            let array = UserDefaults.standard.array(forKey: appidsKey) as? [Int] ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: appidsKey)
        }
    }

    func contains(_ appid: Int) -> Bool { appids.contains(appid) }

    func add(game: Game) {
        var ids = appids
        ids.insert(game.appid)
        appids = ids
        saveGameSnapshot(game)
        NotificationCenter.default.post(name: .localWishlistChanged, object: nil)
    }

    func remove(appid: Int) {
        var ids = appids
        ids.remove(appid)
        appids = ids
        removeGameSnapshot(appid: appid)
        NotificationCenter.default.post(name: .localWishlistChanged, object: nil)
    }



    func localGames() -> [Game] {
        guard let raw = UserDefaults.standard.array(forKey: gamesKey) as? [[String: Any]] else {
            return []
        }
        return raw.compactMap { dict -> Game? in
            guard
                let appid   = dict["appid"]   as? Int,
                let name    = dict["name"]    as? String,
                let iconURL = dict["iconURL"] as? String
            else { return nil }
            return Game(
                appid: appid,
                name: name,
                playtime_forever: dict["playtime_forever"] as? Int ?? 0,
                playtime_2weeks: dict["playtime_2weeks"]  as? Int ?? 0,
                iconURL: iconURL,
                lastPlayedDate: nil
            )
        }
    }

    private func saveGameSnapshot(_ game: Game) {
        var list = UserDefaults.standard.array(forKey: gamesKey) as? [[String: Any]] ?? []
        // Avoid duplicates
        list.removeAll { ($0["appid"] as? Int) == game.appid }
        list.append([
            "appid":            game.appid,
            "name":             game.name,
            "playtime_forever": game.playtime_forever,
            "playtime_2weeks":  game.playtime_2weeks,
            "iconURL":          game.iconURL,
        ])
        UserDefaults.standard.set(list, forKey: gamesKey)
    }

    private func removeGameSnapshot(appid: Int) {
        var list = UserDefaults.standard.array(forKey: gamesKey) as? [[String: Any]] ?? []
        list.removeAll { ($0["appid"] as? Int) == appid }
        UserDefaults.standard.set(list, forKey: gamesKey)
    }
}


extension Notification.Name {
    static let localWishlistChanged = Notification.Name("localWishlistChanged")
}
