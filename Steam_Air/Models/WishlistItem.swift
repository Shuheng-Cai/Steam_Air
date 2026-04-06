//
//  WishlistItem.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import Foundation

struct WishlistItem {
    let appid: Int
    let name: String
    let iconURL: String
    let currentPrice: Double?
    let originalPrice: Double?
    let discountPercent: Int
    let isFreeGame: Bool
    let addedDate: Date?
    let priority: Int              

    var formattedCurrentPrice: String {
        if isFreeGame { return "Free" }
        guard let price = currentPrice else { return "N/A" }
        return String(format: "$%.2f", price)
    }

    var formattedOriginalPrice: String {
        guard let price = originalPrice else { return "" }
        return String(format: "$%.2f", price)
    }

    var isOnSale: Bool { discountPercent > 0 }
}
