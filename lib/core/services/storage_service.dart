import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadMatchScreenshot({
    required String matchId,
    required Uint8List fileBytes,
  }) async {
    final ref = _storage.ref().child('match_results/$matchId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<String> uploadPlayerAvatar({
    required String playerId,
    required Uint8List fileBytes,
  }) async {
    final ref = _storage.ref().child('player_avatars/$playerId.jpg');
    final uploadTask = ref.putData(fileBytes, SettableMetadata(contentType: 'image/jpeg'));
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
