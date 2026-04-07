//
//  AchievementFetch.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//  Fetches player achievements for a single game via Steam Web API.
//

import Foundation

class AchievementFetch {
    private static var apiKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "SteamWebAPIKey") as? String
    }

    /// Fetches achievements for `appid`. Returns nil if the game has no stats or on error.
    func fetchAchievements(appid: Int, steamID: String, completion: @escaping (GameAchievements?) -> Void) {
        guard let apiKey = Self.apiKey, !apiKey.isEmpty else {
            print("AchievementFetch missing SteamWebAPIKey in Info.plist")
            completion(nil)
            return
        }

        let urlString = "https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/"
            + "?appid=\(appid)&key=\(apiKey)&steamid=\(steamID)&l=en"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                guard let data, error == nil else {
                    if let error {
                        print("Achievement network error (appid \(appid)):", error.localizedDescription)
                    }
                    completion(nil)
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(PlayerAchievementsResponse.self, from: data)
                    let stats = decoded.playerstats
                    // success == false means the game has no achievement system
                    guard stats.success == true, let dtos = stats.achievements else {
                        if let http = response as? HTTPURLResponse {
                            print("Achievement fetch failed (appid \(appid)), status:", http.statusCode, "error:", stats.error ?? "unknown")
                        } else {
                            print("Achievement fetch failed (appid \(appid)), error:", stats.error ?? "unknown")
                        }
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
