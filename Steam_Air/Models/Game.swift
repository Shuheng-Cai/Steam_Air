//
//  Untitled.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/25/26.
//  The data structure fro the GameLibrary.

import Foundation


struct Game {
    let appid: Int
    let name: String
    let playtime_forever: Int
    let playtime_2weeks: Int
    var iconURL: String
    let lastPlayedDate: Date?
}
