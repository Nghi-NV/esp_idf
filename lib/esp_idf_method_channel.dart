import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'esp_idf_platform_interface.dart';

/// An implementation of [EspIdfPlatform] that uses method channels.
class MethodChannelEspIdf extends EspIdfPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('esp_idf');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
