//
//  HomeViewController.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/30/26.
//

import UIKit

class HomeViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var recommendedCollectionView: UICollectionView!
    @IBOutlet weak var newsCollectionView: UICollectionView!
    
    var games: [Game] = []
    var news: [News] = []
    var steamID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        recommendedCollectionView.delegate = self
        recommendedCollectionView.dataSource = self
        
        newsCollectionView.delegate = self
        newsCollectionView.dataSource = self
        
        if let layout = recommendedCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.itemSize = CGSize(width: 140, height: 180)
        }
        guard let steamID = steamID else {
            print("steamID is nil")
            return
        }
        
        fetchGame().fetchOwnedGames(steamID: steamID) { games in
                DispatchQueue.main.async {
                    self.games = games
                    self.recommendedCollectionView.reloadData()
                    
                    self.news = []
                    
                    var remaining = games.count

                    for game in games {
                        fetchNews().fetchNews(appid: game.appid) { news in
                            self.news.append(contentsOf: news)
                            
                            remaining -= 1
                            
                            if remaining == 0 {
                                self.newsCollectionView.reloadData()
                            }
                        }
                    }
                    
                }
            }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == recommendedCollectionView{
            return games.count
        }
        
        if collectionView == newsCollectionView{
            return news.count
        }
        
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == recommendedCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameCell", for: indexPath) as! GameCell
            
            // Fill name
            GameImageCache.loadImage(from: games[indexPath.row].iconURL, into: cell.gameImageView)
            
            cell.gameNameLabel.text = games[indexPath.row].name
            
            return cell
        }
        
        if collectionView == newsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NewsCell", for: indexPath) as! NewsCell
            
            GameImageCache.loadImage(from: news[indexPath.row].iconURL, into: cell.newsImage)
            cell.newsTitle.text = news[indexPath.row].title
            
            return cell
        }
        
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == recommendedCollectionView {
            let selectGame = games[indexPath.row]
            let storyboard = UIStoryboard(name: "HomePageScreen", bundle: nil)
            let detailVC = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
            
            detailVC.Game = selectGame
            
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
        
    }
}
