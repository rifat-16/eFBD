import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:efbd/features/tournament/models/registration_model.dart';

class MockDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic> _data;

  MockDocumentSnapshot(this.id, this._data);

  @override
  dynamic data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Registration Model', () {
    final timestamp = DateTime(2024, 1, 1);

    test('should serialize to Firestore correctly', () {
      final registration = Registration(
        id: 'reg_123',
        tournamentId: 'tour_123',
        playerId: 'player_123',
        playerName: 'John Doe',
        playerIgn: 'JohnnyD',
        playerUid: 'uid_123',
        playerWhatsapp: '+1234567890',
        playerEmail: 'john@example.com',
        playerProfileImageUrl: 'https://example.com/pic.jpg',
        trxId: 'trx_123',
        status: RegistrationStatus.verified,
        timestamp: timestamp,
      );

      final map = registration.toFirestore();

      expect(map['tournamentId'], 'tour_123');
      expect(map['playerId'], 'player_123');
      expect(map['playerName'], 'John Doe');
      expect(map['playerIgn'], 'JohnnyD');
      expect(map['playerUid'], 'uid_123');
      expect(map['playerWhatsapp'], '+1234567890');
      expect(map['playerEmail'], 'john@example.com');
      expect(map['playerProfileImageUrl'], 'https://example.com/pic.jpg');
      expect(map['trxId'], 'trx_123');
      expect(map['status'], 'verified');
      expect(map['timestamp'], isA<Timestamp>());
      expect((map['timestamp'] as Timestamp).toDate(), timestamp);
    });

    test('should deserialize from Firestore correctly', () {
      final data = {
        'tournamentId': 'tour_123',
        'playerId': 'player_123',
        'playerName': 'John Doe',
        'playerIgn': 'JohnnyD',
        'playerUid': 'uid_123',
        'playerWhatsapp': '+1234567890',
        'playerEmail': 'john@example.com',
        'playerProfileImageUrl': 'https://example.com/pic.jpg',
        'trxId': 'trx_123',
        'status': 'verified',
        'timestamp': Timestamp.fromDate(timestamp),
      };

      final doc = MockDocumentSnapshot('reg_123', data);
      final registration = Registration.fromFirestore(doc);

      expect(registration.id, 'reg_123');
      expect(registration.tournamentId, 'tour_123');
      expect(registration.playerId, 'player_123');
      expect(registration.playerName, 'John Doe');
      expect(registration.playerIgn, 'JohnnyD');
      expect(registration.playerUid, 'uid_123');
      expect(registration.playerWhatsapp, '+1234567890');
      expect(registration.playerEmail, 'john@example.com');
      expect(registration.playerProfileImageUrl, 'https://example.com/pic.jpg');
      expect(registration.trxId, 'trx_123');
      expect(registration.status, RegistrationStatus.verified);
      expect(registration.timestamp, timestamp);
    });

    test('should handle missing fields in fromFirestore by using default values', () {
      final doc = MockDocumentSnapshot('reg_123', {
        'timestamp': Timestamp.fromDate(timestamp),
      });
      final registration = Registration.fromFirestore(doc);

      expect(registration.id, 'reg_123');
      expect(registration.tournamentId, '');
      expect(registration.playerId, '');
      expect(registration.playerName, '');
      expect(registration.playerIgn, '');
      expect(registration.playerUid, '');
      expect(registration.playerWhatsapp, '');
      expect(registration.playerEmail, '');
      expect(registration.playerProfileImageUrl, isNull);
      expect(registration.trxId, '');
      expect(registration.status, RegistrationStatus.pending);
      expect(registration.timestamp, timestamp);
    });

    test('should handle unknown status by defaulting to pending', () {
      final doc = MockDocumentSnapshot('reg_123', {
        'status': 'unknown_status_that_does_not_exist',
        'timestamp': Timestamp.fromDate(timestamp),
      });
      final registration = Registration.fromFirestore(doc);
      expect(registration.status, RegistrationStatus.pending);
    });
  });
}
