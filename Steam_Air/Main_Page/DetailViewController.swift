//
//  DetailViewController.swift
//  Steam_Air
//
//  Created by  csh's computer on 4/3/26.
//

internal import UIKit

class DetailViewController: UIViewController {

    var Game: Game?

    @IBOutlet weak var GamePosterImage: CardImageView!
    @IBOutlet weak var GameTitle: UILabel!
    @IBOutlet weak var GamePlayTime: UILabel!
    @IBOutlet weak var wishlistButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        showGame()
        updateWishlistButton()
    }

    func showGame() {
        GameTitle.text = Game?.name
        GameImageCache.loadImage(from: Game!.iconURL, into: GamePosterImage)
        let total = Game?.playtime_forever ?? 0
        let recent = Game?.playtime_2weeks ?? 0
        GamePlayTime.text = "Play Time: \(total) min, Recently: \(recent) min"
    }

    private func updateWishlistButton() {
        guard let appid = Game?.appid else { return }
        let inWishlist = LocalWishlistManager.shared.contains(appid)
        var config = wishlistButton.configuration ?? UIButton.Configuration.tinted()
        config.title = inWishlist ? "In Wishlist" : "Add to Wishlist"
        config.baseForegroundColor = inWishlist ? .systemGreen : .systemBlue
        config.baseBackgroundColor = inWishlist ? .systemGreen : .systemBlue
        wishlistButton.configuration = config
    }

    @IBAction func wishlistButtonTapped(_ sender: UIButton) {
        guard let game = Game else { return }
        let manager = LocalWishlistManager.shared
        if manager.contains(game.appid) {
            manager.remove(appid: game.appid)
        } else {
            manager.add(game: game)
        }
        updateWishlistButton()
    }

    @IBAction func viewOnSteamTapped(_ sender: UIButton) {
        guard let appid = Game?.appid,
              let url = URL(string: "https://store.steampowered.com/app/\(appid)") else { return }
        UIApplication.shared.open(url)
    }
}
