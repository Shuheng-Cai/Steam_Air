//
//  WishlistAPI.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/6/26.
//
//

import Foundation

struct WishlistServiceResponse: Codable {
    let response: WishlistServiceBody
}

struct WishlistServiceBody: Codable {
    let items: [WishlistServiceItem]?
}


struct WishlistServiceItem: Codable {
    let appid: Int
    let date_added: Int?   // Unix timestamp
    let priority: Int?     // 0 = highest priority
    let as_of: Int?        // timestamp of last sync
}


struct AppDetailResponse: Codable {
    let success: Bool
    let data: AppDetailData?
}

struct AppDetailData: Codable {
    let name: String
    let steam_appid: Int
    let is_free: Bool
    let price_overview: AppDetailPriceOverview?
}

struct AppDetailPriceOverview: Codable {
    let currency: String
    let initial: Int
    let final: Int
    let discount_percent: Int
    let initial_formatted: String?
    let final_formatted: String?

    func toWishlistPricing() -> (current: Double, original: Double?, discount: Int) {
        let current  = Double(final)   / 100.0
        let original = discount_percent > 0 ? Double(initial) / 100.0 : nil
        return (current, original, discount_percent)
    }
}


struct WishlistSubDTO: Codable {
    let id: Int?
    let discount_pct: Int?
    let price: FlexibleInt?
    let price_before_discount: FlexibleInt?
}

struct WishlistItemDTO: Codable {
    let name: String
    let is_free_game: Bool
    let subs: [WishlistSubDTO]?
    let added: Int?
    let priority: Int?

    func toWishlistItem(appid: Int) -> WishlistItem {
        let sub = subs?.first(where: { ($0.price?.value ?? 0) > 0 }) ?? subs?.first
        let discountPct = sub?.discount_pct ?? 0
        let priceInt = sub?.price?.value ?? 0

        var currentPrice: Double?
        var originalPrice: Double?

        if !is_free_game, priceInt > 0 {
            currentPrice = Double(priceInt) / 100.0
            if discountPct > 0 {
                if let before = sub?.price_before_discount?.value, before > 0 {
                    originalPrice = Double(before) / 100.0
                } else {
                    originalPrice = currentPrice! / (1.0 - Double(discountPct) / 100.0)
                }
            }
        }

        let iconURL = "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appid)/library_600x900.jpg"
        return WishlistItem(
            appid: appid,
            name: name,
            iconURL: iconURL,
            currentPrice: currentPrice,
            originalPrice: originalPrice,
            discountPercent: discountPct,
            isFreeGame: is_free_game,
            addedDate: added.map { Date(timeIntervalSince1970: TimeInterval($0)) },
            priority: priority ?? 0
        )
    }
}

struct FlexibleInt: Codable {
    let value: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
            return
        }
        if let strValue = try? container.decode(String.self) {
            value = Int(strValue) ?? 0
            return
        }
        value = 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
