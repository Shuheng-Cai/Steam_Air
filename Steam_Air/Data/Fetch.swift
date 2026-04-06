//
//  Fetch.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/25/26.
//

import Foundation

class FetchGame {
    
    func fetchOwnedGames(steamID: String, completion: @escaping ([Game]) -> Void) {
        guard let url = URL(string: "http://10.232.214.33:5050/owned-games?steamid=\(steamID)") else {
            print("Invalid URL")
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Request error:", error ?? "")
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(OwnedGamesResponse.self, from: data)
                let games = (decoded.response.games ?? []).map { $0.toGame() }
                
                DispatchQueue.main.async {
                    completion(games)
                }
            } catch {
                print("Decode error:", error)
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Returned JSON:")
                    print(jsonString)
                }
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
}
