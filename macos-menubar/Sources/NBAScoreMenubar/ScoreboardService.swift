import Foundation

enum ScoreboardService {
    static let scoreboardURL = URL(string: "https://cdn.nba.com/static/json/liveData/scoreboard/todaysScoreboard_00.json")!
    static let webScoreboardURL = URL(string: "https://www.nba.com/games")!

    static func fetchScoreboard() async throws -> Scoreboard {
        var request = URLRequest(url: scoreboardURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScoreboardError.invalidResponse
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw ScoreboardError.httpStatus(httpResponse.statusCode)
        }

        return try JSONDecoder().decode(ScoreboardEnvelope.self, from: data).scoreboard
    }
}

enum ScoreboardError: LocalizedError {
    case invalidResponse
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The NBA scoreboard service returned an invalid response."
        case .httpStatus(let statusCode):
            return "The NBA scoreboard service returned HTTP \(statusCode)."
        }
    }
}
