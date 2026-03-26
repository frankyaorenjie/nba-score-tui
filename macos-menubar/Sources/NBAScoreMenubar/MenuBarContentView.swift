import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: ScoreboardStore
    let onSelectGame: (Game) -> Void

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header

                if let errorMessage = store.errorMessage, store.scoreboard != nil {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                content

                Divider()

                footer
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NBA Scores")
                .font(.title3.weight(.semibold))

            if let scoreboard = store.scoreboard {
                Text(GameFormatting.formattedGameDate(scoreboard.gameDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(store.favoriteSummaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Fetching the live scoreboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.scoreboard == nil {
            VStack(alignment: .leading, spacing: 12) {
                ProgressView()
                Text("Loading today's games...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if let scoreboard = store.scoreboard {
            if scoreboard.games.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No games scheduled today.")
                        .font(.body.weight(.medium))
                    Text("The menubar app will keep polling the same NBA live scoreboard feed used by the TUI.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    if store.hasFavorites {
                        pinnedGames
                    }

                    Text("All Games")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(scoreboard.games) { game in
                                SimpleGameRow(
                                    game: game,
                                    isFavorite: store.isFavorite(game.id),
                                    onToggleFavorite: {
                                        store.toggleFavorite(game.id)
                                    },
                                    onSelect: {
                                        onSelectGame(game)
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Updated \(GameFormatting.formattedLastUpdated(store.lastUpdated))")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Refresh Now") {
                    Task {
                        await store.refresh()
                    }
                }

                Button("Open NBA.com") {
                    NSWorkspace.shared.open(ScoreboardService.webScoreboardURL)
                }

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }

    private var pinnedGames: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pinned In Menu Bar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ForEach(store.favoriteGames) { game in
                Button(action: { onSelectGame(game) }) {
                    HStack(spacing: 8) {
                        Text(GameFormatting.primaryLine(for: game))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                            .lineLimit(1)

                        Spacer()

                        Text(GameFormatting.statusText(for: game))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

private struct SimpleGameRow: View {
    let game: Game
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? Color.yellow : Color.secondary)
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 2) {
                    Text(GameFormatting.primaryLine(for: game))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .monospacedDigit()

                    Text(GameFormatting.statusText(for: game))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(GameFormatting.statusBadgeText(for: game))
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(statusColor)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onSelect)

            Divider()
                .padding(.top, 10)
        }
        .padding(.vertical, 10)
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
