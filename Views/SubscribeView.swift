import SwiftUI

struct SubscribeView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var topic = ""
    @State private var qos = 0

    let onSubscribe: (String, Int) -> Void

    private var isValid: Bool {
        TopicFilter.isValid(topic)
    }

    var body: some View {
        Form {
            Section {
                TextField("Topic filter", text: $topic)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                Picker("QoS", selection: $qos) {
                    Text("At most once (0)").tag(0)
                    Text("At least once (1)").tag(1)
                    Text("Exactly once (2)").tag(2)
                }
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text("+ matches one topic level.")
                    Text("# matches all remaining levels and must be last.")
                    Text("Examples: sensors/+/temperature, devices/#")
                }
            }

            if !topic.isEmpty && !isValid {
                Label("Invalid MQTT topic filter", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Subscribe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Subscribe") {
                    onSubscribe(topic, qos)
                    dismiss()
                }
                .disabled(!isValid)
            }
        }
    }
}
