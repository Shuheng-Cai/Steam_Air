//
//  StoreViewController.swift
//  Steam_Air
//
//  Created by  Lucy K Y XU on 4/5/26.
//

internal import UIKit

final class StoreViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Store"
        setupPlaceholder()
    }

    private func setupPlaceholder() {
        let label = UILabel()
        label.text = "Coming Soon"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
