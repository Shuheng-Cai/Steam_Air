//
//  WishlistFetch.swift
//  Steam_Air
//
//  Created by Lucy K Y XU on 4/5/26.
//

import Foundation

class WishlistFetch {

    func fetchWishlist(steamID: String, completion: @escaping ([WishlistItem]) -> Void) {
        let urlString = "https://store.steampowered.com/wishlist/profiles/\(steamID)/wishlistdata/?p=0"
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    print("WishlistFetch network error:", error ?? "unknown")
                    completion([])
                    return
                }

                // Private / empty wishlist returns "[]"
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
                    print("WishlistFetch decode error:", error)
                    completion([])
                }
            }
        }.resume()
    }
}
