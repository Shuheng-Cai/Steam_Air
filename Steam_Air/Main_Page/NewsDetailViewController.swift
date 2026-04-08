//
//  NewsDetailViewController.swift
//  Steam_Air
//
//  Created by  csh's computer on 4/6/26.
//

internal import UIKit

class NewsDetailViewController: UIViewController {
    
    var news: News?
    @IBOutlet weak var Image: CardImageView!
    @IBOutlet weak var newsTitle: UILabel!
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        showNews()
    }
    
    func showNews(){
        newsTitle.text = news?.title
        GameImageCache.loadImage(from: news!.iconURL, into: Image)
        let html = news?.content
        
        let attributedString = htmlToAttributedString(html ?? "")
        textView.attributedText = attributedString
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.dataDetectorTypes = .link
        
    }
   
    func htmlToAttributedString(_ html: String) -> NSAttributedString? {
        guard let data = html.data(using: .utf8) else { return nil }
        
        return try? NSAttributedString(
            data: data,
            options: [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ],
            documentAttributes: nil
        )
    }
    
}
