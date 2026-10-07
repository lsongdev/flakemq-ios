import SwiftUI

struct ServerFormView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var formData: ServerDescription
    private let isNew: Bool
    private let onSave: (ServerDescription) -> Void

    init(
        server: ServerDescription = .empty,
        onSave: @escaping (ServerDescription) -> Void
    ) {
        _formData = State(initialValue: server)
        isNew = server.host.isEmpty
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Broker") {
                    TextField("Name (optional)", text: $formData.name)
                        .textInputAutocapitalization(.never)

                    TextField("Hostname or IP", text: $formData.host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack {
                        TextField("Port", text: $formData.port)
                            .keyboardType(.numberPad)

                        if formData.portNumber == nil {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }

                    Picker("Protocol", selection: $formData.protocolVersion) {
                        ForEach(MQTTProtocolVersion.allCases) { version in
                            Text(version.description).tag(version)
                        }
                    }
                }

                Section {
                    Toggle("TLS", isOn: $formData.useTLS)
                    Toggle("WebSocket", isOn: $formData.useWebSocket)

                    if formData.useWebSocket {
                        TextField("WebSocket path", text: $formData.webSocketPath)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    LabeledContent("Endpoint", value: formData.endpointDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Transport")
                } footer: {
                    Text("Leave the port empty to use the transport default (1883, 8883, 80, or 443).")
                }

                Section {
                    TextField("Username", text: $formData.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField("Password", text: $formData.password)
                        .textContentType(.password)
                } header: {
                    Text("Authentication")
                } footer: {
                    Text("The password is stored in the iOS Keychain, not UserDefaults.")
                }

                Section {
                    TextField("Client ID", text: $formData.clientId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    Text("A generated client ID is used by default. Change it only when your broker requires a stable identity.")
                }
            }
            .navigationTitle(isNew ? "Add Broker" : "Edit Broker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(formData)
                        dismiss()
                    }
                    .disabled(!formData.isValid)
                }
            }
        }
    }
}
