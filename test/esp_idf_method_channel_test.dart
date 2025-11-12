import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esp_idf/esp_idf_method_channel.dart';
import 'package:esp_idf/src/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelEspIdf platform = MethodChannelEspIdf();
  const MethodChannel channel = MethodChannel('esp_idf');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'createDevice':
              return 'test-device-id';
            case 'isBluetoothEnabled':
              return true;
            case 'checkPermissions':
              return true;
            case 'requestPermissions':
              return true;
            case 'scanWifiNetworks':
              return <Map<String, dynamic>>[];
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('createDevice returns device ID', () async {
    final deviceId = await platform.createDevice(
      deviceName: 'PROV_TEST',
      transport: ESPTransportType.ble,
      security: ESPSecurityType.secure,
    );
    expect(deviceId, 'test-device-id');
  });

  test('isBluetoothEnabled returns boolean', () async {
    final enabled = await platform.isBluetoothEnabled();
    expect(enabled, isA<bool>());
  });

  test('checkPermissions returns boolean', () async {
    final hasPermissions = await platform.checkPermissions();
    expect(hasPermissions, isA<bool>());
  });

  test('scanWifiNetworks returns list', () async {
    final networks = await platform.scanWifiNetworks('test-device-id');
    expect(networks, isA<List<ESPWifiNetwork>>());
  });
}
