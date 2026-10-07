import SwiftUI

struct AboutView: View {
    @EnvironmentObject private var appManager: FlakeAppManager

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(appManager.appName)
                            .font(.headline)
                        Text("Version \(appManager.appVersion)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Project") {
                Link(
                    "GitHub",
                    destination: URL(string: "https://github.com/lsongdev/flakemq-ios")!
                )
            }

            Section("Acknowledgements") {
                Link(
                    "CocoaMQTT · MPL-2.0",
                    destination: URL(string: "https://github.com/emqx/CocoaMQTT")!
                )
            }
        }
        .navigationTitle("About")
    }
}
