import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:efbd/core/config/flavor_config.dart';

void main() {
  // A simple dummy FirebaseOptions for testing purposes.
  const dummyFirebaseOptions = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: 'dummy-app-id',
    messagingSenderId: 'dummy-sender-id',
    projectId: 'dummy-project-id',
  );

  group('FlavorConfig Tests', () {
    test('isProduction and isDevelopment return false before initialization', () {
      // NOTE: Because FlavorConfig relies on a static variable, and static variables
      // persist across tests in Dart, we are testing the initial uninitialized state first.
      expect(FlavorConfig.isProduction(), isFalse);
      expect(FlavorConfig.isDevelopment(), isFalse);
    });

    test('accessing instance before initialization throws an error', () {
      expect(() => FlavorConfig.instance, throwsA(isA<TypeError>()));
    });

    test('can initialize with Flavor.dev and sets properties correctly', () {
      final config = FlavorConfig(
        flavor: Flavor.dev,
        appTitle: 'Test Dev App',
        firebaseOptions: dummyFirebaseOptions,
      );

      expect(config.flavor, Flavor.dev);
      expect(config.appTitle, 'Test Dev App');
      expect(config.firebaseOptions, dummyFirebaseOptions);
    });

    test('isDevelopment returns true and isProduction returns false when flavor is dev', () {
      // It was already initialized in the previous test
      expect(FlavorConfig.isDevelopment(), isTrue);
      expect(FlavorConfig.isProduction(), isFalse);
    });

    test('factory constructor returns the exact same instance (singleton pattern)', () {
      final config1 = FlavorConfig.instance;

      final config2 = FlavorConfig(
        flavor: Flavor.prod, // Even if we try to pass different parameters, it returns the singleton
        appTitle: 'Test Prod App',
        firebaseOptions: dummyFirebaseOptions,
      );

      expect(identical(config1, config2), isTrue);
      // Ensure the flavor is still dev
      expect(config2.flavor, Flavor.dev);
    });
  });
}
