# esp_idf

A Flutter plugin for ESP32/ESP8266 device provisioning using ESP-IDF. Supports BLE and SoftAP transport with multiple security modes.

## Features

- 🔍 **BLE Device Discovery** - Search for ESP devices via Bluetooth Low Energy
- 📡 **SoftAP Support** - Connect to devices via Wi-Fi Access Point
- 🔐 **Multiple Security Modes** - Support for unsecured, secure (Security 1), and secure2 (Security 2)
- 📱 **QR Code Scanning** - Scan QR codes to quickly provision devices (iOS native, Android via fallback)
- 📶 **Wi-Fi Network Scanning** - Scan available Wi-Fi networks from connected devices
- ⚡ **Provisioning** - Provision devices with Wi-Fi credentials
- 🔔 **Real-time Status** - Stream connection and provisioning status updates
- ✅ **Permission Management** - Built-in permission handling for BLE and Wi-Fi

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  esp_idf: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### Android

1. **Minimum SDK**: Android 5.0 (API level 21)

2. **Permissions**: Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />

<!-- For Android 12+ -->
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

3. **Dependencies**: The plugin uses `esp-idf-provisioning-android` library (version 2.4.2) via JitPack.

### iOS

1. **Minimum iOS Version**: iOS 13.0

2. **Permissions**: Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to discover and connect to ESP devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to communicate with ESP devices</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to scan for Wi-Fi networks</string>
```

3. **Dependencies**: The plugin uses `ESPProvision` CocoaPod (version 3.0.3).

4. **Install Pods**:

```bash
cd ios
pod install
cd ..
```

## Usage

### Basic Example

```dart
import 'package:esp_idf/esp_idf.dart';

final espIdf = EspIdf();

// Request permissions first
final hasPermissions = await espIdf.requestPermissions();
if (!hasPermissions) {
  print('Permissions not granted');
  return;
}

// Search for BLE devices
final deviceStream = espIdf.searchBleDevices('PROV_');
deviceStream.listen((device) {
  print('Found device: ${device.name}');
});
```

### Complete Provisioning Flow

```dart
import 'package:esp_idf/esp_idf.dart';

final espIdf = EspIdf();

// 1. Check and request permissions
if (!await espIdf.checkPermissions()) {
  await espIdf.requestPermissions();
}

// 2. Search for devices
final deviceStream = espIdf.searchBleDevices('PROV_');
deviceStream.listen((device) async {
  // 3. Create device instance
  final deviceId = await espIdf.createDevice(
    deviceName: device.name,
    transport: ESPTransportType.ble,
    security: ESPSecurityType.secure,
    proofOfPossession: 'your-pop-here', // Optional
  );

  // 4. Connect to device
  await espIdf.connectDevice(deviceId);

  // 5. Scan for Wi-Fi networks
  final networks = await espIdf.scanWifiNetworks(deviceId);
  for (var network in networks) {
    print('${network.ssid} - ${network.rssi} dBm');
  }

  // 6. Provision device
  await espIdf.provisionDevice(
    deviceId: deviceId,
    ssid: 'YourWiFiSSID',
    password: 'YourWiFiPassword',
  );
});
```

### QR Code Scanning

```dart
try {
  final qrData = await espIdf.scanQRCode(
    title: 'Scan ESP Device',
    description: 'Point your camera at the QR code',
    cancelButtonText: 'Cancel',
  );

  // Create device from QR data
  final deviceId = await espIdf.createDevice(
    deviceName: qrData.name,
    transport: qrData.transport,
    security: qrData.security,
    proofOfPossession: qrData.proofOfPossession,
    username: qrData.username, // For Security 2
  );

  // Connect based on transport type
  if (qrData.transport == ESPTransportType.ble) {
    await espIdf.connectDevice(deviceId);
  } else {
    await espIdf.connectWiFiDevice(deviceId);
  }
} catch (e) {
  print('QR scan failed: $e');
}
```

### SoftAP (Wi-Fi) Connection

```dart
// First, connect your phone to the device's Wi-Fi network manually
// Then create and connect:

