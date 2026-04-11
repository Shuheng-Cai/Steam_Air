//
//  NewsAPI.swift
//  Steam_Air
//
//  Created by  csh's computer on 4/5/26.
//

import Foundation

struct NewsResponse: Codable {
    let appnews: AppNews
}

struct AppNews: Codable {
    let appid: Int
    let newsitems: [NewsDTO]
}

struct NewsDTO: Codable {
    let gid: String
    let title: String
    let url: String
    let contents: String
    let date: Int?
}

extension NewsDTO {
    func toNews(appid: Int) -> News {
        return News(
            title: title,
            content: contents,
            iconURL: "https://cdn.cloudflare.steamstatic.com/steam/apps/\(appid)/library_600x900.jpg",
            url: url,
            publishedAt: date.map { Date(timeIntervalSince1970: TimeInterval($0)) }
        )
    }
}
