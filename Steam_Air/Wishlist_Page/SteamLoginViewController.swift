//
//  SteamLoginViewController.swift
//  Steam_Air
//
//  Presents a WKWebView pointing at the Steam store login page.
//  After the user signs in, the sessionid cookie is captured from the
//  WKWebView cookie store and saved to SteamAuthManager.
//

import UIKit
import WebKit

final class SteamLoginViewController: UIViewController {

    /// Called on the main queue after successful authentication.
    var onAuthenticated: (() -> Void)?

    private lazy var webView: WKWebView = {
        // Use a non-persistent data store so existing app sessions are not affected
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.navigationDelegate = self
        wv.translatesAutoresizingMaskIntoConstraints = false
        return wv
    }()

    private let spinner: UIActivityIndicatorView = {
        let s = UIActivityIndicatorView(style: .medium)
        s.hidesWhenStopped = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Sign in to Steam"
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancelTapped)
        )

        view.addSubview(webView)
        view.addSubview(spinner)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        loadLoginPage()
    }

    // MARK: - Private

    private func loadLoginPage() {
        let url = URL(string: "https://store.steampowered.com/login/")!
        webView.load(URLRequest(url: url))
        spinner.startAnimating()
    }

    /// Reads the WKWebView's cookie store looking for a steampowered.com sessionid.
    /// If found, saves it and dismisses.
    private func checkForSessionCookie() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self else { return }

            // Transfer all steampowered.com cookies to URLSession's shared storage
            // so SteamAuthManager's URLSession requests carry them automatically.
            for cookie in cookies where cookie.domain.contains("steampowered.com") {
                HTTPCookieStorage.shared.setCookie(cookie)
            }

            if let sessionCookie = cookies.first(where: {
                $0.domain.contains("steampowered.com") && $0.name == "sessionid"
            }) {
                SteamAuthManager.shared.sessionID = sessionCookie.value
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.onAuthenticated?()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension SteamLoginViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        spinner.startAnimating()
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        spinner.stopAnimating()

        guard let url = webView.url?.absoluteString else { return }

        // Detect successful login: we've navigated away from /login to any other store page
        let onLoginPage = url.contains("/login") || url.contains("/join")
        if !onLoginPage && url.contains("steampowered.com") {
            checkForSessionCookie()
        }
    }

    func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        spinner.stopAnimating()
    }
}
