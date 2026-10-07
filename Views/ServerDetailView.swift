import SwiftUI

struct ServerDetailView: View {
    @EnvironmentObject private var appManager: FlakeAppManager
    @ObservedObject var client: MQTTClient

    @State private var showSubscribe = false

    var body: some View {
        List {
            Section {
                HStack {
                    StatusView(connectionState: client.connectionState)
                    Spacer()

                    if client.connectionState.canConnect {
                        Button("Connect") {
                            client.connect()
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Disconnect") {
                            client.disconnect()
                        }
                        .buttonStyle(.bordered)
                    }
                }

                LabeledContent("Endpoint", value: client.server.endpointDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LabeledContent("Protocol", value: client.server.protocolVersion.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Connection")
            }

            Section {
                if client.server.subscriptions.isEmpty {
                    Text("No subscriptions")
                        .foregroundStyle(.secondary)
                }

                ForEach(client.server.subscriptions) { subscription in
                    NavigationLink {
                        MessagesView(subscription: subscription, client: client)
                    } label: {
                        SubscriptionView(subscription: subscription)
                    }
                    .contextMenu {
                        Button {
                            client.subscribe(to: subscription.name, qos: subscription.qos)
                        } label: {
                            Label("Subscribe Now", systemImage: "dot.radiowaves.left.and.right")
                        }

                        Button {
                            client.unsubscribe(from: subscription.name)
                        } label: {
                            Label("Unsubscribe Now", systemImage: "xmark.circle")
                        }

                        Button(role: .destructive) {
                            client.clearMessages(matching: subscription.name)
                        } label: {
                            Label("Clear Messages", systemImage: "trash")
                        }
                    }
                }
                .onDelete(perform: deleteSubscriptions)
            } header: {
                HStack {
                    Text("Subscriptions")
                    Spacer()
                    Button {
                        showSubscribe = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
            } footer: {
                Text("Saved subscriptions are restored automatically after reconnecting.")
            }
        }
        .navigationTitle(client.server.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSubscribe) {
            NavigationStack {
                SubscribeView { topic, qos in
                    upsertSubscription(topic: topic, qos: qos)
                }
            }
        }
    }

    private func upsertSubscription(topic: String, qos: Int) {
        var updated = client.server
        let subscription = Subscription(name: topic, qos: qos)

        if let index = updated.subscriptions.firstIndex(where: { $0.name == topic }) {
            let old = updated.subscriptions[index]
            updated.subscriptions[index] = Subscription(id: old.id, name: topic, qos: qos)
        } else {
            updated.subscriptions.append(subscription)
        }

        appManager.updateServer(updated)
        client.subscribe(to: topic, qos: qos)
    }

    private func deleteSubscriptions(at offsets: IndexSet) {
        let subscriptions = client.server.subscriptions
        let removed = offsets.compactMap { subscriptions.indices.contains($0) ? subscriptions[$0] : nil }

        for subscription in removed {
            client.unsubscribe(from: subscription.name)
        }

        var updated = client.server
        updated.subscriptions.remove(atOffsets: offsets)
        appManager.updateServer(updated)
    }
}
