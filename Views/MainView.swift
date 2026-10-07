import SwiftUI

struct MainView: View {
    @EnvironmentObject private var appManager: FlakeAppManager

    @State private var selectedServer: ServerDescription?
    @State private var showingServer = false
    @State private var showingWelcome = false
    @State private var showingSettings = false
    @State private var searchText = ""

    private var filteredServers: [ServerDescription] {
        guard !searchText.isEmpty else { return appManager.servers }
        return appManager.servers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.host.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section("Servers") {
                ForEach(filteredServers) { server in
                    let client = appManager.getClient(for: server)

                    NavigationLink {
                        ServerDetailView(client: client)
                    } label: {
                        ServerRowView(client: client)
                    }
                    .contextMenu {
                        if client.connectionState.canConnect {
                            Button {
                                client.connect()
                            } label: {
                                Label("Connect", systemImage: "link")
                            }
                        } else {
                            Button {
                                client.disconnect()
                            } label: {
                                Label("Disconnect", systemImage: "link.slash")
                            }
                        }

                        Button {
                            selectedServer = server
                        } label: {
                            Label("Edit Broker", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            appManager.removeServer(server)
                        } label: {
                            Label("Delete Broker", systemImage: "trash")
                        }
                    }
                }
                .onDelete { offsets in
                    let ids = Set(offsets.compactMap { index in
                        filteredServers.indices.contains(index)
                            ? filteredServers[index].id
                            : nil
                    })
                    appManager.removeServers(ids: ids)
                }

                if appManager.servers.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("No brokers yet")
                            .font(.headline)
                        Text("Add an MQTT broker to start subscribing and publishing.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search brokers")
        .navigationTitle(appManager.appName)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingServer = true
                } label: {
                    Label("Add Broker", systemImage: "plus")
                }

                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .sheet(isPresented: $showingWelcome) {
            WelcomeView()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showingServer) {
            ServerFormView { newServer in
                appManager.addServer(newServer)
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedServer) { server in
            ServerFormView(server: server) { updatedServer in
                appManager.updateServer(updatedServer)
            }
        }
        .onAppear {
            if appManager.servers.isEmpty {
                showingWelcome = true
            }
        }
    }
}

struct ServerRowView: View {
    @ObservedObject var client: MQTTClient

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 3) {
                Text(client.server.displayName)
                    .font(.headline)

                Text(client.server.endpointDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if client.messages.count > 0 {
                Text("\(client.messages.count)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: Capsule())
            }
        }
    }

    private var statusColor: Color {
        switch client.connectionState {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .secondary
        case .error:
            return .red
        }
    }
}
