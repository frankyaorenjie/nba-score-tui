import Charts
import SwiftUI

struct GameDetailView: View {
    @ObservedObject var store: GameDetailStore

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header

                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                if store.isLoading && store.boxScore == nil {
                    ProgressView("Loading game detail...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else if let boxScore = store.boxScore {
                    HSplitView {
                        TrendPanelView(boxScore: boxScore, playByPlay: store.playByPlay)
                            .frame(minWidth: 360)

                        BoxScorePanelView(boxScore: boxScore)
                            .frame(minWidth: 700)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Select a game to load details.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(store.titleText)
                .font(.title2.weight(.semibold))
                .monospacedDigit()

            if let game = store.selectedGame {
                HStack(spacing: 12) {
                    Text(GameFormatting.statusText(for: game))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let leaderSummary = GameFormatting.leaderSummary(for: game) {
                        Text(leaderSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

private struct TrendPanelView: View {
    let boxScore: BoxScoreGame
    let playByPlay: PlayByPlayGame?

    private var trendPoints: [TrendPoint] {
        GameFormatting.trendPoints(boxScore: boxScore, playByPlay: playByPlay)
    }

    private var recentPlays: [PlayAction] {
        Array((playByPlay?.actions ?? []).suffix(5).reversed())
    }

    private var currentDifferential: Int {
        (Int(boxScore.homeTeam.score) ?? 0) - (Int(boxScore.awayTeam.score) ?? 0)
    }

    var body: some View {
        DetailPanel(title: "Game Flow") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    TrendStatPill(
                        label: "Lead Changes",
                        value: "\(GameFormatting.leadChangeCount(playByPlay: playByPlay))"
                    )

                    TrendStatPill(
                        label: "Current Margin",
                        value: marginText
                    )

                    TrendStatPill(
                        label: "Recent Plays",
                        value: "\(recentPlays.count)"
                    )
                }

                Chart {
                    RuleMark(y: .value("Tie", 0))
                        .foregroundStyle(.secondary.opacity(0.35))

                    ForEach(trendPoints) { point in
                        AreaMark(
                            x: .value("Minute", point.elapsedMinutes),
                            y: .value("Differential", point.differential)
                        )
                        .interpolationMethod(.stepEnd)
                        .foregroundStyle(.blue.opacity(0.12))

                        LineMark(
                            x: .value("Minute", point.elapsedMinutes),
                            y: .value("Differential", point.differential)
                        )
                        .interpolationMethod(.stepEnd)
                        .foregroundStyle(.blue)
                    }
                }
                .frame(height: 280)

                Text("Recent Plays")
                    .font(.headline)

                if recentPlays.isEmpty {
                    Text("Play-by-play has not populated yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(recentPlays) { action in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(GameFormatting.playActionSummary(action))
                                        .font(.system(.body, design: .rounded))
                                        .monospacedDigit()

                                    if let description = action.description {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
        }
    }

    private var marginText: String {
        if currentDifferential == 0 {
            return "Tie"
        }

        let team = currentDifferential > 0 ? boxScore.homeTeam.teamTricode : boxScore.awayTeam.teamTricode
        return "\(team) \(abs(currentDifferential))"
    }
}

private struct BoxScorePanelView: View {
    let boxScore: BoxScoreGame

    var body: some View {
        DetailPanel(title: "Box Score") {
            ScrollView([.vertical, .horizontal]) {
                VStack(alignment: .leading, spacing: 18) {
                    TeamBoxScoreSection(team: boxScore.awayTeam)
                    TeamBoxScoreSection(team: boxScore.homeTeam)
                }
                .padding(.bottom, 12)
            }
        }
    }
}

private struct TeamBoxScoreSection: View {
    let team: BoxScoreTeam

    private var activePlayers: [BoxScorePlayer] {
        team.players.filter { ($0.played ?? "").isEmpty == false && $0.played != "0" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(team.teamTricode)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()

                if let totals = team.statistics {
                    Text(teamSummary(totals))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                headerRow

                Divider()

                ForEach(Array(activePlayers.enumerated()), id: \.element.id) { index, player in
                    PlayerStatRow(player: player)

                    if index == 4 && activePlayers.count > 5 {
                        Divider()
                    }
                }
            }
            .frame(minWidth: 762, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            header("PLAYER", width: 170, alignment: .leading)
            header("MIN", width: 52)
            header("PTS", width: 42)
            header("REB", width: 42)
            header("AST", width: 42)
            header("STL", width: 42)
            header("BLK", width: 42)
            header("FG", width: 76)
            header("3PT", width: 76)
            header("FT", width: 68)
            header("+/-", width: 52)
        }
    }

    private func header(_ text: String, width: CGFloat, alignment: Alignment = .trailing) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: alignment)
    }

    private func teamSummary(_ totals: BoxScoreTeamStatistics) -> String {
        let points = totals.points ?? "0"
        let rebounds = totals.reboundsTotal ?? "0"
        let assists = totals.assists ?? "0"
        return "PTS \(points)  REB \(rebounds)  AST \(assists)"
    }
}

private struct PlayerStatRow: View {
    let player: BoxScorePlayer

    var body: some View {
        let stats = player.statistics

        HStack(spacing: 0) {
            value(GameFormatting.shortPlayerDisplayName(player.name), width: 170, alignment: .leading)
            value(GameFormatting.minutesDisplay(stats.minutes), width: 52)
            value(stats.points ?? "0", width: 42)
            value(stats.reboundsTotal ?? "0", width: 42)
            value(stats.assists ?? "0", width: 42)
            value(stats.steals ?? "0", width: 42)
            value(stats.blocks ?? "0", width: 42)
            value(shootingText(made: stats.fieldGoalsMade, attempted: stats.fieldGoalsAttempted), width: 76)
            value(shootingText(made: stats.threePointersMade, attempted: stats.threePointersAttempted), width: 76)
            value(shootingText(made: stats.freeThrowsMade, attempted: stats.freeThrowsAttempted), width: 68)
            value(GameFormatting.plusMinusDisplay(stats.plusMinusPoints), width: 52)
        }
    }

    private func value(_ text: String, width: CGFloat, alignment: Alignment = .trailing) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .regular, design: .rounded))
            .monospacedDigit()
            .frame(width: width, alignment: alignment)
    }

    private func shootingText(made: String?, attempted: String?) -> String {
        "\(made ?? "0")-\(attempted ?? "0")"
    }
}

private struct DetailPanel<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)

            content
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

private struct TrendStatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
    }
}
