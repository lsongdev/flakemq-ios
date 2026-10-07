import Combine
import Foundation
import Security
import UserNotifications

final class FlakeAppManager: ObservableObject {
    static let shared = FlakeAppManager()

    @Published private(set) var servers: [ServerDescription] = []
    @Published private(set) var notificationsEnabled: Bool

    private var clients: [UUID: MQTTClient] = [:]
    private let storageKey = "servers"
    private let notificationsKey = "notifications-enabled"
    private let credentials = CredentialStore()

    init() {
        notificationsEnabled = UserDefaults.standard.bool(forKey: notificationsKey)
        loadServers()
    }

    func getClient(for server: ServerDescription) -> MQTTClient {
        if let client = clients[server.id] {
            if client.server != server {
                client.updateServer(server)
            }
            return client
        }

        let client = MQTTClient(server: server)
        clients[server.id] = client
        return client
    }

    func addServer(_ server: ServerDescription) {
        guard server.isValid else { return }
        servers.append(server)
        saveServers()
    }

    func removeServer(_ server: ServerDescription) {
        removeServer(id: server.id)
    }

    func removeServer(id: UUID) {
        clients.removeValue(forKey: id)?.disconnect()
        credentials.removePassword(for: id)
        servers.removeAll { $0.id == id }
        saveServers()
    }

    func removeServers(ids: Set<UUID>) {
        for id in ids {
            clients.removeValue(forKey: id)?.disconnect()
            credentials.removePassword(for: id)
        }
        servers.removeAll { ids.contains($0.id) }
        saveServers()
    }

    func updateServer(_ server: ServerDescription) {
        guard server.isValid,
              let index = servers.firstIndex(where: { $0.id == server.id }) else {
            return
        }

        servers[index] = server
        credentials.setPassword(server.password, for: server.id)
        clients[server.id]?.updateServer(server)
        saveServers()
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        guard enabled else {
            notificationsEnabled = false
            UserDefaults.standard.set(false, forKey: notificationsKey)
            return
        }

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.notificationsEnabled = granted
                UserDefaults.standard.set(granted, forKey: self?.notificationsKey ?? "notifications-enabled")
            }
        }
    }

    func sendNotification(title: String, body: String) {
        guard notificationsEnabled else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        UNUserNotificationCenter.current().add(
            UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
        )
    }

    func addDemoServers() {
        guard servers.isEmpty else { return }
        let topic = Subscription(name: "test/#")
        addServer(
            ServerDescription(
                name: "EMQX Public Broker",
                host: "broker.emqx.io",
                subscriptions: [topic]
            )
        )
        addServer(
            ServerDescription(
                name: "HiveMQ Public Broker",
                host: "broker.hivemq.com",
                subscriptions: [topic]
            )
        )
    }

    func loadServers() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              var decoded = try? JSONDecoder().decode([ServerDescription].self, from: data) else {
            return
        }

        var migratedLegacyPassword = false

        for index in decoded.indices {
            let id = decoded[index].id

            if !decoded[index].password.isEmpty {
                credentials.setPassword(decoded[index].password, for: id)
                migratedLegacyPassword = true
            } else if let password = credentials.password(for: id) {
                decoded[index].password = password
            }
        }

        servers = decoded

        if migratedLegacyPassword {
            saveServers()
        }
    }

    func saveServers() {
        for server in servers {
            credentials.setPassword(server.password, for: server.id)
        }

        guard let data = try? JSONEncoder().encode(servers) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }

    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "FlakeMQ"
    }
}

private struct CredentialStore {
    private let service = Bundle.main.bundleIdentifier ?? "org.lsong.mqtt"

    func password(for id: UUID) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func setPassword(_ password: String, for id: UUID) {
        removePassword(for: id)
        guard !password.isEmpty, let data = password.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecValueData as String: data
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    func removePassword(for id: UUID) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: id.uuidString
        ]
        SecItemDelete(query as CFDictionary)
    }
}
