//
//  WishlistFetch.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/6/26.
//
//  
//

import Foundation

private let apiKey  = "CD89B4D216CF0A68E8970744826761AF"
private let batchSize = 20

class WishlistFetch {


    func fetchWishlist(steamID: String, completion: @escaping ([WishlistItem]) -> Void) {
        fetchFromOfficialAPI(steamID: steamID) { [weak self] items in
            if items.isEmpty {
                self?.fetchFromStore(steamID: steamID, completion: completion)
            } else {
                completion(items)
            }
        }
    }


    private func fetchFromOfficialAPI(steamID: String,
                                      completion: @escaping ([WishlistItem]) -> Void) {
        let urlStr = "https://api.steampowered.com/IWishlistService/GetWishlist/v1/?key=\(apiKey)&steamid=\(steamID)"
        guard let url = URL(string: urlStr) else { completion([]); return }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data, error == nil else {
                print("WishlistFetch official API error:", error ?? "unknown")
                DispatchQueue.main.async { completion([]) }
                return
            }

            do {
                let decoded = try JSONDecoder().decode(WishlistServiceResponse.self, from: data)
                let serviceItems = decoded.response.items ?? []
                if serviceItems.isEmpty {
                    DispatchQueue.main.async { completion([]) }
                    return
                }
                
                self.fetchAppDetails(for: serviceItems, completion: completion)
            } catch {
                print("WishlistFetch official API decode error:", error)
                DispatchQueue.main.async { completion([]) }
            }
        }.resume()
    }

    private func fetchAppDetails(for serviceItems: [WishlistServiceItem],
                                 completion: @escaping ([WishlistItem]) -> Void) {
        let appids = serviceItems.map { $0.appid }
        var detailMap: [Int: AppDetailData] = [:]
        let lock  = NSLock()
        let group = DispatchGroup()

        // Split into batches of `batchSize`
        let batches = stride(from: 0, to: appids.count, by: batchSize).map {
            Array(appids[$0 ..< min($0 + batchSize, appids.count)])
        }

        for batch in batches {
            group.enter()
            let appidsParam = batch.map { String($0) }.joined(separator: ",")
            let urlStr = "https://store.steampowered.com/api/appdetails?appids=\(appidsParam)&cc=us&l=en"
            guard let url = URL(string: urlStr) else { group.leave(); continue }

            URLSession.shared.dataTask(with: url) { data, _, error in
                defer { group.leave() }
                guard let data, error == nil else {
                    print("WishlistFetch appdetails error:", error ?? "unknown")
                    return
                }
                guard let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

                for (key, value) in raw {
                    guard let appid = Int(key),
                          let entry = value as? [String: Any],
                          let success = entry["success"] as? Bool, success,
                          let dataDict = entry["data"]
                    else { continue }

                    if let detailData = try? JSONSerialization.data(withJSONObject: dataDict),
                       let detail = try? JSONDecoder().decode(AppDetailData.self, from: detailData) {
                        lock.lock()
                        detailMap[appid] = detail
                        lock.unlock()
                    }
                }
            }.resume()
        }

        group.notify(queue: .main) {
            let items = serviceItems.compactMap { si -> WishlistItem? in
                guard let detail = detailMap[si.appid] else { return nil }

                var currentPrice: Double?
                var originalPrice: Double?
                var discountPct = 0

                if !detail.is_free, let po = detail.price_overview {
                    let pricing = po.toWishlistPricing()
                    currentPrice  = pricing.current
                    originalPrice = pricing.original
                    discountPct   = pricing.discount
                }

                let iconURL = "https://cdn.cloudflare.steamstatic.com/steam/apps/\(si.appid)/library_600x900.jpg"
                return WishlistItem(
                    appid:          si.appid,
                    name:           detail.name,
                    iconURL:        iconURL,
                    currentPrice:   currentPrice,
                    originalPrice:  originalPrice,
                    discountPercent: discountPct,
                    isFreeGame:     detail.is_free,
                    addedDate:      si.date_added.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                    priority:       si.priority ?? 0
                )
            }.sorted { $0.priority < $1.priority }

            completion(items)
        }
    }

    private func fetchFromStore(steamID: String, completion: @escaping ([WishlistItem]) -> Void) {
        let urlStr = "https://store.steampowered.com/wishlist/profiles/\(steamID)/wishlistdata/?p=0"
        guard let url = URL(string: urlStr) else {
            DispatchQueue.main.async { completion([]) }
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data, error == nil else {
                    print("WishlistFetch store fallback error:", error ?? "unknown")
                    completion([])
                    return
                }

                let raw = String(data: data, encoding: .utf8) ?? ""
                if raw.trimmingCharacters(in: .whitespacesAndNewlines) == "[]" {
                    completion([])
                    return
                }

                do {
                    let dict = try JSONDecoder().decode([String: WishlistItemDTO].self, from: data)
                    let items = dict.compactMap { key, dto -> WishlistItem? in
                        guard let appid = Int(key) else { return nil }
                        return dto.toWishlistItem(appid: appid)
                    }.sorted { $0.priority < $1.priority }
                    completion(items)
                } catch {
                    print("WishlistFetch store fallback decode error:", error)
                    completion([])
                }
            }
        }.resume()
    }
}
