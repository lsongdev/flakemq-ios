import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appManager: FlakeAppManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingServer = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "snowflake")
                        .font(.system(size: 56, weight: .light))
                        .foregroundStyle(.tint)

                    Text("Welcome to FlakeMQ")
                        .font(.largeTitle.bold())

                    Text("A focused MQTT client for connecting, subscribing, inspecting, and publishing.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 18) {
                    feature(
                        "MQTT 3.1.1 & 5.0",
                        "TCP, TLS and WebSocket transports",
                        systemImage: "network"
                    )
                    feature(
                        "Topic filters",
                        "Correct + and # wildcard subscriptions",
                        systemImage: "point.3.connected.trianglepath.dotted"
                    )
                    feature(
                        "Message inspector",
                        "QoS, retain, duplicate, JSON and binary payloads",
                        systemImage: "doc.text.magnifyingglass"
                    )
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 10) {
                    if appManager.servers.isEmpty {
                        Button {
                            showingServer = true
                        } label: {
                            Text("Add Broker")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Try Public Brokers") {
                            appManager.addDemoServers()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Text("Continue")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Button("Not Now") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
            .padding()
            .sheet(isPresented: $showingServer) {
                ServerFormView { server in
                    appManager.addServer(server)
                }
            }
        }
    }

    private func feature(_ title: String, _ subtitle: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .frame(width: 28)
                .foregroundStyle(.tint)
        }
    }
}
