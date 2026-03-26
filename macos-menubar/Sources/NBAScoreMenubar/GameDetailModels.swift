import Foundation

struct BoxScoreEnvelope: Decodable {
    let game: BoxScoreGame
}

struct BoxScoreGame: Decodable {
    let gameId: String
    let gameStatus: Int
    let gameStatusText: String?
    let period: Int
    let gameClock: String?
    let regulationPeriods: Int?
    let homeTeam: BoxScoreTeam
    let awayTeam: BoxScoreTeam
}

struct BoxScoreTeam: Decodable {
    let teamTricode: String
    let score: String
    let periods: [BoxScorePeriod]?
    let players: [BoxScorePlayer]
    let statistics: BoxScoreTeamStatistics?

    enum CodingKeys: String, CodingKey {
        case teamTricode
        case score
        case periods
        case players
        case statistics
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        teamTricode = try container.decode(String.self, forKey: .teamTricode)
        score = decodeLossyString(container, forKey: .score)
        periods = try container.decodeIfPresent([BoxScorePeriod].self, forKey: .periods)
        players = try container.decodeIfPresent([BoxScorePlayer].self, forKey: .players) ?? []
        statistics = try container.decodeIfPresent(BoxScoreTeamStatistics.self, forKey: .statistics)
    }
}

struct BoxScorePeriod: Decodable {
    let period: Int?
    let score: String?

    enum CodingKeys: String, CodingKey {
        case period
        case score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        period = decodeOptionalLossyInt(container, forKey: .period)
        score = decodeOptionalLossyString(container, forKey: .score)
    }
}

struct BoxScorePlayer: Decodable, Identifiable {
    let personId: Int
    let jerseyNum: String?
    let starter: String?
    let played: String?
    let statistics: BoxScorePlayerStatistics
    let name: String

    var id: Int { personId }

    enum CodingKeys: String, CodingKey {
        case personId
        case jerseyNum
        case starter
        case played
        case statistics
        case name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        personId = decodeLossyInt(container, forKey: .personId)
        jerseyNum = decodeOptionalLossyString(container, forKey: .jerseyNum)
        starter = decodeOptionalLossyString(container, forKey: .starter)
        played = decodeOptionalLossyString(container, forKey: .played)
        statistics = try container.decodeIfPresent(BoxScorePlayerStatistics.self, forKey: .statistics) ?? .empty
        name = try container.decode(String.self, forKey: .name)
    }
}

struct BoxScorePlayerStatistics: Decodable {
    let minutes: String?
    let points: String?
    let reboundsTotal: String?
    let assists: String?
    let steals: String?
    let blocks: String?
    let fieldGoalsMade: String?
    let fieldGoalsAttempted: String?
    let threePointersMade: String?
    let threePointersAttempted: String?
    let freeThrowsMade: String?
    let freeThrowsAttempted: String?
    let plusMinusPoints: String?

    enum CodingKeys: String, CodingKey {
        case minutes
        case points
        case reboundsTotal
        case assists
        case steals
        case blocks
        case fieldGoalsMade
        case fieldGoalsAttempted
        case threePointersMade
        case threePointersAttempted
        case freeThrowsMade
        case freeThrowsAttempted
        case plusMinusPoints
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        minutes = decodeOptionalLossyString(container, forKey: .minutes)
        points = decodeOptionalLossyString(container, forKey: .points)
        reboundsTotal = decodeOptionalLossyString(container, forKey: .reboundsTotal)
        assists = decodeOptionalLossyString(container, forKey: .assists)
        steals = decodeOptionalLossyString(container, forKey: .steals)
        blocks = decodeOptionalLossyString(container, forKey: .blocks)
        fieldGoalsMade = decodeOptionalLossyString(container, forKey: .fieldGoalsMade)
        fieldGoalsAttempted = decodeOptionalLossyString(container, forKey: .fieldGoalsAttempted)
        threePointersMade = decodeOptionalLossyString(container, forKey: .threePointersMade)
        threePointersAttempted = decodeOptionalLossyString(container, forKey: .threePointersAttempted)
        freeThrowsMade = decodeOptionalLossyString(container, forKey: .freeThrowsMade)
        freeThrowsAttempted = decodeOptionalLossyString(container, forKey: .freeThrowsAttempted)
        plusMinusPoints = decodeOptionalLossyString(container, forKey: .plusMinusPoints)
    }

