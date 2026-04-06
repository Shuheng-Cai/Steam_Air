//
//  Achievement.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import Foundation

struct Achievement {
    let apiName: String
    let name: String
    let description: String
    let achieved: Bool
    let unlockTime: Date?
}

struct GameAchievements {
    let appid: Int
    let gameName: String
    let achievements: [Achievement]

    var unlockedCount: Int { achievements.filter { $0.achieved }.count }
    var totalCount: Int    { achievements.count }
    var progress: Float   { totalCount > 0 ? Float(unlockedCount) / Float(totalCount) : 0 }
}
