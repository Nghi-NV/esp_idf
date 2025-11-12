import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'esp_idf_method_channel.dart';
import 'src/models.dart';

abstract class EspIdfPlatform extends PlatformInterface {
  /// Constructs a EspIdfPlatform.
  EspIdfPlatform() : super(token: _token);

  static final Object _token = Object();

  static EspIdfPlatform _instance = MethodChannelEspIdf();

  /// The default instance of [EspIdfPlatform] to use.
  ///
  /// Defaults to [MethodChannelEspIdf].
  static EspIdfPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EspIdfPlatform] when
  /// they register themselves.
  static set instance(EspIdfPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Start searching for BLE devices with the given prefix
  /// Returns a stream of discovered devices
  Stream<ESPDevice> searchBleDevices(String prefix) {
    throw UnimplementedError('searchBleDevices() has not been implemented.');
  }

  /// Stop searching for BLE devices
  Future<void> stopBleSearch() {
    throw UnimplementedError('stopBleSearch() has not been implemented.');
  }

  /// Create a device instance manually
  Future<String> createDevice({
    required String deviceName,
    required ESPTransportType transport,
    required ESPSecurityType security,
    String? proofOfPossession,
    String? username,
    String? softApPassword,
    String? primaryServiceUuid,
  }) {
    throw UnimplementedError('createDevice() has not been implemented.');
  }

  /// Connect to a device
  Future<void> connectDevice(String deviceId) {
    throw UnimplementedError('connectDevice() has not been implemented.');
  }

  /// Disconnect from a device
  Future<void> disconnectDevice(String deviceId) {
    throw UnimplementedError('disconnectDevice() has not been implemented.');
  }

  /// Scan for available Wi-Fi networks
  Future<List<ESPWifiNetwork>> scanWifiNetworks(String deviceId) {
    throw UnimplementedError('scanWifiNetworks() has not been implemented.');
  }

  /// Provision the device with Wi-Fi credentials
  Future<void> provisionDevice({
    required String deviceId,
    required String ssid,
    String? password,
  }) {
    throw UnimplementedError('provisionDevice() has not been implemented.');
  }

  /// Get device connection status stream
  Stream<ESPConnectionStatus> getConnectionStatusStream(String deviceId) {
    throw UnimplementedError(
      'getConnectionStatusStream() has not been implemented.',
    );
  }

  /// Get provisioning status stream
  Stream<ESPProvisionStatus> getProvisioningStatusStream(String deviceId) {
    throw UnimplementedError(
      'getProvisioningStatusStream() has not been implemented.',
    );
  }

  /// Check if Bluetooth is enabled
  Future<bool> isBluetoothEnabled() {
    throw UnimplementedError('isBluetoothEnabled() has not been implemented.');
  }

  /// Request required permissions
  Future<bool> requestPermissions() {
    throw UnimplementedError('requestPermissions() has not been implemented.');
  }

  /// Check if required permissions are granted
  Future<bool> checkPermissions() {
    throw UnimplementedError('checkPermissions() has not been implemented.');
  }

  /// Scan QR code to get device provisioning information
  Future<ESPQRCodePayload> scanQRCode({
    String? title,
    String? description,
    String? cancelButtonText,
  }) {
    throw UnimplementedError('scanQRCode() has not been implemented.');
  }

  /// Connect to device via WiFi (SoftAP)
  /// This is used for SoftAP transport mode
  Future<void> connectWiFiDevice(String deviceId) {
    throw UnimplementedError('connectWiFiDevice() has not been implemented.');
  }
}
