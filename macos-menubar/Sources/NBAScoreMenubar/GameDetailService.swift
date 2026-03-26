import Foundation

enum GameDetailService {
    static func fetchBoxScore(gameID: String) async throws -> BoxScoreGame {
        let url = URL(string: "https://cdn.nba.com/static/json/liveData/boxscore/boxscore_\(gameID).json")!
        return try await fetch(url, as: BoxScoreEnvelope.self).game
    }

    static func fetchPlayByPlay(gameID: String) async throws -> PlayByPlayGame {
        let url = URL(string: "https://cdn.nba.com/static/json/liveData/playbyplay/playbyplay_\(gameID).json")!
        return try await fetch(url, as: PlayByPlayEnvelope.self).game
    }

    private static func fetch<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScoreboardError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw ScoreboardError.httpStatus(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}
