import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appManager: FlakeAppManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(
                        "Message Notifications",
                        isOn: Binding(
                            get: { appManager.notificationsEnabled },
                            set: { appManager.setNotificationsEnabled($0) }
                        )
                    )
                } header: {
                    Text("Notifications")
                } footer: {
                    Text("FlakeMQ can show a local notification for messages received while the app is in the background. iOS may suspend MQTT network connections, so this is not a substitute for server-side push notifications.")
                }

                Section {
                    NavigationLink("About") {
                        AboutView()
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
