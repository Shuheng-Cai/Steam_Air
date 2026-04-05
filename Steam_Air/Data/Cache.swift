//
//  Cache.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/30/26.
//

import Foundation
import UIKit

class GameImageCache {
    static let shared = NSCache<NSString, UIImage>()
    
    static func GetGameImage(forKey key: String) -> UIImage? {
        return GameImageCache.shared.object(forKey: key as NSString)
    }
    
    static func loadImage(from urlString: String, into imageView: UIImageView) {

        if let cachedImage = GameImageCache.shared.object(forKey: urlString as NSString) {
            imageView.image = cachedImage
            return
        }

        guard let url = URL(string: urlString) else { return }

        URLSession.shared.dataTask(with: url) { data, _, _ in

            if let data = data, let image = UIImage(data: data) {

                GameImageCache.shared.setObject(image, forKey: urlString as NSString)

                DispatchQueue.main.async {
                    imageView.image = image
                }
            }

        }.resume()
    }
}
