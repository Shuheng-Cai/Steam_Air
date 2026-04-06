//
//  AchievementFetch.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//  Fetches player achievements for a single game via Steam Web API.
//

import Foundation

class AchievementFetch {

    private static let apiKey  = "CD89B4D216CF0A68E8970744826761AF"
    private static let steamID = "76561198803168936"

    /// Fetches achievements for `appid`. Returns nil if the game has no stats or on error.
    func fetchAchievements(appid: Int, completion: @escaping (GameAchievements?) -> Void) {
        let urlString = "https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/"
            + "?appid=\(appid)&key=\(Self.apiKey)&steamid=\(Self.steamID)&l=en"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data, error == nil else {
                    completion(nil)
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(PlayerAchievementsResponse.self, from: data)
                    let stats = decoded.playerstats
                    // success == false means the game has no achievement system
                    guard stats.success == true, let dtos = stats.achievements else {
                        completion(nil)
                        return
                    }
                    completion(GameAchievements(
                        appid: appid,
                        gameName: stats.gameName ?? "Unknown",
                        achievements: dtos.map { $0.toAchievement() }
                    ))
                } catch {
                    print("Achievement decode error (appid \(appid)):", error)
                    completion(nil)
                }
            }
        }.resume()
    }
}
