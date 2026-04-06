//
//  AchievementAPI.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import Foundation

struct PlayerAchievementsResponse: Codable {
    let playerstats: PlayerAchievementStats
}

struct PlayerAchievementStats: Codable {
    let steamID: String?
    let gameName: String?
    let achievements: [AchievementDTO]?
    let success: Bool?
    let error: String?
}

struct AchievementDTO: Codable {
    let apiname: String
    let achieved: Int
    let unlocktime: Int
    let name: String?
    let description: String?
}

extension AchievementDTO {
    func toAchievement() -> Achievement {
        Achievement(
            apiName: apiname,
            name: name ?? apiname,
            description: description ?? "",
            achieved: achieved == 1,
            unlockTime: unlocktime > 0 ? Date(timeIntervalSince1970: TimeInterval(unlocktime)) : nil
        )
    }
}
