export 'src/models.dart';
export 'src/exceptions.dart';

import 'esp_idf_platform_interface.dart';
import 'src/models.dart';

/// Main class for ESP-IDF provisioning functionality
class EspIdf {
  /// Start searching for BLE devices with the given prefix
  ///
  /// [prefix] - Device name prefix to search for (e.g., "PROV_")
  /// Returns a stream of discovered [ESPDevice] objects
  ///
  /// Example:
  /// ```dart
  /// final stream = EspIdf().searchBleDevices('PROV_');
  /// stream.listen((device) {
  ///   print('Found device: ${device.name}');
  /// });
  /// ```
  Stream<ESPDevice> searchBleDevices(String prefix) {
    return EspIdfPlatform.instance.searchBleDevices(prefix);
  }

  /// Stop searching for BLE devices
  Future<void> stopBleSearch() {
    return EspIdfPlatform.instance.stopBleSearch();
  }

  /// Create a device instance manually
  ///
  /// [deviceName] - Name of the device
  /// [transport] - Transport type (BLE or SoftAP)
  /// [security] - Security type (unsecured, secure, or secure2)
  /// [proofOfPossession] - Optional PoP for security version 1
  /// [username] - Required for security version 2
  /// [softApPassword] - Password for SoftAP connection
  /// [primaryServiceUuid] - Service UUID for BLE (optional)
  ///
  /// Returns a device ID that can be used for subsequent operations
  ///
  /// Example:
  /// ```dart
  /// final deviceId = await EspIdf().createDevice(
  ///   deviceName: 'PROV_123456',
  ///   transport: ESPTransportType.ble,
  ///   security: ESPSecurityType.secure,
  ///   proofOfPossession: 'abcd1234',
  /// );
  /// ```
  Future<String> createDevice({
    required String deviceName,
    required ESPTransportType transport,
    required ESPSecurityType security,
    String? proofOfPossession,
    String? username,
    String? softApPassword,
    String? primaryServiceUuid,
  }) {
    return EspIdfPlatform.instance.createDevice(
      deviceName: deviceName,
      transport: transport,
      security: security,
      proofOfPossession: proofOfPossession,
      username: username,
      softApPassword: softApPassword,
      primaryServiceUuid: primaryServiceUuid,
    );
  }

  /// Connect to a device
  ///
  /// [deviceId] - ID of the device to connect to
  ///
  /// Example:
  /// ```dart
  /// await EspIdf().connectDevice(deviceId);
  /// ```
  Future<void> connectDevice(String deviceId) {
    return EspIdfPlatform.instance.connectDevice(deviceId);
  }

  /// Disconnect from a device
  ///
  /// [deviceId] - ID of the device to disconnect from
  Future<void> disconnectDevice(String deviceId) {
    return EspIdfPlatform.instance.disconnectDevice(deviceId);
  }

  /// Scan for available Wi-Fi networks
  ///
  /// [deviceId] - ID of the connected device
  /// Returns a list of available [ESPWifiNetwork] objects
  ///
  /// Example:
  /// ```dart
  /// final networks = await EspIdf().scanWifiNetworks(deviceId);
  /// for (var network in networks) {
  ///   print('${network.ssid} - ${network.rssi} dBm');
  /// }
  /// ```
  Future<List<ESPWifiNetwork>> scanWifiNetworks(String deviceId) {
    return EspIdfPlatform.instance.scanWifiNetworks(deviceId);
  }

  /// Provision the device with Wi-Fi credentials
  ///
  /// [deviceId] - ID of the connected device
  /// [ssid] - Wi-Fi network SSID
  /// [password] - Wi-Fi network password (optional for open networks)
  ///
  /// Example:
  /// ```dart
  /// await EspIdf().provisionDevice(
  ///   deviceId: deviceId,
  ///   ssid: 'MyWiFi',
  ///   password: 'mypassword',
  /// );
  /// ```
  Future<void> provisionDevice({
    required String deviceId,
    required String ssid,
    String? password,
  }) {
    return EspIdfPlatform.instance.provisionDevice(
      deviceId: deviceId,
      ssid: ssid,
      password: password,
    );
  }

