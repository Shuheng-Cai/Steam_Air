//
//  PriceHistoryFetch.swift
//  Steam_Air
//
//  Created by Codex on 4/15/26.
//

import Foundation

final class PriceHistoryFetch {

    enum PriceHistoryError: LocalizedError {
        case missingAPIKey
        case invalidURL
        case gameNotFound
        case noHistoryData
        case network
        case decode

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing ITAD API key"
            case .invalidURL:
                return "Invalid request URL"
            case .gameNotFound:
                return "Game not found in ITAD"
            case .noHistoryData:
                return "No Steam price history returned"
            case .network:
                return "Network request failed"
            case .decode:
                return "Failed to parse ITAD response"
            }
        }
    }

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private var apiKey: String? {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "ITADAPIKey") as? String else {
            return nil
        }
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func fetchPriceHistory(for item: WishlistItem,
                           country: String = "US",
                           completion: @escaping (Result<GamePriceHistory, Error>) -> Void) {
        guard let apiKey else {
            completion(.failure(PriceHistoryError.missingAPIKey))
            return
        }

        lookupITADGame(appid: item.appid, apiKey: apiKey) { [weak self] result in
            guard let self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let game):
                self.fetchITADHistory(itadGameID: game.id, apiKey: apiKey, country: country) { historyResult in
                    switch historyResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let points):
                        guard !points.isEmpty else {
                            completion(.failure(PriceHistoryError.noHistoryData))
                            return
                        }

                        let prices = points.map(\.price)
                        let currentPrice = prices.last ?? (item.currentPrice ?? 0)
                        let low = prices.min() ?? currentPrice
                        let high = prices.max() ?? currentPrice
                        let avg = prices.reduce(0, +) / Double(prices.count)

                        completion(.success(
                            GamePriceHistory(
                                appid: item.appid,
                                gameName: game.title.isEmpty ? item.name : game.title,
                                currentPrice: currentPrice,
                                allTimeLow: low,
                                allTimeHigh: high,
                                averagePrice: avg,
                                history: points,
                                isRecommendedToBuy: currentPrice <= low * 1.15
                            )
                        ))
                    }
                }
            }
        }
    }

    private func lookupITADGame(appid: Int,
                                apiKey: String,
                                completion: @escaping (Result<ITADLookupGame, Error>) -> Void) {
        var components = URLComponents(string: "https://api.isthereanydeal.com/games/lookup/v1")
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "appid", value: String(appid)),
        ]
        guard let url = components?.url else {
            completion(.failure(PriceHistoryError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion(.failure(PriceHistoryError.network))
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode(ITADLookupResponse.self, from: data)
                    guard decoded.found, let game = decoded.game else {
                        completion(.failure(PriceHistoryError.gameNotFound))
                        return
                    }
                    completion(.success(game))
                } catch {
                    completion(.failure(PriceHistoryError.decode))
                }
            }
        }.resume()
    }

    private func fetchITADHistory(itadGameID: String,
                                  apiKey: String,
                                  country: String,
                                  completion: @escaping (Result<[PricePoint], Error>) -> Void) {
        var components = URLComponents(string: "https://api.isthereanydeal.com/games/history/v2")
        components?.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "id", value: itadGameID),
            URLQueryItem(name: "country", value: country),
            URLQueryItem(name: "shops", value: "61"),
            URLQueryItem(name: "since", value: "2001-01-01T00:00:00Z"),
        ]
        guard let url = components?.url else {
            completion(.failure(PriceHistoryError.invalidURL))
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard let self else { return }
                guard let data = data, error == nil else {
                    completion(.failure(PriceHistoryError.network))
                    return
                }
                do {
                    let entries = try JSONDecoder().decode([ITADHistoryEntry].self, from: data)
                    let points = entries.compactMap { entry -> PricePoint? in
                        guard let timestamp = self.parseITADDate(entry.timestamp),
                              let amount = entry.deal?.price?.amount else {
                            return nil
                        }
                        return PricePoint(date: timestamp, price: amount)
                    }.sorted { $0.date < $1.date }
                    completion(.success(points))
                } catch {
                    completion(.failure(PriceHistoryError.decode))
                }
            }
        }.resume()
    }

    private func parseITADDate(_ raw: String) -> Date? {
        if let date = isoFormatter.date(from: raw) {
            return date
        }
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: raw)
    }
}

private struct ITADLookupResponse: Decodable {
    let found: Bool
    let game: ITADLookupGame?
}

private struct ITADLookupGame: Decodable {
    let id: String
    let title: String
}

private struct ITADHistoryEntry: Decodable {
    let timestamp: String
    let deal: ITADHistoryDeal?
}

private struct ITADHistoryDeal: Decodable {
    let price: ITADMoney?
}

private struct ITADMoney: Decodable {
    let amount: Double
}

