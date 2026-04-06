//
//  PriceHistory.swift
//  Steam_Air
//
//  NOTE: Steam has no official price history API.
//  In production, integrate IsThereAnyDeal (itad.com) or SteamDB.
//  This file provides a model + mock generator for UI development.
//

import Foundation

struct PricePoint {
    let date: Date
    let price: Double
}

struct GamePriceHistory {
    let appid: Int
    let gameName: String
    let currentPrice: Double
    let allTimeLow: Double
    let allTimeHigh: Double
    let averagePrice: Double
    let history: [PricePoint]
    let isRecommendedToBuy: Bool

    static func mock(for item: WishlistItem) -> GamePriceHistory {
        let basePrice = item.originalPrice ?? item.currentPrice ?? 29.99
        let currentPrice = item.currentPrice ?? basePrice
        let now = Date()
        let calendar = Calendar.current

        // Simulated discount pattern: index 0 = 11 months ago, index 11 = now
        let discountPattern = [0, 0, 25, 0, 50, 0, 10, 0, 75, 0, 25, item.discountPercent]
        var points: [PricePoint] = []
        for i in 0..<12 {
            let date = calendar.date(byAdding: .month, value: i - 11, to: now)!
            let pct = discountPattern[i]
            let price = basePrice * (1.0 - Double(pct) / 100.0)
            points.append(PricePoint(date: date, price: price))
        }

        let prices = points.map { $0.price }
        let low = prices.min() ?? basePrice
        let high = prices.max() ?? basePrice
        let avg = prices.reduce(0, +) / Double(prices.count)
        let isRecommended = currentPrice <= low * 1.15  // within 15% of all-time low

        return GamePriceHistory(
            appid: item.appid,
            gameName: item.name,
            currentPrice: currentPrice,
            allTimeLow: low,
            allTimeHigh: high,
            averagePrice: avg,
            history: points,
            isRecommendedToBuy: isRecommended
        )
    }
}
