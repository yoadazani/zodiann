// ZOD-FND-008: the logo marks ship under shared_ui's package key in the real
// app bundle.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final name in [
    'zodiann-logo-on-dark.png',
    'zodiann-logo-on-light.png',
  ]) {
    test('the app bundle carries $name under the package key', () async {
      final data = await rootBundle.load(
        'packages/shared_ui/assets/logo/$name',
      );
      expect(data.lengthInBytes, greaterThan(1000));
    });
  }
}
