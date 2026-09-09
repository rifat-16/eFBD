import 'package:firebase_core/firebase_core.dart';

enum Flavor {
  dev,
  prod,
}

class FlavorConfig {
  final Flavor flavor;
  final String appTitle;
  final FirebaseOptions firebaseOptions;

  static FlavorConfig? _instance;

  factory FlavorConfig({
    required Flavor flavor,
    required String appTitle,
    required FirebaseOptions firebaseOptions,
  }) {
    _instance ??= FlavorConfig._internal(flavor, appTitle, firebaseOptions);
    return _instance!;
  }

  FlavorConfig._internal(this.flavor, this.appTitle, this.firebaseOptions);

  static FlavorConfig get instance => _instance!;

  static bool isProduction() => _instance?.flavor == Flavor.prod;
  static bool isDevelopment() => _instance?.flavor == Flavor.dev;
}
