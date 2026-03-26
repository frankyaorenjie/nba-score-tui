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
    private var activeFavoriteIndex = 0

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

    var favoriteSummaryText: String {
        let count = favoriteGames.count

        if count == 0 {
            return "Star a game to pin it to the menu bar."
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
                advanceFavoriteRotation()
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
            syncFavoriteSelection()
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
            syncFavoriteSelection()
            updateMenuBarLabel()
            return
        }

        favoriteGameIDs.insert(gameID)
        persistFavorites()
        syncFavoriteSelection(preferredGameID: gameID)
        updateMenuBarLabel()
    }

    func advanceFavoriteRotation() {
        let favorites = favoriteGames
        guard favorites.count > 1 else {
            return
        }

        activeFavoriteIndex = (activeFavoriteIndex + 1) % favorites.count
        updateMenuBarLabel()
    }

    private func syncFavoriteSelection(preferredGameID: String? = nil) {
        let favorites = favoriteGames

        guard !favorites.isEmpty else {
            activeFavoriteIndex = 0
            return
        }

        if let preferredGameID,
           let preferredIndex = favorites.firstIndex(where: { $0.id == preferredGameID }) {
            activeFavoriteIndex = preferredIndex
            return
        }

        if activeFavoriteIndex >= favorites.count {
            activeFavoriteIndex = 0
        }
    }

    private func updateMenuBarLabel() {
        menuBarLabel = GameFormatting.menuBarLabel(
            for: scoreboard,
            favorites: favoriteGames,
            favoriteIndex: activeFavoriteIndex
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
