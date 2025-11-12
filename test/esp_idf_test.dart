import 'package:flutter_test/flutter_test.dart';
import 'package:esp_idf/esp_idf.dart';
import 'package:esp_idf/esp_idf_platform_interface.dart';
import 'package:esp_idf/esp_idf_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEspIdfPlatform
    with MockPlatformInterfaceMixin
    implements EspIdfPlatform {
  @override
  Stream<ESPDevice> searchBleDevices(String prefix) {
    return Stream.value(
      ESPDevice(
        name: 'PROV_TEST',
        transport: ESPTransportType.ble,
        security: ESPSecurityType.secure,
      ),
    );
  }

  @override
  Future<void> stopBleSearch() => Future.value();

  @override
  Future<String> createDevice({
    required String deviceName,
    required ESPTransportType transport,
    required ESPSecurityType security,
    String? proofOfPossession,
    String? username,
    String? softApPassword,
    String? primaryServiceUuid,
  }) => Future.value('test-device-id');

  @override
  Future<void> connectDevice(String deviceId) => Future.value();

  @override
  Future<void> disconnectDevice(String deviceId) => Future.value();

  @override
  Future<List<ESPWifiNetwork>> scanWifiNetworks(String deviceId) =>
      Future.value([]);

  @override
  Future<void> provisionDevice({
    required String deviceId,
    required String ssid,
    String? password,
  }) => Future.value();

  @override
  Stream<ESPConnectionStatus> getConnectionStatusStream(String deviceId) =>
      Stream.value(ESPConnectionStatus.connected);

  @override
  Stream<ESPProvisionStatus> getProvisioningStatusStream(String deviceId) =>
      Stream.value(ESPProvisionStatus.success);

  @override
  Future<bool> isBluetoothEnabled() => Future.value(true);

  @override
  Future<bool> requestPermissions() => Future.value(true);

  @override
  Future<bool> checkPermissions() => Future.value(true);

  @override
  Future<ESPQRCodePayload> scanQRCode({
    String? title,
    String? description,
    String? cancelButtonText,
  }) => Future.value(
    ESPQRCodePayload(
      name: 'PROV_TEST',
      transport: ESPTransportType.ble,
      security: ESPSecurityType.secure,
    ),
  );

  @override
  Future<void> connectWiFiDevice(String deviceId) => Future.value();
}

void main() {
  final EspIdfPlatform initialPlatform = EspIdfPlatform.instance;

  test('$MethodChannelEspIdf is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEspIdf>());
  });

  test('EspIdf instance creation', () {
    final espIdf = EspIdf();
    expect(espIdf, isNotNull);
  });

  test('searchBleDevices returns stream', () {
    final espIdf = EspIdf();
    final stream = espIdf.searchBleDevices('PROV_');
    expect(stream, isA<Stream<ESPDevice>>());
  });

  test('createDevice returns device ID', () async {
    final espIdf = EspIdf();
    MockEspIdfPlatform fakePlatform = MockEspIdfPlatform();
    EspIdfPlatform.instance = fakePlatform;

    final deviceId = await espIdf.createDevice(
      deviceName: 'PROV_TEST',
      transport: ESPTransportType.ble,
      security: ESPSecurityType.secure,
    );
    expect(deviceId, 'test-device-id');
  });
}
