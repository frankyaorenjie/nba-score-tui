import Foundation

@MainActor
final class GameDetailStore: ObservableObject {
    @Published private(set) var selectedGame: Game?
    @Published private(set) var boxScore: BoxScoreGame?
    @Published private(set) var playByPlay: PlayByPlayGame?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var refreshTask: Task<Void, Never>?

    var titleText: String {
        guard let selectedGame else {
            return "NBA Game Detail"
        }

        return GameFormatting.primaryLine(for: selectedGame)
    }

    func show(game: Game) {
        selectedGame = game
        boxScore = nil
        playByPlay = nil
        errorMessage = nil
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await refresh()

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                await refresh()
            }
        }
    }

    func stopRefreshing() {
        refreshTask?.cancel()
        refreshTask = nil
    }

    func refresh() async {
        guard let selectedGame, !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            boxScore = try await GameDetailService.fetchBoxScore(gameID: selectedGame.gameId)
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load box score."
        }

        do {
            playByPlay = try await GameDetailService.fetchPlayByPlay(gameID: selectedGame.gameId)
        } catch {
            playByPlay = nil
            if boxScore != nil {
                errorMessage = "Box score loaded. Play-by-play is unavailable right now."
            } else {
                errorMessage = "Unable to load game detail."
            }
        }
    }

    deinit {
        refreshTask?.cancel()
    }
}
