//
//  API.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/25/26.
//

import Foundation

struct OwnedGamesResponse: Codable {
    let response: OwnedGamesData
}

struct OwnedGamesData: Codable {
    let gameCount: Int
    let games: [GameDTO]

    enum CodingKeys: String, CodingKey {
        case gameCount = "game_count"
        case games
    }
}

struct GameDTO: Codable {
    let appid: Int
    let name: String?
    let playtimeForever: Int
    let imgIconUrl: String?

    enum CodingKeys: String, CodingKey {
        case appid
        case name
        case playtimeForever = "playtime_forever"
        case imgIconUrl = "img_icon_url"
    }
}

extension GameDTO {
    func toGame() -> Game {
        Game(
            id: appid,
            name: name ?? "Unknown Game",
            playtimeHours: Double(playtimeForever) / 60.0,
            iconURL: imgIconUrl.flatMap {
                URL(string: "https://media.steampowered.com/steamcommunity/public/images/apps/\(appid)/\($0).jpg")
            }
        )
    }
}
