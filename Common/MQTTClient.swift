import CocoaMQTT
import CocoaMQTTWebSocket
import Combine
import Foundation
import UIKit

final class MQTTClient: NSObject, ObservableObject {
    private enum Client {
        case mqtt3(CocoaMQTT)
        case mqtt5(CocoaMQTT5)
    }

    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case reconnecting(attempt: UInt, delay: UInt16)
        case connected
        case error(String)

        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }

        var isActive: Bool {
            switch self {
            case .connecting, .reconnecting, .connected:
                return true
            case .disconnected, .error:
                return false
            }
        }

        var canConnect: Bool {
            switch self {
            case .disconnected, .error:
                return true
            case .connecting, .reconnecting, .connected:
                return false
            }
        }
    }

    private var client: Client?

    @Published private(set) var server: ServerDescription
    @Published private(set) var messages = CircularBuffer<Message>(maxSize: 1000)
    @Published private(set) var connectionState: ConnectionState = .disconnected

    init(server: ServerDescription) {
        self.server = server
        super.init()
    }

    func updateServer(_ updatedServer: ServerDescription) {
        let shouldReconnect =
            connectionState.isActive &&
            server.requiresReconnect(comparedTo: updatedServer)

        server = updatedServer

        if shouldReconnect {
            disconnect()
            connect()
        }
    }

    func connect() {
        guard connectionState.canConnect else { return }
        guard server.isValid, let port = server.portNumber else {
            connectionState = .error("Invalid broker configuration")
            return
        }

        tearDownClient()
        connectionState = .connecting

        switch server.protocolVersion {
        case .mqtt3:
            connectMQTT3(port: port)
        case .mqtt5:
            connectMQTT5(port: port)
        }
    }

    private func connectMQTT3(port: UInt16) {
        let socket: CocoaMQTTSocketProtocol = server.useWebSocket
            ? CocoaMQTTWebSocket(uri: server.normalizedWebSocketPath)
            : CocoaMQTTSocket()

        let mqtt = CocoaMQTT(
            clientID: server.clientId,
            host: server.host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: port,
            socket: socket
        )
        configure(mqtt)
        client = .mqtt3(mqtt)

        guard mqtt.connect() else {
            client = nil
            connectionState = .error("Unable to start MQTT 3.1.1 connection")
            return
        }
    }

    private func connectMQTT5(port: UInt16) {
        let socket: CocoaMQTTSocketProtocol = server.useWebSocket
            ? CocoaMQTTWebSocket(uri: server.normalizedWebSocketPath)
            : CocoaMQTTSocket()

        let mqtt = CocoaMQTT5(
            clientID: server.clientId,
            host: server.host.trimmingCharacters(in: .whitespacesAndNewlines),
            port: port,
            socket: socket
        )
        configure(mqtt)
        client = .mqtt5(mqtt)

        guard mqtt.connect() else {
            client = nil
            connectionState = .error("Unable to start MQTT 5.0 connection")
            return
        }
    }

    private func configure(_ mqtt: CocoaMQTT) {
        mqtt.username = server.username.isEmpty ? nil : server.username
        mqtt.password = server.password.isEmpty ? nil : server.password
        mqtt.enableSSL = server.useTLS
        mqtt.autoReconnect = true
        mqtt.autoReconnectTimeInterval = 1
        mqtt.maxAutoReconnectTimeInterval = 30
        mqtt.cleanSession = true
        mqtt.keepAlive = 60
        mqtt.delegateQueue = .main
        mqtt.delegate = self
    }

    private func configure(_ mqtt: CocoaMQTT5) {
        mqtt.username = server.username.isEmpty ? nil : server.username
        mqtt.password = server.password.isEmpty ? nil : server.password
        mqtt.enableSSL = server.useTLS
        mqtt.autoReconnect = true
        mqtt.autoReconnectTimeInterval = 1
        mqtt.maxAutoReconnectTimeInterval = 30
        mqtt.cleanSession = true
        mqtt.keepAlive = 60
        mqtt.delegateQueue = .main
        mqtt.delegate = self
    }

    func disconnect() {
        tearDownClient()
        connectionState = .disconnected
    }

    private func tearDownClient() {
        let current = client
        client = nil

        switch current {
        case .mqtt3(let mqtt):
            mqtt.disconnect()
        case .mqtt5(let mqtt):
            mqtt.disconnect()
        case nil:
            break
        }
    }

    @discardableResult
    func publish(_ message: PublishDraft) -> Bool {
        guard message.isValid, connectionState.isConnected else {
            return false
        }

        let qos = CocoaMQTTQoS(rawValue: UInt8(message.qos)) ?? .qos0

        switch client {
        case .mqtt3(let mqtt):
            return mqtt.publish(
                message.topic,
                withString: message.payload,
                qos: qos,
                retained: message.retain
            ) >= 0

        case .mqtt5(let mqtt):
            return mqtt.publish(
                message.topic,
                withString: message.payload,
                qos: qos,
                DUP: false,
                retained: message.retain,
                properties: MqttPublishProperties()
            ) >= 0

        case nil:
            return false
        }
    }

    func subscribe(to topic: String, qos: Int = 0) {
        guard connectionState.isConnected, TopicFilter.isValid(topic) else {
            return
        }

        let mqttQoS = CocoaMQTTQoS(rawValue: UInt8(qos)) ?? .qos0

        switch client {
        case .mqtt3(let mqtt):
            mqtt.subscribe(topic, qos: mqttQoS)
        case .mqtt5(let mqtt):
            mqtt.subscribe(topic, qos: mqttQoS)
        case nil:
            break
        }
    }

    func unsubscribe(from topic: String) {
        guard connectionState.isConnected else { return }

        switch client {
        case .mqtt3(let mqtt):
            mqtt.unsubscribe(topic)
        case .mqtt5(let mqtt):
            mqtt.unsubscribe(topic)
        case nil:
            break
        }
    }

    func clearMessages(matching topicFilter: String? = nil) {
        guard let topicFilter else {
            messages.clear()
            return
        }
        messages.removeAll { TopicFilter.matches(topicFilter, topic: $0.topic) }
    }

    func restoreSubscriptions() {
        for subscription in server.subscriptions {
            subscribe(to: subscription.name, qos: subscription.qos)
        }
    }

    func addMessage(
        packetId: UInt16,
        topic: String,
        payload: [UInt8],
        qos: Int,
        retain: Bool,
        duplicate: Bool
    ) {
        messages.append(
            Message(
                packetId: packetId == 0 ? nil : packetId,
                topic: topic,
                qos: qos,
                payload: Data(payload),
                retain: retain,
                duplicate: duplicate
            )
        )

        if UIApplication.shared.applicationState == .background {
            let body = String(data: Data(payload), encoding: .utf8)
                ?? "\(payload.count) bytes of binary data"
            FlakeAppManager.shared.sendNotification(title: topic, body: body)
        }
    }

    func isCurrent(_ mqtt: CocoaMQTT) -> Bool {
        guard case .mqtt3(let current) = client else { return false }
        return current === mqtt
    }

    func isCurrent(_ mqtt: CocoaMQTT5) -> Bool {
        guard case .mqtt5(let current) = client else { return false }
        return current === mqtt
    }

    var isInErrorState: Bool {
        if case .error = connectionState { return true }
        return false
    }

    func setConnectionState(_ state: ConnectionState) {
        connectionState = state
    }
}
