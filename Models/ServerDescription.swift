import Foundation

enum MQTTProtocolVersion: Int, Codable, CaseIterable, Identifiable {
    case mqtt3 = 3
    case mqtt5 = 5

    var id: Int { rawValue }

    var description: String {
        switch self {
        case .mqtt3: return "MQTT 3.1.1"
        case .mqtt5: return "MQTT 5.0"
        }
    }
}

struct ServerDescription: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String = ""
    var host: String = ""
    var port: String = ""
    var clientId: String = ""
    var useTLS: Bool = false
    var username: String = ""
    var password: String = ""
    var protocolVersion: MQTTProtocolVersion = .mqtt3
    var subscriptions: [Subscription] = []
    var useWebSocket: Bool = false
    var webSocketPath: String = "/mqtt"

    static var empty: ServerDescription {
        let alphabet = "1234567890abcdefghijklmnopqrstuvwxyz"
        let suffix = String((0..<8).compactMap { _ in alphabet.randomElement() })
        return ServerDescription(clientId: "mqtt-\(suffix)")
    }

    var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? host
            : name
    }

    var defaultPort: UInt16 {
        if useWebSocket {
            return useTLS ? 443 : 80
        }
        return useTLS ? 8883 : 1883
    }

    var portNumber: UInt16? {
        let value = port.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.isEmpty {
            return defaultPort
        }
        guard let number = UInt16(value), number > 0 else {
            return nil
        }
        return number
    }

    var normalizedWebSocketPath: String {
        let value = webSocketPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "/mqtt" }
        return value.hasPrefix("/") ? value : "/\(value)"
    }

    var isValid: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        portNumber != nil &&
        (!useWebSocket || !normalizedWebSocketPath.isEmpty)
    }

    var endpointDescription: String {
        let scheme: String
        if useWebSocket {
            scheme = useTLS ? "wss" : "ws"
        } else {
            scheme = useTLS ? "mqtts" : "mqtt"
        }
        return "\(scheme)://\(host):\(portNumber ?? defaultPort)"
    }

    func requiresReconnect(comparedTo other: ServerDescription) -> Bool {
        host != other.host ||
        portNumber != other.portNumber ||
        clientId != other.clientId ||
        useTLS != other.useTLS ||
        username != other.username ||
        password != other.password ||
        protocolVersion != other.protocolVersion ||
        useWebSocket != other.useWebSocket ||
        normalizedWebSocketPath != other.normalizedWebSocketPath
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case host
        case port
        case clientId
        case useTLS
        case username
        case password
        case protocolVersion
        case subscriptions
        case useWebSocket
        case webSocketPath
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        host: String = "",
        port: String = "",
        clientId: String = "",
        useTLS: Bool = false,
        username: String = "",
        password: String = "",
        protocolVersion: MQTTProtocolVersion = .mqtt3,
        subscriptions: [Subscription] = [],
        useWebSocket: Bool = false,
        webSocketPath: String = "/mqtt"
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.clientId = clientId
        self.useTLS = useTLS
        self.username = username
        self.password = password
        self.protocolVersion = protocolVersion
        self.subscriptions = subscriptions
        self.useWebSocket = useWebSocket
        self.webSocketPath = webSocketPath
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        host = try container.decodeIfPresent(String.self, forKey: .host) ?? ""
        port = try container.decodeIfPresent(String.self, forKey: .port) ?? "1883"
        clientId = try container.decodeIfPresent(String.self, forKey: .clientId) ?? ""
        useTLS = try container.decodeIfPresent(Bool.self, forKey: .useTLS) ?? false
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
        protocolVersion = try container.decodeIfPresent(MQTTProtocolVersion.self, forKey: .protocolVersion) ?? .mqtt3
        subscriptions = try container.decodeIfPresent([Subscription].self, forKey: .subscriptions) ?? []
        useWebSocket = try container.decodeIfPresent(Bool.self, forKey: .useWebSocket) ?? false
        webSocketPath = try container.decodeIfPresent(String.self, forKey: .webSocketPath) ?? "/mqtt"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(host, forKey: .host)
        try container.encode(port, forKey: .port)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(useTLS, forKey: .useTLS)
        try container.encode(username, forKey: .username)
        try container.encode(protocolVersion, forKey: .protocolVersion)
        try container.encode(subscriptions, forKey: .subscriptions)
        try container.encode(useWebSocket, forKey: .useWebSocket)
        try container.encode(webSocketPath, forKey: .webSocketPath)
        // Passwords are intentionally excluded. FlakeAppManager persists them in Keychain.
    }
}
