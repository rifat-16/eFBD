import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/flavor_config.dart';
import 'firebase_options.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlavorConfig(
    flavor: Flavor.prod,
    appTitle: 'eFootballers Bangladesh',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
  );

  await Firebase.initializeApp(
    options: FlavorConfig.instance.firebaseOptions,
  );

  runApp(const EFBDApp());
}
