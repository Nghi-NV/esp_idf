/// Transport type for device communication
enum ESPTransportType {
  /// Bluetooth Low Energy
  ble,

  /// Soft Access Point (Wi-Fi)
  softAp,
}

/// Security type for provisioning
enum ESPSecurityType {
  /// No security (not recommended for production)
  unsecured,

  /// Security version 1 with Proof of Possession
  secure,

  /// Security version 2 with username and Proof of Possession
  secure2,
}

/// Status of the provisioning process
enum ESPProvisionStatus {
  /// Provisioning successful
  success,

  /// Provisioning failed
  failed,

  /// Configuration applied successfully
  configApplied,

  /// Credentials received
  credentialsReceived,
}

/// Represents an ESP device discovered during scanning
class ESPDevice {
  /// Device name
  final String name;

  /// Transport type (BLE or SoftAP)
  final ESPTransportType transport;

  /// Security type
  final ESPSecurityType security;

  /// Device identifier (MAC address for BLE, IP for SoftAP)
  final String? deviceId;

  /// Primary service UUID (for BLE devices)
  final String? primaryServiceUuid;

  /// Proof of possession (optional)
  final String? proofOfPossession;

  /// Username (required for Security 2)
  final String? username;

  /// Device capabilities
  final List<String>? capabilities;

  /// Version information
  final String? versionInfo;

  ESPDevice({
    required this.name,
    required this.transport,
    required this.security,
    this.deviceId,
    this.primaryServiceUuid,
    this.proofOfPossession,
    this.username,
    this.capabilities,
    this.versionInfo,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'transport': transport.name,
      'security': security.name,
      'deviceId': deviceId,
      'primaryServiceUuid': primaryServiceUuid,
      'proofOfPossession': proofOfPossession,
      'username': username,
      'capabilities': capabilities,
      'versionInfo': versionInfo,
    };
  }

  factory ESPDevice.fromMap(Map<String, dynamic> map) {
    return ESPDevice(
      name: map['name'] as String,
      transport: ESPTransportType.values.firstWhere(
        (e) => e.name == map['transport'],
      ),
      security: ESPSecurityType.values.firstWhere(
        (e) => e.name == map['security'],
      ),
      deviceId: map['deviceId'] as String?,
      primaryServiceUuid: map['primaryServiceUuid'] as String?,
      proofOfPossession: map['proofOfPossession'] as String?,
      username: map['username'] as String?,
      capabilities:
          (map['capabilities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList(),
      versionInfo: map['versionInfo'] as String?,
    );
  }

  @override
  String toString() {
    return 'ESPDevice(name: $name, transport: $transport, security: $security)';
  }
}

/// Represents a Wi-Fi network
class ESPWifiNetwork {
  /// Network SSID
  final String ssid;

  /// Signal strength (RSSI)
  final int rssi;

  /// Authentication mode
  final int auth;

  /// Channel number
  final int? channel;

  ESPWifiNetwork({
    required this.ssid,
    required this.rssi,
    required this.auth,
    this.channel,
  });

  Map<String, dynamic> toMap() {
    return {'ssid': ssid, 'rssi': rssi, 'auth': auth, 'channel': channel};
  }

  factory ESPWifiNetwork.fromMap(Map<String, dynamic> map) {
    return ESPWifiNetwork(
      ssid: map['ssid'] as String,
      rssi: map['rssi'] as int,
      auth: map['auth'] as int,
      channel: map['channel'] as int?,
    );
  }

  /// Get authentication mode as string
  String get authModeString {
    switch (auth) {
      case 0:
        return 'Open';
      case 1:
        return 'WEP';
      case 2:
        return 'WPA PSK';
      case 3:
        return 'WPA2 PSK';
      case 4:
        return 'WPA WPA2 PSK';
      case 5:
        return 'WPA2 Enterprise';
      case 6:
        return 'WPA3 PSK';
      case 7:
        return 'WPA2 WPA3 PSK';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'ESPWifiNetwork(ssid: $ssid, rssi: $rssi, auth: $authModeString)';
  }
}

/// QR code payload data
class ESPQRCodePayload {
  /// Device name
  final String name;

  /// Proof of possession
  final String? proofOfPossession;

  /// Transport type
  final ESPTransportType transport;

  /// Security type
  final ESPSecurityType security;

  /// Username (for Security 2)
  final String? username;

  /// Password
  final String? password;

  ESPQRCodePayload({
    required this.name,
    this.proofOfPossession,
    required this.transport,
    required this.security,
    this.username,
    this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'proofOfPossession': proofOfPossession,
      'transport': transport.name,
      'security': security.name,
      'username': username,
      'password': password,
    };
  }

  factory ESPQRCodePayload.fromMap(Map<String, dynamic> map) {
    return ESPQRCodePayload(
      name: map['name'] as String,
      proofOfPossession: map['proofOfPossession'] as String?,
      transport: ESPTransportType.values.firstWhere(
        (e) => e.name == map['transport'],
      ),
      security: ESPSecurityType.values.firstWhere(
        (e) => e.name == map['security'],
      ),
      username: map['username'] as String?,
      password: map['password'] as String?,
    );
  }
}

/// Provisioning configuration
class ESPProvisionConfig {
  /// Wi-Fi SSID to provision
  final String ssid;

  /// Wi-Fi password
  final String? password;

  ESPProvisionConfig({required this.ssid, this.password});

  Map<String, dynamic> toMap() {
    return {'ssid': ssid, 'password': password};
  }
}

/// Device connection status
enum ESPConnectionStatus {
  /// Connected
  connected,

  /// Disconnected
  disconnected,

  /// Connecting
  connecting,

  /// Failed to connect
  failed,
}
