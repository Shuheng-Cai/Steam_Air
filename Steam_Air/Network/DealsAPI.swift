//
//  DealsAPI.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//
//  Uses Steam's featured categories endpoint to get current discounted games.
//  Endpoint: https://store.steampowered.com/api/featuredcategories/?cc=US&l=en
//

import Foundation

struct FeaturedCategoriesResponse: Codable {
    let specials: FeaturedSection?
    let top_sellers: FeaturedSection?
    let new_releases: FeaturedSection?
}

struct StoreSearchResponse: Codable {
    let total: Int
    let items: [StoreSearchItemDTO]
}

struct StoreSearchItemDTO: Codable {
    let type: String?
    let name: String
    let id: Int
    let tiny_image: String?
    let price: StoreSearchPriceDTO?

    func toStoreDeal() -> SteamDeal {
        let initialCents = price?.initial ?? 0
        let finalCents = price?.final ?? initialCents

        let discountPercent: Int
        if initialCents > 0, finalCents < initialCents {
            discountPercent = Int(((Double(initialCents - finalCents) / Double(initialCents)) * 100.0).rounded())
        } else {
            discountPercent = 0
        }

        let normalizedImage: String = {
            guard let tiny_image else { return "" }
            if tiny_image.hasPrefix("http://") {
                return "https://" + tiny_image.dropFirst("http://".count)
            }
            return tiny_image
        }()

        return SteamDeal(
            appid: id,
            name: name,
            headerImageURL: normalizedImage,
            originalPrice: Double(initialCents) / 100.0,
            finalPrice: Double(finalCents) / 100.0,
            discountPercent: discountPercent
        )
    }
}

struct StoreSearchPriceDTO: Codable {
    let currency: String?
    let initial: Int?
    let final: Int?
}

struct FeaturedSection: Codable {
    let id: String
    let name: String
    let items: [FeaturedItemDTO]
}

struct FeaturedItemDTO: Codable {
    let id: Int
    let name: String
    let discounted: Bool?
    let discount_percent: Int?
    let original_price: Int?
    let final_price: Int?
    let large_capsule_image: String?
    let small_capsule_image: String?
    let header_image: String?

    func toSteamDeal() -> SteamDeal? {
        guard (discount_percent ?? 0) > 0, let finalPrice = final_price else { return nil }
        let originalCents = original_price ?? final_price
        let imageURL = header_image ?? large_capsule_image ?? small_capsule_image ?? ""
        guard let originalCents else { return nil }
        return SteamDeal(
            appid: id,
            name: name,
            headerImageURL: imageURL,
            originalPrice: Double(originalCents) / 100.0,
            finalPrice: Double(finalPrice) / 100.0,
            discountPercent: discount_percent ?? 0
        )
    }

    func toStoreDeal() -> SteamDeal? {
        let imageURL = header_image ?? large_capsule_image ?? small_capsule_image ?? ""
        let finalCents = final_price ?? original_price
        guard let finalCents else { return nil }
        let originalCents = original_price ?? finalCents

        let effectiveDiscount: Int
        if let discountPercent = discount_percent {
            effectiveDiscount = max(0, discountPercent)
        } else if originalCents > 0, finalCents < originalCents {
            effectiveDiscount = Int(((Double(originalCents - finalCents) / Double(originalCents)) * 100.0).rounded())
        } else {
            effectiveDiscount = 0
        }

        return SteamDeal(
            appid: id,
            name: name,
            headerImageURL: imageURL,
            originalPrice: Double(originalCents) / 100.0,
            finalPrice: Double(finalCents) / 100.0,
            discountPercent: effectiveDiscount
        )
    }

    var bestImageURL: String {
        header_image ?? large_capsule_image ?? small_capsule_image ?? ""
    }
}
