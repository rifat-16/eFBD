import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:efbd/core/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late MockFirebaseStorage mockStorage;
    late StorageService storageService;

    setUp(() {
      mockStorage = MockFirebaseStorage();
      storageService = StorageService(storage: mockStorage);
    });

    test('uploadMatchScreenshot uploads to correct path and returns URL', () async {
      final matchId = 'test_match_123';
      final fileBytes = Uint8List.fromList([1, 2, 3]);

      final downloadUrl = await storageService.uploadMatchScreenshot(
        matchId: matchId,
        fileBytes: fileBytes,
      );

      expect(downloadUrl, isNotEmpty);
      expect(downloadUrl, contains('match_results/test_match_123/'));
    });

    test('uploadPlayerAvatar uploads to correct path and returns URL', () async {
      final playerId = 'test_player_456';
      final fileBytes = Uint8List.fromList([4, 5, 6]);

      final downloadUrl = await storageService.uploadPlayerAvatar(
        playerId: playerId,
        fileBytes: fileBytes,
      );

      expect(downloadUrl, isNotEmpty);
      expect(downloadUrl, contains('player_avatars/test_player_456.jpg'));

      final ref = mockStorage.ref('player_avatars/$playerId.jpg');
      final url = await ref.getDownloadURL();
      expect(url, equals(downloadUrl));
    });
  });
}