final deviceId = await espIdf.createDevice(
  deviceName: 'PROV_123456',
  transport: ESPTransportType.softAp,
  security: ESPSecurityType.secure,
  proofOfPossession: 'your-pop',
  softApPassword: 'wifi-password', // If the SoftAP is password protected
);

await espIdf.connectWiFiDevice(deviceId);
```

### Monitoring Connection Status

```dart
final statusStream = espIdf.getConnectionStatusStream(deviceId);
statusStream.listen((status) {
  switch (status) {
    case ESPConnectionStatus.connected:
      print('Device connected');
      break;
    case ESPConnectionStatus.disconnected:
      print('Device disconnected');
      break;
    case ESPConnectionStatus.connecting:
      print('Connecting...');
      break;
    case ESPConnectionStatus.failed:
      print('Connection failed');
      break;
  }
});
```

### Monitoring Provisioning Status

```dart
final provisionStream = espIdf.getProvisioningStatusStream(deviceId);
provisionStream.listen((status) {
  switch (status) {
    case ESPProvisionStatus.success:
      print('Provisioning successful!');
      break;
    case ESPProvisionStatus.failed:
      print('Provisioning failed');
      break;
    case ESPProvisionStatus.configApplied:
      print('Configuration applied');
      break;
    case ESPProvisionStatus.credentialsReceived:
      print('Credentials received');
      break;
  }
});
```

## API Reference

### EspIdf Class

#### Methods

##### `searchBleDevices(String prefix)`
Search for BLE devices with the given prefix.

- **Parameters**:
  - `prefix` (String): Device name prefix to search for (e.g., "PROV_")
- **Returns**: `Stream<ESPDevice>` - Stream of discovered devices

##### `stopBleSearch()`
Stop searching for BLE devices.

- **Returns**: `Future<void>`

##### `createDevice({...})`
Create a device instance manually.

- **Parameters**:
  - `deviceName` (String, required): Name of the device
  - `transport` (ESPTransportType, required): Transport type (BLE or SoftAP)
  - `security` (ESPSecurityType, required): Security type
  - `proofOfPossession` (String?, optional): PoP for Security 1
  - `username` (String?, optional): Username for Security 2
  - `softApPassword` (String?, optional): Password for SoftAP connection
  - `primaryServiceUuid` (String?, optional): Service UUID for BLE
- **Returns**: `Future<String>` - Device ID

##### `connectDevice(String deviceId)`
Connect to a device (for BLE transport).

- **Parameters**:
  - `deviceId` (String): ID of the device to connect to
- **Returns**: `Future<void>`

##### `connectWiFiDevice(String deviceId)`
Connect to a device via Wi-Fi (for SoftAP transport).

- **Parameters**:
  - `deviceId` (String): ID of the device to connect to
- **Returns**: `Future<void>`

##### `disconnectDevice(String deviceId)`
Disconnect from a device.

- **Parameters**:
  - `deviceId` (String): ID of the device to disconnect from
- **Returns**: `Future<void>`

##### `scanWifiNetworks(String deviceId)`
Scan for available Wi-Fi networks.

- **Parameters**:
  - `deviceId` (String): ID of the connected device
- **Returns**: `Future<List<ESPWifiNetwork>>` - List of available networks

##### `provisionDevice({...})`
Provision the device with Wi-Fi credentials.

- **Parameters**:
  - `deviceId` (String, required): ID of the connected device
  - `ssid` (String, required): Wi-Fi network SSID
  - `password` (String?, optional): Wi-Fi network password (optional for open networks)
- **Returns**: `Future<void>`

##### `getConnectionStatusStream(String deviceId)`
Get device connection status stream.

- **Parameters**:
  - `deviceId` (String): ID of the device
- **Returns**: `Stream<ESPConnectionStatus>` - Stream of connection status updates

##### `getProvisioningStatusStream(String deviceId)`
Get provisioning status stream.

- **Parameters**:
  - `deviceId` (String): ID of the device
- **Returns**: `Stream<ESPProvisionStatus>` - Stream of provisioning status updates

##### `isBluetoothEnabled()`
Check if Bluetooth is enabled.

- **Returns**: `Future<bool>`

##### `requestPermissions()`
Request required permissions for BLE and Wi-Fi operations.

- **Returns**: `Future<bool>` - True if permissions are granted

##### `checkPermissions()`
Check if required permissions are granted.

- **Returns**: `Future<bool>` - True if all required permissions are granted

##### `scanQRCode({...})`
Scan QR code to get device provisioning information.

- **Parameters**:
  - `title` (String?, optional): Custom title for scanner screen
  - `description` (String?, optional): Custom description text
  - `cancelButtonText` (String?, optional): Custom cancel button text
- **Returns**: `Future<ESPQRCodePayload>` - Scanned device information

### Models

#### `ESPDevice`
Represents an ESP device discovered during scanning.

- `name` (String): Device name
- `transport` (ESPTransportType): Transport type
- `security` (ESPSecurityType): Security type
- `deviceId` (String?): Device identifier
- `primaryServiceUuid` (String?): Primary service UUID (BLE)
- `proofOfPossession` (String?): Proof of possession
- `username` (String?): Username (Security 2)
- `capabilities` (List<String>?): Device capabilities
- `versionInfo` (String?): Version information

#### `ESPWifiNetwork`
Represents a Wi-Fi network.

- `ssid` (String): Network SSID
- `rssi` (int): Signal strength
- `auth` (int): Authentication mode
- `channel` (int?): Channel number
- `authModeString` (String): Authentication mode as string

#### `ESPQRCodePayload`
QR code payload data.

- `name` (String): Device name
- `transport` (ESPTransportType): Transport type
- `security` (ESPSecurityType): Security type
- `proofOfPossession` (String?): Proof of possession
- `username` (String?): Username (Security 2)
- `password` (String?): Password

### Enums

#### `ESPTransportType`
- `ble` - Bluetooth Low Energy
- `softAp` - Soft Access Point (Wi-Fi)

#### `ESPSecurityType`
- `unsecured` - No security (not recommended for production)
- `secure` - Security version 1 with Proof of Possession
- `secure2` - Security version 2 with username and Proof of Possession

#### `ESPConnectionStatus`
- `connected` - Connected
- `disconnected` - Disconnected
- `connecting` - Connecting
- `failed` - Failed to connect

#### `ESPProvisionStatus`
- `success` - Provisioning successful
- `failed` - Provisioning failed
- `configApplied` - Configuration applied
- `credentialsReceived` - Credentials received

## Permissions

### Android

The plugin automatically handles permissions based on Android version:

- **Android 12+ (API 31+)**: Requires `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`
- **Android 6-11**: Requires `BLUETOOTH` and `BLUETOOTH_ADMIN`
- **Location**: Required for BLE scanning (Android 6+) and Wi-Fi SSID access (Android 10+)
- **Wi-Fi**: Required for Wi-Fi state and network management

### iOS

- **Bluetooth**: Required for BLE device discovery and connection
- **Location**: Required for Wi-Fi SSID access

Always request permissions before using BLE or Wi-Fi features:

```dart
if (!await espIdf.checkPermissions()) {
  final granted = await espIdf.requestPermissions();
  if (!granted) {
    // Handle permission denial
  }
}
```

## Troubleshooting

### BLE Devices Not Found

1. Ensure Bluetooth is enabled on the device
2. Check that permissions are granted
3. Verify the device prefix matches your ESP device name
4. Make sure the ESP device is in provisioning mode
5. On Android 12+, ensure location permission is granted (required for BLE scanning)

### Connection Failed

1. Verify the Proof of Possession (PoP) is correct
2. Check that the device is still in range (for BLE)
3. For SoftAP, ensure the phone is connected to the device's Wi-Fi network
4. Verify the security type matches the device configuration

### Provisioning Failed

1. Ensure the device is connected before provisioning
2. Verify Wi-Fi credentials are correct
3. Check that the Wi-Fi network is within range of the ESP device
4. Ensure the device supports the selected security mode

### QR Code Scanning Issues

- **iOS**: Uses native ESPProvision QR scanner
- **Android**: Falls back to Flutter-based scanner (requires `mobile_scanner` package in your app)

## Example App

See the `example` directory for a complete example app demonstrating all features.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See the [LICENSE](LICENSE) file for details.

## Homepage

[GitHub Repository](https://github.com/Nghi-NV/esp_idf)
