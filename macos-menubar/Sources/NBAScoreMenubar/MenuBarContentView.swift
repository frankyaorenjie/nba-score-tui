import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: ScoreboardStore
    let onSelectGame: (Game) -> Void

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 12) {
                header

                if let errorMessage = store.errorMessage, store.scoreboard != nil {
                    inlineMessage(errorMessage, color: .orange)
                }

                content

                footer
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("NBA Scores")
                .font(.title3.weight(.semibold))

            if let scoreboard = store.scoreboard {
                Text(GameFormatting.formattedGameDate(scoreboard.gameDate))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(store.favoriteSummaryText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Fetching the live scoreboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.scoreboard == nil {
            VStack(alignment: .leading, spacing: 10) {
                ProgressView()
                Text("Loading today's games...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if let scoreboard = store.scoreboard {
            if scoreboard.games.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("No games scheduled today.")
                        .font(.body.weight(.medium))
                    Text("The menubar app will keep polling the same NBA live scoreboard feed used by the TUI.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if store.hasFavorites {
                            SectionCard(title: "Pinned In Menu Bar") {
                                ForEach(store.favoriteGames) { game in
                                    CompactGameCard(
                                        game: game,
                                        isFavorite: true,
                                        onToggleFavorite: {
                                            store.toggleFavorite(game.id)
                                        },
                                        onSelectDetail: {
                                            onSelectGame(game)
                                        }
                                    )
                                }
                            }
                        }

                        if !unpinnedGames(from: scoreboard).isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionHeader(title: "All Games")

                                ForEach(unpinnedGames(from: scoreboard)) { game in
                                    CompactGameCard(
                                        game: game,
                                        isFavorite: store.isFavorite(game.id),
                                        onToggleFavorite: {
                                            store.toggleFavorite(game.id)
                                        },
                                        onSelectDetail: {
                                            onSelectGame(game)
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Unable to load the NBA scoreboard.")
                    .font(.body.weight(.medium))
                Text(store.errorMessage ?? "Check your network connection and try again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Refresh Now") {
                    Task {
                        await store.refresh()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            HStack(spacing: 8) {
                Text("Updated \(GameFormatting.formattedLastUpdated(store.lastUpdated))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Refresh") {
                    Task {
                        await store.refresh()
                    }
                }

                Button("NBA.com") {
                    NSWorkspace.shared.open(ScoreboardService.webScoreboardURL)
                }

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private func inlineMessage(_ message: String, color: Color) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(color.opacity(0.09))
            )
    }

    private func unpinnedGames(from scoreboard: Scoreboard) -> [Game] {
        scoreboard.games.filter { !store.isFavorite($0.id) }
    }
}

private struct CompactGameCard: View {
    let game: Game
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onSelectDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 8) {
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(GameFormatting.primaryLine(for: game))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Button("Detail", action: onSelectDetail)
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }

                    HStack(spacing: 8) {
                        Text(GameFormatting.statusText(for: game))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        StatusBadge(text: GameFormatting.statusBadgeText(for: game), color: statusColor)
                    }

                    if let leaderSummary = GameFormatting.leaderSummary(for: game) {
                        Text(leaderSummary)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06))
        )
    }

    private var statusColor: Color {
        if game.isLive {
            return .red
        }

        if game.isScheduled {
            return .blue
        }

        return .green
    }
}

private struct StatusBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.10))
            )
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: title)
            content
        }
        .padding(10)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10))
        )
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}
