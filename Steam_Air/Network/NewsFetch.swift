//
//  NewsFetch.swift
//  Steam_Air
//
//  Created by  csh's computer on 4/5/26.
//

import Foundation
internal import UIKit

class fetchNews{
    var news: [News] = []
    func fetchNews(appid: Int, completion: @escaping ([News]) -> Void) {
        print("🔥 fetchNews called with appid:", appid)
            let urlString = "https://api.steampowered.com/ISteamNews/GetNewsForApp/v0002/?appid=\(appid)&count=1&format=json"
            
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error:", error)
                        completion([])
                        return
                    }
                    guard let data = data else {
                        completion([])
                        return
                    }
                    do {
                        let decoded = try JSONDecoder().decode(NewsResponse.self, from: data)
                        let news = decoded.appnews.newsitems.map { $0.toNews(appid: appid) }
                        completion(news)
                    } catch {
                        print("Decode error:", error)
                        completion([])
                    }
                }
            }.resume()
        }
}
