import Foundation

@MainActor
final class AppPreferences: ObservableObject {
    private static let startAndHideKey = "startAndHide"

    @Published private(set) var startAtLogin: Bool
    @Published private(set) var startAndHide: Bool
    @Published private(set) var loginItemMessage: String?

    init() {
        startAtLogin = LoginLaunchAgentManager.isEnabled
        startAndHide = UserDefaults.standard.object(forKey: Self.startAndHideKey) as? Bool ?? true
    }

    func setStartAndHide(_ enabled: Bool) {
        startAndHide = enabled
        UserDefaults.standard.set(enabled, forKey: Self.startAndHideKey)
    }

    func setStartAtLogin(_ enabled: Bool) {
        do {
            loginItemMessage = try LoginLaunchAgentManager.setEnabled(
                enabled,
                appBundleURL: Bundle.main.bundleURL
            )
        } catch {
            loginItemMessage = "Unable to update start-at-login. \(error.localizedDescription)"
        }

        startAtLogin = LoginLaunchAgentManager.isEnabled
    }
}
