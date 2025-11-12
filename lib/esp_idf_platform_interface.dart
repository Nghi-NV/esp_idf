import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'esp_idf_method_channel.dart';

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
