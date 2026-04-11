//
//  News.swift
//  Steam_Air
//
//  Created by  csh's computer on 4/5/26.
//

import Foundation

struct News: Codable {
    let title: String
    let content: String
    let iconURL: String
    let url: String
    let publishedAt: Date?
}
