import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/config/flavor_config.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize FlavorConfig for main.dart
  FlavorConfig(
    flavor: Flavor.prod,
    appTitle: 'eFootballers Bangladesh',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await Firebase.initializeApp(
      options: FlavorConfig.instance.firebaseOptions,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  runApp(const EFBDApp());
}
