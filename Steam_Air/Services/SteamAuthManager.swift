//
//  SteamAuthManager.swift
//  Steam_Air
//
//  Manages the Steam web session obtained via SteamLoginViewController.
//  The sessionid cookie is captured after web login and stored in UserDefaults.
//  It is then used to POST to Steam's add-to-wishlist endpoint.
//

import Foundation

final class SteamAuthManager {

    static let shared = SteamAuthManager()
    private init() {}

    private let sessionIDKey = "steam_sessionid"

    /// The sessionid cookie value from steampowered.com, set after login.
    var sessionID: String? {
        get { UserDefaults.standard.string(forKey: sessionIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: sessionIDKey) }
    }

    var isAuthenticated: Bool { sessionID != nil }

    func logOut() {
        sessionID = nil
    }

    // MARK: - Add to Steam Wishlist

    /// POSTs appid to Steam's wishlist API.
    /// Silently succeeds if not authenticated (local-only mode).
    /// - Parameters:
    ///   - appid: Steam app ID to add
    ///   - completion: called on the main queue with success/failure
    func addToSteamWishlist(appid: Int,
                            completion: @escaping (Result<Void, SteamAuthError>) -> Void) {
        guard let sessionID = sessionID else {
            completion(.failure(.notAuthenticated))
            return
        }

        guard let url = URL(string: "https://store.steampowered.com/api/addtowishlist") else {
            completion(.failure(.badURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("https://store.steampowered.com", forHTTPHeaderField: "Referer")
        // Include sessionid both as cookie and as POST body parameter
        request.setValue("sessionid=\(sessionID)", forHTTPHeaderField: "Cookie")
        request.httpBody = "appid=\(appid)&sessionid=\(sessionID)".data(using: .utf8)

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.network(error)))
                    return
                }
                guard let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool, success
                else {
                    completion(.failure(.apiRejected))
                    return
                }
                completion(.success(()))
            }
        }.resume()
    }

    // MARK: - Batch sync

    /// Syncs all locally-added games to the Steam wishlist.
    /// Calls completion with the number of successfully synced games.
    func syncLocalWishlistToSteam(completion: @escaping (_ synced: Int, _ failed: Int) -> Void) {
        guard isAuthenticated else {
            completion(0, 0)
            return
        }
        let games = LocalWishlistManager.shared.localGames()
        guard !games.isEmpty else {
            completion(0, 0)
            return
        }

        var synced = 0
        var failed = 0
        let group = DispatchGroup()

        for game in games {
            group.enter()
            addToSteamWishlist(appid: game.appid) { result in
                switch result {
                case .success: synced += 1
                case .failure: failed += 1
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(synced, failed)
        }
    }

    // MARK: - Errors

    enum SteamAuthError: LocalizedError {
        case notAuthenticated
        case badURL
        case network(Error)
        case apiRejected

        var errorDescription: String? {
            switch self {
            case .notAuthenticated: return "Not signed in to Steam."
            case .badURL:           return "Invalid Steam API URL."
            case .network(let e):   return e.localizedDescription
            case .apiRejected:      return "Steam rejected the request. Session may have expired."
            }
        }
    }
}
