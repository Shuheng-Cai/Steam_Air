//
//  SteamDeal.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import Foundation

struct SteamDeal {
    let appid: Int
    let name: String
    let headerImageURL: String
    let originalPrice: Double
    let finalPrice: Double      
    let discountPercent: Int

    var formattedOriginalPrice: String { String(format: "$%.2f", originalPrice) }
    var formattedFinalPrice: String { String(format: "$%.2f", finalPrice) }
}
