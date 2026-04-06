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
    let history: [PricePoint]       // daily granularity, ~365 days
    let isRecommendedToBuy: Bool

    // MARK: - Mock generator
    //
    // Generates one data point per day for the past 365 days, simulating
    // Steam's four annual sale windows so all time-range filters have data.

    static func mock(for item: WishlistItem) -> GamePriceHistory {
        let basePrice  = item.originalPrice ?? item.currentPrice ?? 29.99
        let currentPrice = item.currentPrice ?? basePrice
        let now      = Date()
        let calendar = Calendar.current

        var points: [PricePoint] = []

        for daysAgo in stride(from: 364, through: 0, by: -1) {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            let comps = calendar.dateComponents([.month, .day], from: date)
            let month = comps.month ?? 1
            let day   = comps.day   ?? 1

            // Simulate Steam seasonal sales:
            // Summer Sale   late Jun → early Jul   -75 %
            // Autumn Sale   mid Nov                 -33 %
            // Winter Sale   late Dec → early Jan   -50 %
            // Spring Sale   late Mar                -25 %
            let discountPct: Double
            switch (month, day) {
            case (6, 25...30), (7, 1...10):   discountPct = 75
            case (12, 22...31), (1, 1...5):   discountPct = 50
            case (11, 18...30):               discountPct = 33
            case (3, 20...31), (4, 1...5):    discountPct = 25
            default:                          discountPct = 0
            }

            let price = basePrice * (1.0 - discountPct / 100.0)
            points.append(PricePoint(date: date, price: price))
        }

        // Last point reflects the actual current price
        points[points.count - 1] = PricePoint(date: now, price: currentPrice)

        let prices = points.map { $0.price }
        let low    = prices.min() ?? basePrice
        let high   = prices.max() ?? basePrice
        let avg    = prices.reduce(0, +) / Double(prices.count)

        return GamePriceHistory(
            appid: item.appid,
            gameName: item.name,
            currentPrice: currentPrice,
            allTimeLow: low,
            allTimeHigh: high,
            averagePrice: avg,
            history: points,
            isRecommendedToBuy: currentPrice <= low * 1.15
        )
    }
}