    init(
        minutes: String?,
        points: String?,
        reboundsTotal: String?,
        assists: String?,
        steals: String?,
        blocks: String?,
        fieldGoalsMade: String?,
        fieldGoalsAttempted: String?,
        threePointersMade: String?,
        threePointersAttempted: String?,
        freeThrowsMade: String?,
        freeThrowsAttempted: String?,
        plusMinusPoints: String?
    ) {
        self.minutes = minutes
        self.points = points
        self.reboundsTotal = reboundsTotal
        self.assists = assists
        self.steals = steals
        self.blocks = blocks
        self.fieldGoalsMade = fieldGoalsMade
        self.fieldGoalsAttempted = fieldGoalsAttempted
        self.threePointersMade = threePointersMade
        self.threePointersAttempted = threePointersAttempted
        self.freeThrowsMade = freeThrowsMade
        self.freeThrowsAttempted = freeThrowsAttempted
        self.plusMinusPoints = plusMinusPoints
    }
}

struct BoxScoreTeamStatistics: Decodable {
    let points: String?
    let reboundsTotal: String?
    let assists: String?

    enum CodingKeys: String, CodingKey {
        case points
        case reboundsTotal
        case assists
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        points = decodeOptionalLossyString(container, forKey: .points)
        reboundsTotal = decodeOptionalLossyString(container, forKey: .reboundsTotal)
        assists = decodeOptionalLossyString(container, forKey: .assists)
    }
}

struct PlayByPlayEnvelope: Decodable {
    let game: PlayByPlayGame
}

struct PlayByPlayGame: Decodable {
    let gameId: String
    let actions: [PlayAction]
}

struct PlayAction: Decodable, Identifiable {
    let actionNumber: Int
    let clock: String?
    let period: Int
    let scoreHome: String?
    let scoreAway: String?
    let description: String?

    var id: Int { actionNumber }

    enum CodingKeys: String, CodingKey {
        case actionNumber
        case clock
        case period
        case scoreHome
        case scoreAway
        case description
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        actionNumber = decodeLossyInt(container, forKey: .actionNumber)
        clock = decodeOptionalLossyString(container, forKey: .clock)
        period = decodeLossyInt(container, forKey: .period)
        scoreHome = decodeOptionalLossyString(container, forKey: .scoreHome)
        scoreAway = decodeOptionalLossyString(container, forKey: .scoreAway)
        description = decodeOptionalLossyString(container, forKey: .description)
    }
}

struct TrendPoint: Identifiable {
    let id = UUID()
    let elapsedMinutes: Double
    let differential: Int
}

extension BoxScorePlayerStatistics {
    static let empty = BoxScorePlayerStatistics(
        minutes: nil,
        points: nil,
        reboundsTotal: nil,
        assists: nil,
        steals: nil,
        blocks: nil,
        fieldGoalsMade: nil,
        fieldGoalsAttempted: nil,
        threePointersMade: nil,
        threePointersAttempted: nil,
        freeThrowsMade: nil,
        freeThrowsAttempted: nil,
        plusMinusPoints: nil
    )
}

private func decodeLossyInt<K: CodingKey>(
    _ container: KeyedDecodingContainer<K>,
    forKey key: K
) -> Int {
    if let value = try? container.decode(Int.self, forKey: key) {
        return value
    }

    if let value = try? container.decode(String.self, forKey: key), let intValue = Int(value) {
        return intValue
    }

    if let value = try? container.decode(Double.self, forKey: key) {
        return Int(value)
    }

    return 0
}

private func decodeOptionalLossyInt<K: CodingKey>(
    _ container: KeyedDecodingContainer<K>,
    forKey key: K
) -> Int? {
    if (try? container.decodeNil(forKey: key)) == true {
        return nil
    }

    let value = decodeLossyInt(container, forKey: key)
    return value == 0 ? nil : value
}
