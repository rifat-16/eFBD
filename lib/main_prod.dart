import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/flavor_config.dart';
import 'firebase_options.dart'; // You will need to update this or create firebase_options_prod.dart
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // For now using the same options, but normally you'd use the prod ones
  FlavorConfig(
    flavor: Flavor.prod,
    appTitle: 'eFootballers BD',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );

  await Firebase.initializeApp(
    options: FlavorConfig.instance.firebaseOptions,
  );

  runApp(const EFBDApp());
}
