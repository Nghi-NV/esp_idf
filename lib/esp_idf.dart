
import 'esp_idf_platform_interface.dart';

class EspIdf {
  Future<String?> getPlatformVersion() {
    return EspIdfPlatform.instance.getPlatformVersion();
  }
}
