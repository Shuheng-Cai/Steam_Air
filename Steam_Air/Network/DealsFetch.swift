//
//  DealsFetch.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.

import Foundation

struct StoreSections {
    let specials: [SteamDeal]
    let topSellers: [SteamDeal]
    let newReleases: [SteamDeal]
}

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

    func fetchRecommendedGames(limit: Int = 12, completion: @escaping ([Game]) -> Void) {
        let urlString = "https://store.steampowered.com/api/featuredcategories/?cc=US&l=en"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("DealsFetch recommended network error:", error ?? "unknown")
                    completion([])
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(FeaturedCategoriesResponse.self, from: data)
                    let buckets: [[FeaturedItemDTO]] = [
                        decoded.top_sellers?.items ?? [],
                        decoded.new_releases?.items ?? [],
                        decoded.specials?.items ?? [],
                    ]

                    var seen = Set<Int>()
                    let merged = buckets
                        .flatMap { $0 }
                        .filter { item in
                            if seen.contains(item.id) {
                                return false
                            }
                            seen.insert(item.id)
                            return true
                        }

                    let recommended = merged.prefix(limit).map { item in
                        Game(
                            appid: item.id,
                            name: item.name,
                            playtime_forever: 0,
                            playtime_2weeks: 0,
                            iconURL: item.bestImageURL,
                            lastPlayedDate: nil
                        )
                    }
                    completion(recommended)
                } catch {
                    print("DealsFetch recommended decode error:", error)
                    completion([])
                }
            }
        }.resume()
    }

    func fetchStoreSections(completion: @escaping (StoreSections) -> Void) {
        let urlString = "https://store.steampowered.com/api/featuredcategories/?cc=US&l=en"
        guard let url = URL(string: urlString) else {
            completion(StoreSections(specials: [], topSellers: [], newReleases: []))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("DealsFetch store network error:", error ?? "unknown")
                    completion(StoreSections(specials: [], topSellers: [], newReleases: []))
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(FeaturedCategoriesResponse.self, from: data)
                    let specials = (decoded.specials?.items ?? []).compactMap { $0.toStoreDeal() }
                    let topSellers = (decoded.top_sellers?.items ?? []).compactMap { $0.toStoreDeal() }
                    let newReleases = (decoded.new_releases?.items ?? []).compactMap { $0.toStoreDeal() }

                    completion(StoreSections(
                        specials: specials,
                        topSellers: topSellers,
                        newReleases: newReleases
                    ))
                } catch {
                    print("DealsFetch store decode error:", error)
                    completion(StoreSections(specials: [], topSellers: [], newReleases: []))
                }
            }
        }.resume()
    }

    func searchStoreGames(term: String, completion: @escaping ([SteamDeal]) -> Void) {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            completion([])
            return
        }

        var components = URLComponents(string: "https://store.steampowered.com/api/storesearch/")
        components?.queryItems = [
            URLQueryItem(name: "term", value: trimmed),
            URLQueryItem(name: "l", value: "en"),
            URLQueryItem(name: "cc", value: "US"),
        ]

        guard let url = components?.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("DealsFetch store search network error:", error ?? "unknown")
                    completion([])
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(StoreSearchResponse.self, from: data)
                    let deals = decoded.items
                        .filter { ($0.type ?? "app") == "app" }
                        .map { $0.toStoreDeal() }
                    completion(deals)
                } catch {
                    print("DealsFetch store search decode error:", error)
                    completion([])
                }
            }
        }.resume()
    }
}
