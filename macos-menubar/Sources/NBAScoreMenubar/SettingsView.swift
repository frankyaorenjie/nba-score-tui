import SwiftUI

struct SettingsView: View {
    @ObservedObject var preferences: AppPreferences

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                Text("Settings")
                    .font(.title2.weight(.semibold))

                VStack(alignment: .leading, spacing: 14) {
                    Toggle(
                        "Start at login",
                        isOn: Binding(
                            get: { preferences.startAtLogin },
                            set: { preferences.setStartAtLogin($0) }
                        )
                    )

                    Toggle(
                        "Start and hide",
                        isOn: Binding(
                            get: { preferences.startAndHide },
                            set: { preferences.setStartAndHide($0) }
                        )
                    )
                }

                Text("Start and hide keeps the app in the menu bar without opening the scoreboard popover on launch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Start at login applies on your next macOS login.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let loginItemMessage = preferences.loginItemMessage {
                    Text(loginItemMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}
