import AppKit
import Darwin
import Foundation

@MainActor
enum LegacyProcessManager {
    static func terminateOlderInstances() {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let bundleIdentifier = Bundle.main.bundleIdentifier
        let executableName = Bundle.main.executableURL?.lastPathComponent ?? ProcessInfo.processInfo.processName

        var candidatesByPID: [pid_t: NSRunningApplication] = [:]

        if let bundleIdentifier {
            for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier) {
                candidatesByPID[app.processIdentifier] = app
            }
        }

        for app in NSWorkspace.shared.runningApplications {
            guard let appExecutableName = app.executableURL?.lastPathComponent else {
                continue
            }

            if appExecutableName == executableName {
                candidatesByPID[app.processIdentifier] = app
            }
        }

        for (pid, app) in candidatesByPID where pid != currentPID {
            if app.isTerminated {
                continue
            }

            if app.terminate() {
                continue
            }

            kill(pid, SIGKILL)
        }
    }
}
