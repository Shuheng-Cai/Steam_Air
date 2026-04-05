//
//  Fetch.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/25/26.
//

import UIKit

class fetchGame{
    
    var games: [Game] = []
    
    func fetchOwnedGames(apiKey: String, steamID: String, completion: @escaping ([Game]) -> Void) {
        
        let urlString = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=\(apiKey)&steamid=\(steamID)&include_appinfo=true&format=json"
        
        guard let url = URL(string: urlString) else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

            do {
                let decoded = try JSONDecoder().decode(OwnedGamesResponse.self, from: data)
                
                let games = decoded.response.games.map { $0.toGame() }
                
                DispatchQueue.main.async {
                    completion(games)
                }
            } catch {
                print("Decode error:", error)
                DispatchQueue.main.async {
                    completion([])
                }
            }
        }.resume()
    }
    
    func loadImage(from urlString: String, into imageView: UIImageView) {
        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let image = UIImage(data: data) else { return }

            DispatchQueue.main.async {
                imageView.image = image
            }
        }.resume()
    }
}
