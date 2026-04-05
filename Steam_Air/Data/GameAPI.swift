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
    let playtime2weeks: Int?
    let imgIconUrl: String?

    enum CodingKeys: String, CodingKey {
        case appid
        case name
        case playtime2weeks = "playtime_2weeks"
        case playtimeForever = "playtime_forever"
        case imgIconUrl = "img_icon_url"
    }
}

extension GameDTO {
    func toGame() -> Game {
        Game(
            appid: appid,
            name: name ?? "Unknown Game",
            playtime_forever: playtimeForever,
            playtime_2weeks: playtime2weeks ?? 0,
            iconURL: imgIconUrl.map { hash in
                "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appid)/library_600x900.jpg"
            }!
        )
    }
}
