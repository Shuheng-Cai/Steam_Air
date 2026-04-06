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
    let specials: SpecialsSection?
}

struct SpecialsSection: Codable {
    let id: Int
    let name: String
    let items: [DealItemDTO]
}

struct DealItemDTO: Codable {
    let id: Int
    let name: String
    let discounted: Int
    let discount_percent: Int
    let original_price: Int?
    let final_price: Int
    let large_capsule_image: String?
    let small_capsule_image: String?
    let header_image: String?

    func toSteamDeal() -> SteamDeal? {
        guard discount_percent > 0 else { return nil }
        let originalCents = original_price ?? final_price
        let imageURL = header_image ?? large_capsule_image ?? small_capsule_image ?? ""
        return SteamDeal(
            appid: id,
            name: name,
            headerImageURL: imageURL,
            originalPrice: Double(originalCents) / 100.0,
            finalPrice: Double(final_price) / 100.0,
            discountPercent: discount_percent
        )
    }
}
