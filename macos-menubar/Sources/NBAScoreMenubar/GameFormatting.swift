import Foundation

struct MenuBarLabelContent {
    let topLine: String
    let bottomLine: String
}

enum GameFormatting {
    private static let scoreboardDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    private static let lastUpdatedFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter
    }()

    static func formattedGameDate(_ rawValue: String) -> String {
        guard let date = scoreboardDateFormatter.date(from: rawValue) else {
            return rawValue
        }

        return dayFormatter.string(from: date)
    }

    static func formattedLastUpdated(_ date: Date?) -> String {
        guard let date else {
            return "Waiting for first refresh"
        }

        return lastUpdatedFormatter.string(from: date)
    }

    static func scoreboardSummary(for scoreboard: Scoreboard) -> String {
        let liveCount = scoreboard.games.filter(\.isLive).count
        let finalCount = scoreboard.games.filter(\.isFinal).count
        let scheduledCount = scoreboard.games.filter(\.isScheduled).count

        if scoreboard.games.isEmpty {
            return "No games scheduled today"
        }

        if liveCount > 0 {
            return "\(liveCount) live | \(scoreboard.games.count) games today"
        }

        if finalCount == scoreboard.games.count {
            return "All \(finalCount) games are final"
        }

        return "\(scheduledCount) upcoming | \(scoreboard.games.count) games today"
    }

    static func menuBarLabel(for scoreboard: Scoreboard?) -> MenuBarLabelContent {
        guard let scoreboard else {
            return MenuBarLabelContent(topLine: "NBA", bottomLine: "...")
        }

        let liveGames = scoreboard.games.filter(\.isLive)
        if liveGames.count == 1, let liveGame = liveGames.first {
            return menuBarLabel(for: liveGame)
        }

        if liveGames.count > 1 {
            return MenuBarLabelContent(topLine: "NBA", bottomLine: "\(liveGames.count) LIVE")
        }

        if let nextGame = scoreboard.games.first(where: \.isScheduled) {
            return menuBarLabel(for: nextGame)
        }

        if scoreboard.games.isEmpty {
            return MenuBarLabelContent(topLine: "NBA", bottomLine: "OFF")
        }

        return MenuBarLabelContent(topLine: "NBA", bottomLine: "FINAL")
    }

    static func menuBarLabel(for scoreboard: Scoreboard?, favorites: [Game], favoriteIndex: Int) -> MenuBarLabelContent {
        guard !favorites.isEmpty else {
            return menuBarLabel(for: scoreboard)
        }

        let index = min(max(favoriteIndex, 0), favorites.count - 1)
        return menuBarLabel(for: favorites[index])
    }

    static func menuBarLabel(for game: Game) -> MenuBarLabelContent {
        MenuBarLabelContent(
            topLine: "\(game.awayTeam.teamTricode):\(game.homeTeam.teamTricode)",
            bottomLine: secondaryMenuBarLine(for: game)
        )
    }

    static func primaryLine(for game: Game) -> String {
        if game.isScheduled {
            return "\(game.awayTeam.teamTricode) @ \(game.homeTeam.teamTricode)"
        }

        return "\(game.awayTeam.teamTricode) \(game.awayTeam.score) - \(game.homeTeam.score) \(game.homeTeam.teamTricode)"
    }

    static func compactMenuBarLine(for game: Game) -> String {
        if game.isScheduled {
            return "\(game.awayTeam.teamTricode) @ \(game.homeTeam.teamTricode)"
        }

        return "\(game.awayTeam.teamTricode) \(game.awayTeam.score)-\(game.homeTeam.score) \(game.homeTeam.teamTricode)"
    }

    static func accessibilityMenuBarTitle(for label: MenuBarLabelContent) -> String {
        "\(label.topLine) \(label.bottomLine)"
    }

    static func shortPlayerDisplayName(_ fullName: String) -> String {
        shortPlayerName(fullName)
    }

    static func minutesDisplay(_ rawValue: String?) -> String {
        guard let rawValue, !rawValue.isEmpty else {
            return "--"
        }

        if rawValue.contains(":") {
            return rawValue
        }

        let parsed = parseGameClock(rawValue)
        return String(format: "%02d:%02d", parsed.minutes, Int(parsed.seconds.rounded(.down)))
    }

    static func plusMinusDisplay(_ rawValue: String?) -> String {
        guard let rawValue, let value = Int(rawValue) else {
            return "0"
        }

        return value > 0 ? "+\(value)" : "\(value)"
    }

    static func playActionSummary(_ action: PlayAction) -> String {
        let clock = action.clock.map { parseGameClock($0) } ?? (minutes: 0, seconds: 0)
        let timeText = clock.minutes == 0 && clock.seconds == 0
            ? periodText(for: action.period)
            : "\(periodText(for: action.period)) \(displayClockText(minutes: clock.minutes, seconds: clock.seconds))"

        if let scoreAway = action.scoreAway, let scoreHome = action.scoreHome {
            return "\(timeText)  \(scoreAway):\(scoreHome)"
        }

        return timeText
    }

    static func trendPoints(boxScore: BoxScoreGame, playByPlay: PlayByPlayGame?) -> [TrendPoint] {
        guard let playByPlay else {
            return [TrendPoint(elapsedMinutes: 0, differential: 0)]
        }

        let maxPeriod = max(
            boxScore.period,
            playByPlay.actions.map(\.period).max() ?? boxScore.regulationPeriods ?? 4
        )

        let totalMinutes = totalGameMinutes(maxPeriod: maxPeriod)
        var points: [TrendPoint] = [TrendPoint(elapsedMinutes: 0, differential: 0)]

        for action in playByPlay.actions {
            guard let scoreHome = Int(action.scoreHome ?? ""),
                  let scoreAway = Int(action.scoreAway ?? "") else {
                continue
            }

            let parsedClock = parseGameClock(action.clock)
            let elapsedMinutes = elapsedMinutesForAction(
                period: action.period,
                minutesLeft: parsedClock.minutes,
                secondsLeft: parsedClock.seconds
            )

            points.append(
                TrendPoint(
                    elapsedMinutes: min(elapsedMinutes, totalMinutes),
                    differential: scoreHome - scoreAway
                )
            )
        }

        return points.isEmpty ? [TrendPoint(elapsedMinutes: 0, differential: 0)] : points
    }

    static func leadChangeCount(playByPlay: PlayByPlayGame?) -> Int {
        guard let actions = playByPlay?.actions else {
            return 0
        }

        var leadChanges = 0
        var lastLead = 0

        for action in actions {
            guard let scoreHome = Int(action.scoreHome ?? ""),
                  let scoreAway = Int(action.scoreAway ?? "") else {
                continue
            }

            let differential = scoreHome - scoreAway
            if (lastLead > 0 && differential < 0) || (lastLead < 0 && differential > 0) {
                leadChanges += 1
            }

            if differential != 0 {
                lastLead = differential
            }
        }

        return leadChanges
    }

    static func statusText(for game: Game) -> String {
        switch game.gameStatus {
        case 1:
            return "Starts \(scheduledTimeText(from: game.gameTimeUTC))"
        case 2:
            return liveStatusText(for: game)
        default:
            return "Final"
        }
    }

    static func statusBadgeText(for game: Game) -> String {
        switch game.gameStatus {
        case 1:
            return "UP NEXT"
        case 2:
            return "LIVE"
        default:
            return "FINAL"
        }
    }

    static func leaderSummary(for game: Game) -> String? {
        guard !game.isScheduled else {
            return nil
        }

        guard let leaders = game.gameLeaders,
              let homeLeader = leaders.homeLeaders,
              let awayLeader = leaders.awayLeaders,
              let homePoints = intValue(homeLeader.points),
              let awayPoints = intValue(awayLeader.points) else {
            return nil
        }

        let leader: GameLeader
        let teamTricode: String

        if homePoints >= awayPoints {
            leader = homeLeader
            teamTricode = game.homeTeam.teamTricode
        } else {
            leader = awayLeader
            teamTricode = game.awayTeam.teamTricode
        }

        var stats = ["\(max(homePoints, awayPoints)) PTS"]
        if let rebounds = intValue(leader.rebounds), rebounds >= 5 {
            stats.append("\(rebounds) REB")
        }
        if let assists = intValue(leader.assists), assists >= 5 {
            stats.append("\(assists) AST")
        }

        let jerseyText = leader.jerseyNum.map { " #\($0)" } ?? ""
        return "Top: \(shortPlayerName(leader.name))\(jerseyText) | \(teamTricode) | \(stats.joined(separator: ", "))"
    }

    private static func scheduledTimeText(from rawValue: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        guard let date = formatter.date(from: rawValue) else {
            return "soon"
        }

        return timeFormatter.string(from: date)
    }

    private static func liveStatusText(for game: Game) -> String {
        let clock = parseGameClock(game.gameClock)

        if clock.minutes == 0 && clock.seconds == 0 {
            if game.period == 2 {
                return "Halftime"
            }

            if game.period <= 4 {
                return "End Q\(game.period)"
            }

            return "End OT\(game.period - 4)"
        }

        return "\(periodText(for: game.period)) \(displayClockText(minutes: clock.minutes, seconds: clock.seconds))"
    }

    private static func secondaryMenuBarLine(for game: Game) -> String {
        if game.isScheduled {
            return scheduledTimeText(from: game.gameTimeUTC).uppercased()
        }

        let scoreText = "\(game.awayTeam.score):\(game.homeTeam.score)"

        if game.isFinal {
            return "\(scoreText) FINAL"
        }

        return "\(scoreText) \(menuBarGameState(for: game))"
    }

    private static func parseGameClock(_ rawValue: String?) -> (minutes: Int, seconds: Double) {
        guard let rawValue else {
            return (0, 0)
        }

        if let match = rawValue.range(of: #"PT(\d+)M([\d.]+)S"#, options: .regularExpression) {
            let fragment = String(rawValue[match])
            let numbers = fragment
                .replacingOccurrences(of: "PT", with: "")
                .replacingOccurrences(of: "M", with: " ")
                .replacingOccurrences(of: "S", with: "")
                .split(separator: " ")

            if numbers.count == 2 {
                let minutes = Int(numbers[0]) ?? 0
                let seconds = Double(numbers[1]) ?? 0
                return (minutes, seconds)
            }
        }

        let components = rawValue
            .replacingOccurrences(of: "[^0-9:]", with: "", options: .regularExpression)
            .split(separator: ":")

        if components.count == 2 {
            return (Int(components[0]) ?? 0, Double(components[1]) ?? 0)
        }

        return (0, 0)
    }

    private static func menuBarGameState(for game: Game) -> String {
        let clock = parseGameClock(game.gameClock)

        if clock.minutes == 0 && clock.seconds == 0 {
            if game.period == 2 {
                return "HALF"
            }

            if game.period <= 4 {
                return "END Q\(game.period)"
            }

            return "END OT\(game.period - 4)"
        }

        return "\(periodText(for: game.period)) \(displayClockText(minutes: clock.minutes, seconds: clock.seconds))"
    }

    private static func periodText(for period: Int) -> String {
        period <= 4 ? "Q\(period)" : "OT\(period - 4)"
    }

    private static func totalGameMinutes(maxPeriod: Int) -> Double {
        if maxPeriod <= 4 {
            return 48
        }

        return 48 + Double(maxPeriod - 4) * 5
    }

    private static func elapsedMinutesForAction(period: Int, minutesLeft: Int, secondsLeft: Double) -> Double {
        let periodDuration = period <= 4 ? 12.0 : 5.0
        let elapsedBeforePeriod = period <= 4 ? Double(period - 1) * 12.0 : 48.0 + Double(period - 5) * 5.0
        let elapsedInPeriod = periodDuration - Double(minutesLeft) - (secondsLeft / 60.0)
        return max(0, elapsedBeforePeriod + elapsedInPeriod)
    }

    private static func displayClockText(minutes: Int, seconds: Double) -> String {
        if minutes < 1 {
            let wholeSeconds = Int(seconds.rounded(.down))
            let centiseconds = Int(((seconds - floor(seconds)) * 100).rounded())
            return String(format: "%02d.%02d", wholeSeconds, min(centiseconds, 99))
        }

        return String(format: "%02d:%02d", minutes, Int(seconds.rounded(.down)))
    }

    private static func shortPlayerName(_ fullName: String) -> String {
        let parts = fullName
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)

        guard let first = parts.first else {
            return fullName
        }

        if parts.count == 1 {
            return first
        }

        return "\(first.prefix(1)). \(parts.dropFirst().joined(separator: " "))"
    }

    private static func intValue(_ rawValue: String?) -> Int? {
        guard let rawValue else {
            return nil
        }

        return Int(rawValue)
    }
}
