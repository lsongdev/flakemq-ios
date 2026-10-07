# FlakeMQ

FlakeMQ is a small, focused MQTT client for iPhone and iPad.

## Features

- MQTT 3.1.1 and MQTT 5.0
- TCP, TLS, WebSocket and secure WebSocket connections
- Automatic reconnect with saved subscription restoration
- MQTT topic filters with correct `+` and `#` matching
- Publish with QoS 0/1/2 and retained messages
- Message metadata: topic, QoS, retain, duplicate flag and packet identifier
- UTF-8/JSON payload display with a binary hex fallback
- Broker credentials stored in the iOS Keychain
- Optional local notifications for messages received while the app is active in the background

## Design

The app deliberately keeps the architecture small:

- `Models/` contains broker, subscription and message data.
- `Common/MQTTClient.swift` owns one broker session and hides the MQTT 3/5 implementation split.
- `FlakeAppManager.swift` owns saved brokers, session lifetime and credentials.
- `Views/` contains SwiftUI presentation only.

Broker configuration is stored in `UserDefaults`. Passwords are excluded from encoded configuration and stored separately in Keychain. Existing passwords saved by older FlakeMQ versions are migrated to Keychain on first launch.

## Background behavior

iOS can suspend apps in the background, so FlakeMQ does not pretend that a foreground MQTT socket is an always-on push channel. Local notifications are best effort while the process is still receiving MQTT traffic. Products that require reliable background delivery should bridge MQTT messages to APNs on a server.

## Development

The project uses CocoaMQTT through Swift Package Manager.

A lightweight core test checks topic matching, buffer behavior and credential-safe broker encoding:

```sh
swiftc Models/Subscription.swift Models/CircularBuffer.swift Models/ServerDescription.swift Tests/main.swift -o /tmp/flakemq-core-tests
/tmp/flakemq-core-tests
```

The GitHub Actions workflow also builds the iOS target with code signing disabled.
