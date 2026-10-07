import SwiftUI

struct MessagesView: View {
    let subscription: Subscription
    @ObservedObject var client: MQTTClient

    @State private var draft = PublishDraft.empty
    @State private var showPublishSheet = false
    @State private var isScrolledToBottom = true

    private var topicMessages: [Message] {
        client.messages.filter {
            TopicFilter.matches(subscription.name, topic: $0.topic)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ZStack(alignment: .bottomTrailing) {
                    List {
                        if topicMessages.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "tray")
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text("Waiting for messages")
                                    .font(.headline)
                                Text(subscription.name)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .listRowSeparator(.hidden)
                        }

                        ForEach(topicMessages) { message in
                            MessageView(message: message)
                                .listRowInsets(
                                    EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
                                )
                                .listRowBackground(Color.clear)
                                .id(message.id)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .onChange(of: client.messages) { _ in
                        guard isScrolledToBottom,
                              let lastId = topicMessages.last?.id else {
                            return
                        }
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                    .simultaneousGesture(
                        DragGesture().onChanged { _ in
                            isScrolledToBottom = false
                        }
                    )

                    if !isScrolledToBottom && !topicMessages.isEmpty {
                        Button {
                            guard let lastId = topicMessages.last?.id else { return }
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                                isScrolledToBottom = true
                            }
                        } label: {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title2)
                                .padding(4)
                        }
                        .background(.regularMaterial, in: Circle())
                        .padding(16)
                    }
                }
            }

            composer
        }
        .navigationTitle(subscription.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if TopicFilter.isValidTopicName(subscription.name) {
                draft.topic = subscription.name
            }
        }
        .sheet(isPresented: $showPublishSheet) {
            PublishView(draft: draft) { message in
                let sent = client.publish(message)
                if sent {
                    draft = message
                    draft.payload = ""
                    isScrolledToBottom = true
                }
                return sent
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var composer: some View {
        VStack(spacing: 0) {
            Divider()

            if !TopicFilter.isValidTopicName(draft.topic) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("This is a wildcard subscription. Choose a concrete publish topic.")
                    Spacer()
                    Button("Open") {
                        showPublishSheet = true
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)
            }

            HStack(spacing: 10) {
                Menu {
                    Picker("QoS", selection: $draft.qos) {
                        Text("QoS 0").tag(0)
                        Text("QoS 1").tag(1)
                        Text("QoS 2").tag(2)
                    }
                    Toggle("Retain", isOn: $draft.retain)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .frame(width: 28, height: 28)
                }

                TextField("Message", text: $draft.payload)
                    .textInputAutocapitalization(.never)
                    .submitLabel(.send)
                    .onSubmit(sendQuickMessage)

                Button {
                    showPublishSheet = true
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }

                Button(action: sendQuickMessage) {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(!canSend)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.bar)
        }
    }

    private var canSend: Bool {
        draft.isValid && client.connectionState.isConnected
    }

    private func sendQuickMessage() {
        guard canSend, client.publish(draft) else { return }
        draft.payload = ""
        isScrolledToBottom = true
    }
}
