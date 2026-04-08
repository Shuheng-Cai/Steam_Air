//
//  ViewController.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/23/26.
//

internal import UIKit

class ViewController: UIViewController {
    
    var steamID: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        guard let steamID = steamID else {
            print("steam ID is nil")
            return
        }
        
        let fetcher = fetchGame()
        fetcher.fetchOwnedGames(steamID: steamID) { games in
            print("Games count:", games.count)
            for game in games.prefix(10) {
                print(game.name)
            }
        }
    }
}

