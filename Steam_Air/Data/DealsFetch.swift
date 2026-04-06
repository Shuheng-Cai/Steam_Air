//
//  DealsFetch.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.

import Foundation

class DealsFetch {

    func fetchDeals(completion: @escaping ([SteamDeal]) -> Void) {
        let urlString = "https://store.steampowered.com/api/featuredcategories/?cc=US&l=en"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("DealsFetch network error:", error ?? "unknown")
                    completion([])
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(FeaturedCategoriesResponse.self, from: data)
                    let deals = (decoded.specials?.items ?? []).compactMap { $0.toSteamDeal() }
                    completion(deals)
                } catch {
                    print("DealsFetch decode error:", error)
                    completion([])
                }
            }
        }.resume()
    }
}
