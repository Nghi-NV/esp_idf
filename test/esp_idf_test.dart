import 'package:flutter_test/flutter_test.dart';
import 'package:esp_idf/esp_idf.dart';
import 'package:esp_idf/esp_idf_platform_interface.dart';
import 'package:esp_idf/esp_idf_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEspIdfPlatform
    with MockPlatformInterfaceMixin
    implements EspIdfPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final EspIdfPlatform initialPlatform = EspIdfPlatform.instance;

  test('$MethodChannelEspIdf is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEspIdf>());
  });

  test('getPlatformVersion', () async {
    EspIdf espIdfPlugin = EspIdf();
    MockEspIdfPlatform fakePlatform = MockEspIdfPlatform();
    EspIdfPlatform.instance = fakePlatform;

    expect(await espIdfPlugin.getPlatformVersion(), '42');
  });
}
