import Foundation

enum LoginLaunchAgentManager {
    private static let label = "com.frankyaorenjie.nbascoremenubar.login"

    static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func setEnabled(_ enabled: Bool, appBundleURL: URL) throws -> String? {
        if enabled {
            try installLaunchAgent(appBundleURL: appBundleURL)
            return "Start at login is enabled. It will apply the next time you log in."
        }

        try removeLaunchAgent()
        return "Start at login is disabled."
    }

    private static var launchAgentsDirectoryURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
    }

    private static var plistURL: URL {
        launchAgentsDirectoryURL.appendingPathComponent("\(label).plist")
    }

    private static func installLaunchAgent(appBundleURL: URL) throws {
        guard appBundleURL.pathExtension == "app" else {
            throw NSError(
                domain: "NBAScoreMenubar.LoginLaunchAgent",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "The app must be launched from the .app bundle."]
            )
        }

        try FileManager.default.createDirectory(
            at: launchAgentsDirectoryURL,
            withIntermediateDirectories: true
        )

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [
                "/usr/bin/open",
                appBundleURL.path
            ],
            "LimitLoadToSessionType": ["Aqua"],
            "RunAtLoad": true
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )
        try data.write(to: plistURL, options: .atomic)
    }

    private static func removeLaunchAgent() throws {
        guard FileManager.default.fileExists(atPath: plistURL.path) else {
            return
        }

        try FileManager.default.removeItem(at: plistURL)
    }
}
