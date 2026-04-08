//
//  CardView.swift
//  Steam_Air
//
//  Created by  csh's computer on 3/30/26.
//

internal import UIKit


class CardView : UIView{
    override func awakeFromNib() {
         super.awakeFromNib()
         setup()
     }

     override func layoutSubviews() {
         super.layoutSubviews()
     }

     private func setup() {
         layer.cornerRadius = 12
         layer.borderWidth = 1
         layer.borderColor = UIColor.systemGray5.cgColor
         backgroundColor = .systemBackground
         clipsToBounds = true
     }
}
