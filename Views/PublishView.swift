import SwiftUI

struct PublishView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var formData: PublishDraft
    @State private var sendFailed = false

    private let onPublish: (PublishDraft) -> Bool

    init(
        draft: PublishDraft = .empty,
        onPublish: @escaping (PublishDraft) -> Bool
    ) {
        _formData = State(initialValue: draft)
        self.onPublish = onPublish
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Destination") {
                    TextField("Topic", text: $formData.topic)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Picker("QoS", selection: $formData.qos) {
                        Text("At most once (0)").tag(0)
                        Text("At least once (1)").tag(1)
                        Text("Exactly once (2)").tag(2)
                    }

                    Toggle("Retain", isOn: $formData.retain)
                }

                Section {
                    TextEditor(text: $formData.payload)
                        .frame(minHeight: 120)
                        .font(.system(.body, design: .monospaced))
                        .textInputAutocapitalization(.never)

                    LabeledContent(
                        "Size",
                        value: ByteCountFormatter.string(
                            fromByteCount: Int64(formData.payload.utf8.count),
                            countStyle: .file
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } header: {
                    Text("Payload")
                } footer: {
                    Text("An empty MQTT payload is valid. With Retain enabled, it can clear a retained message.")
                }
            }
            .navigationTitle("Publish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        if onPublish(formData) {
                            dismiss()
                        } else {
                            sendFailed = true
                        }
                    }
                    .disabled(!formData.isValid)
                }
            }
            .alert("Message not sent", isPresented: $sendFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Check the broker connection and topic, then try again.")
            }
        }
    }
}