  /// Get device connection status stream
  ///
  /// [deviceId] - ID of the device
  /// Returns a stream of [ESPConnectionStatus] updates
  ///
  /// Example:
  /// ```dart
  /// EspIdf().getConnectionStatusStream(deviceId).listen((status) {
  ///   print('Connection status: $status');
  /// });
  /// ```
  Stream<ESPConnectionStatus> getConnectionStatusStream(String deviceId) {
    return EspIdfPlatform.instance.getConnectionStatusStream(deviceId);
  }

  /// Get provisioning status stream
  ///
  /// [deviceId] - ID of the device
  /// Returns a stream of [ESPProvisionStatus] updates
  ///
  /// Example:
  /// ```dart
  /// EspIdf().getProvisioningStatusStream(deviceId).listen((status) {
  ///   if (status == ESPProvisionStatus.success) {
  ///     print('Provisioning completed successfully!');
  ///   }
  /// });
  /// ```
  Stream<ESPProvisionStatus> getProvisioningStatusStream(String deviceId) {
    return EspIdfPlatform.instance.getProvisioningStatusStream(deviceId);
  }

  /// Check if Bluetooth is enabled
  ///
  /// Returns true if Bluetooth is enabled, false otherwise
  Future<bool> isBluetoothEnabled() {
    return EspIdfPlatform.instance.isBluetoothEnabled();
  }

  /// Request required permissions for BLE and Wi-Fi operations
  ///
  /// Returns true if permissions are granted, false otherwise
  ///
  /// Example:
  /// ```dart
  /// final granted = await EspIdf().requestPermissions();
  /// if (!granted) {
  ///   print('Permissions not granted');
  /// }
  /// ```
  Future<bool> requestPermissions() {
    return EspIdfPlatform.instance.requestPermissions();
  }

  /// Check if required permissions are granted
  ///
  /// Returns true if all required permissions are granted
  Future<bool> checkPermissions() {
    return EspIdfPlatform.instance.checkPermissions();
  }

  /// Scan QR code to get device provisioning information
  ///
  /// Opens a QR code scanner and returns the scanned device information
  /// including device name, proof of possession, security type, etc.
  ///
  /// [title] - Custom title for the scanner screen (default: "Scan QR Code")
  /// [description] - Custom description/instruction text (default: "Scan the QR code on your ESP device")
  /// [cancelButtonText] - Custom text for cancel button (default: "Cancel")
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final qrData = await EspIdf().scanQRCode(
  ///     title: 'Scan Device QR Code',
  ///     description: 'Point your camera at the QR code',
  ///     cancelButtonText: 'Close',
  ///   );
  ///   print('Device: ${qrData.name}, Security: ${qrData.security}');
  /// } catch (e) {
  ///   print('QR scan failed: $e');
  /// }
  /// ```
  Future<ESPQRCodePayload> scanQRCode({
    String? title,
    String? description,
    String? cancelButtonText,
  }) {
    return EspIdfPlatform.instance.scanQRCode(
      title: title,
      description: description,
      cancelButtonText: cancelButtonText,
    );
  }

  /// Connect to device via WiFi (SoftAP)
  ///
  /// This method is specifically for SoftAP transport mode.
  /// Before calling this, ensure the phone is connected to the device's
  /// Wi-Fi access point.
  ///
  /// [deviceId] - ID of the device to connect to
  ///
  /// Example:
  /// ```dart
  /// // Create device with SoftAP transport
  /// final deviceId = await EspIdf().createDevice(
  ///   deviceName: 'PROV_123456',
  ///   transport: ESPTransportType.softAp,
  ///   security: ESPSecurityType.secure,
  ///   proofOfPossession: 'abcd1234',
  /// );
  ///
  /// // Connect via WiFi
  /// await EspIdf().connectWiFiDevice(deviceId);
  /// ```
  Future<void> connectWiFiDevice(String deviceId) {
    return EspIdfPlatform.instance.connectWiFiDevice(deviceId);
  }
}
