import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'features/profile/models/player_profile_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('--- SEEDING STARTED ---');
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase Initialized');
  } catch (e) {
    print('Firebase initialization failed: $e');
    return;
  }

  final List<Map<String, String>> mockPlayersData = List.generate(32, (index) {
    final id = index + 1;
    return {
      'name': 'Mock Player $id',
      'email': 'player$id@efbd.com',
      'password': 'password123',
      'ign': 'IGN_Player$id',
      'uid': '100-000-${id.toString().padLeft(3, '0')}',
      'whatsapp': '017${id.toString().padLeft(8, '0')}',
    };
  });

  int successCount = 0;
  int errorCount = 0;

  for (final data in mockPlayersData) {
    try {
      print('Creating ${data['ign']} (${data['email']})...');
      
      // 1. Create Firebase Auth User
      final UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: data['email']!,
        password: data['password']!,
      );
      
      final String authUid = cred.user!.uid;
      
      // 2. Create Player Profile Model
      final player = Player(
        id: authUid,
        name: data['name']!,
        email: data['email']!,
        ign: data['ign']!,
        uid: data['uid']!,
        whatsapp: data['whatsapp']!,
        role: 'player',
      );
      
      // 3. Save to Firestore
      await FirebaseFirestore.instance
          .collection('players')
          .doc(authUid)
          .set(player.toFirestore());
      
      print('✅ Created ${data['ign']} - $authUid');
      successCount++;
      
      // 4. Delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 500));
      
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('⚠️ Skipping: ${data['email']} already exists.');
      } else {
        print('❌ Auth Error for ${data['email']}: ${e.message}');
      }
      errorCount++;
    } catch (e) {
      print('❌ General Error for ${data['email']}: $e');
      errorCount++;
    }
  }

  print('\n--- SEEDING COMPLETED ---');
  print('Success: $successCount');
  print('Errors/Skipped: $errorCount');
  print('Total: 32');
  
  // Exit the app after completion if running as a standalone script
  // Note: If running via flutter run, you'll need to stop the process manually.
}
