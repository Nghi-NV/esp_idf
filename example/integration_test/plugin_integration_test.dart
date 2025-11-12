// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:esp_idf/esp_idf.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EspIdf plugin initialization test', (WidgetTester tester) async {
    final EspIdf plugin = EspIdf();
    expect(plugin, isNotNull);

    // Test that the plugin can check permissions
    final hasPermissions = await plugin.checkPermissions();
    expect(hasPermissions, isA<bool>());
  });
}
