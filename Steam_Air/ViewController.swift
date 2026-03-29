//
//  ViewController.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/23/26.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        fetchGame().fetchOwnedGames(apiKey: "CD89B4D216CF0A68E8970744826761AF", steamID: "76561198803168936") { games in
            for game in games {
                print(game.name, game.playtimeHours)
            }
        }
    }
}

