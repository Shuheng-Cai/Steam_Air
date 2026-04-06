//
//  WishlistAPI.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//  Steam wishlist endpoint returns a JSON object with appid strings as keys.
//  Endpoint: https://store.steampowered.com/wishlist/profiles/{steamid}/wishlistdata/
//

import Foundation

struct WishlistSubDTO: Codable {
    let id: Int?
    let discount_pct: Int?
    let price: String?
    let price_before_discount: Int?
}

struct WishlistItemDTO: Codable {
    let name: String
    let is_free_game: Bool
    let subs: [WishlistSubDTO]?
    let added: Int?
    let priority: Int?

    func toWishlistItem(appid: Int) -> WishlistItem {
        // Pick the first sub that has a non-zero price, fall back to first sub
        let sub = subs?.first(where: { ($0.price ?? "0") != "0" }) ?? subs?.first
        let discountPct = sub?.discount_pct ?? 0
        let priceInt = Int(sub?.price ?? "0") ?? 0

        var currentPrice: Double?
        var originalPrice: Double?

        if !is_free_game, priceInt > 0 {
            currentPrice = Double(priceInt) / 100.0
            if discountPct > 0 {
                if let before = sub?.price_before_discount, before > 0 {
                    originalPrice = Double(before) / 100.0
                } else {
                    // Estimate from discount percentage
                    originalPrice = currentPrice! / (1.0 - Double(discountPct) / 100.0)
                }
            }
        }

        let addedDate = added.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        let iconURL = "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appid)/library_600x900.jpg"

        return WishlistItem(
            appid: appid,
            name: name,
            iconURL: iconURL,
            currentPrice: currentPrice,
            originalPrice: originalPrice,
            discountPercent: discountPct,
            isFreeGame: is_free_game,
            addedDate: addedDate,
            priority: priority ?? 0
        )
    }
}
