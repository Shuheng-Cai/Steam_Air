//
//  DetailViewController.swift
//  Steam_Air
//
//  Created by  csh's computer on 4/3/26.
//

import UIKit

class DetailViewController: UIViewController {
    
    var Game: Game?
    
    @IBOutlet weak var GamePosterImage: CardImageView!
    @IBOutlet weak var GameTitle: UILabel!
    
    @IBOutlet weak var GamePlayTime: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showGame()
    }
    
    func showGame() {
        GameTitle.text = Game?.name
        GameImageCache.loadImage(from: Game!.iconURL, into: GamePosterImage)
        let total = Game?.playtime_forever ?? 0
        let recent = Game?.playtime_2weeks ?? 0

        GamePlayTime.text = "Play Time: \(total) min, Recently: \(recent) min"
    }
}
