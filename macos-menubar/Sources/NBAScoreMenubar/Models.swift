import Foundation

struct ScoreboardEnvelope: Decodable {
    let scoreboard: Scoreboard
}

struct Scoreboard: Decodable {
    let gameDate: String
    let games: [Game]
}

struct Game: Decodable, Identifiable {
    let gameId: String
    let gameStatus: Int
    let gameTimeUTC: String
    let gameClock: String?
    let period: Int
    let homeTeam: TeamLine
    let awayTeam: TeamLine
    let gameLeaders: GameLeaders?

    var id: String { gameId }
    var isScheduled: Bool { gameStatus == 1 }
    var isLive: Bool { gameStatus == 2 }
    var isFinal: Bool { gameStatus == 3 }
    var awayScoreValue: Int { Int(awayTeam.score) ?? 0 }
    var homeScoreValue: Int { Int(homeTeam.score) ?? 0 }
}

struct TeamLine: Decodable {
    let teamTricode: String
    let score: String

    enum CodingKeys: String, CodingKey {
        case teamTricode
        case score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        teamTricode = try container.decode(String.self, forKey: .teamTricode)
        score = decodeLossyString(container, forKey: .score)
    }
}

struct GameLeaders: Decodable {
    let homeLeaders: GameLeader?
    let awayLeaders: GameLeader?
}

struct GameLeader: Decodable {
    let name: String
    let jerseyNum: String?
    let points: String?
    let rebounds: String?
    let assists: String?

    enum CodingKeys: String, CodingKey {
        case name
        case jerseyNum
        case points
        case rebounds
        case assists
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        jerseyNum = decodeOptionalLossyString(container, forKey: .jerseyNum)
        points = decodeOptionalLossyString(container, forKey: .points)
        rebounds = decodeOptionalLossyString(container, forKey: .rebounds)
        assists = decodeOptionalLossyString(container, forKey: .assists)
    }
}

func decodeLossyString<K: CodingKey>(
    _ container: KeyedDecodingContainer<K>,
    forKey key: K
) -> String {
    if let value = try? container.decode(String.self, forKey: key) {
        return value
    }

    if let value = try? container.decode(Int.self, forKey: key) {
        return String(value)
    }

    if let value = try? container.decode(Double.self, forKey: key) {
        return String(Int(value))
    }

    return ""
}

func decodeOptionalLossyString<K: CodingKey>(
    _ container: KeyedDecodingContainer<K>,
    forKey key: K
) -> String? {
    if (try? container.decodeNil(forKey: key)) == true {
        return nil
    }

    let value = decodeLossyString(container, forKey: key)
    return value.isEmpty ? nil : value
}
