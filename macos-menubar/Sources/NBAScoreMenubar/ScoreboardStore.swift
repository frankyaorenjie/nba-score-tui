import Combine
import Foundation

@MainActor
final class ScoreboardStore: ObservableObject {
    private static let favoriteGameIDsKey = "favoriteGameIDs"

    @Published private(set) var scoreboard: Scoreboard?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?
    @Published private(set) var menuBarLabel = GameFormatting.menuBarLabel(for: nil)
    @Published private(set) var favoriteGameIDs: Set<String>

    private var refreshTask: Task<Void, Never>?
    private var rotationTask: Task<Void, Never>?
    private var activeMenuBarGameIndex = 0

    init() {
        let savedFavorites = UserDefaults.standard.stringArray(forKey: Self.favoriteGameIDsKey) ?? []
        favoriteGameIDs = Set(savedFavorites)
    }

    var favoriteGames: [Game] {
        guard let scoreboard else {
            return []
        }

        return scoreboard.games.filter { favoriteGameIDs.contains($0.id) }
    }

    var hasFavorites: Bool {
        !favoriteGames.isEmpty
    }

    private var menuBarGames: [Game] {
        if hasFavorites {
            return favoriteGames
        }

        return scoreboard?.games ?? []
    }

    var favoriteSummaryText: String {
        let count = favoriteGames.count

        if count == 0 {
            return "No starred games. All games rotate in the menu bar every 6 seconds."
        }

        if count == 1 {
            return "1 starred game is pinned in the menu bar."
        }

        return "\(count) starred games rotate in the menu bar every 6 seconds."
    }

    func start() {
        guard refreshTask == nil else {
            return
        }

        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }

            await refresh()

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(20))
                await refresh()
            }
        }

        rotationTask = Task { [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(6))
                advanceMenuBarRotation()
            }
        }
    }

    func refresh() async {
        guard !isLoading else {
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            scoreboard = try await ScoreboardService.fetchScoreboard()
            lastUpdated = Date()
            errorMessage = nil
            syncMenuBarSelection()
            updateMenuBarLabel()
        } catch {
            if scoreboard == nil {
                errorMessage = error.localizedDescription
                menuBarLabel = MenuBarLabelContent(topLine: "NBA", bottomLine: "!")
            } else {
                errorMessage = "Refresh failed. Showing the last successful scoreboard snapshot."
                updateMenuBarLabel()
            }
        }
    }

    func isFavorite(_ gameID: String) -> Bool {
        favoriteGameIDs.contains(gameID)
    }

    func toggleFavorite(_ gameID: String) {
        if favoriteGameIDs.contains(gameID) {
            favoriteGameIDs.remove(gameID)
            persistFavorites()
            syncMenuBarSelection(preferredGameID: gameID)
            updateMenuBarLabel()
            return
        }

        favoriteGameIDs.insert(gameID)
        persistFavorites()
        syncMenuBarSelection(preferredGameID: gameID)
        updateMenuBarLabel()
    }

    func advanceMenuBarRotation() {
        let games = menuBarGames
        guard games.count > 1 else {
            return
        }

        activeMenuBarGameIndex = (activeMenuBarGameIndex + 1) % games.count
        updateMenuBarLabel()
    }

    private func syncMenuBarSelection(preferredGameID: String? = nil) {
        let games = menuBarGames

        guard !games.isEmpty else {
            activeMenuBarGameIndex = 0
            return
        }

        if let preferredGameID,
           let preferredIndex = games.firstIndex(where: { $0.id == preferredGameID }) {
            activeMenuBarGameIndex = preferredIndex
            return
        }

        if activeMenuBarGameIndex >= games.count {
            activeMenuBarGameIndex = 0
        }
    }

    private func updateMenuBarLabel() {
        menuBarLabel = GameFormatting.menuBarLabel(
            for: scoreboard,
            games: menuBarGames,
            gameIndex: activeMenuBarGameIndex
        )
    }

    private func persistFavorites() {
        UserDefaults.standard.set(Array(favoriteGameIDs).sorted(), forKey: Self.favoriteGameIDsKey)
    }

    deinit {
        refreshTask?.cancel()
        rotationTask?.cancel()
    }
}
