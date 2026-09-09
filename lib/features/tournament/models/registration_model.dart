import 'package:cloud_firestore/cloud_firestore.dart';

enum RegistrationStatus { pending, verified, rejected }

class Registration {
  final String id;
  final String tournamentId;
  final String playerId;
  final String playerName;
  final String playerIgn;
  final String playerUid;
  final String playerWhatsapp;
  final String playerEmail;
  final String? playerProfileImageUrl;
  final String trxId;
  final RegistrationStatus status;
  final DateTime timestamp;

  Registration({
    required this.id,
    required this.tournamentId,
    required this.playerId,
    required this.playerName,
    required this.playerIgn,
    required this.playerUid,
    required this.playerWhatsapp,
    required this.playerEmail,
    this.playerProfileImageUrl,
    required this.trxId,
    required this.status,
    required this.timestamp,
  });

  factory Registration.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Registration(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      playerId: data['playerId'] ?? '',
      playerName: data['playerName'] ?? '',
      playerIgn: data['playerIgn'] ?? '',
      playerUid: data['playerUid'] ?? '',
      playerWhatsapp: data['playerWhatsapp'] ?? '',
      playerEmail: data['playerEmail'] ?? '',
      playerProfileImageUrl: data['playerProfileImageUrl'],
      trxId: data['trxId'] ?? '',
      status: RegistrationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RegistrationStatus.pending,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tournamentId': tournamentId,
      'playerId': playerId,
      'playerName': playerName,
      'playerIgn': playerIgn,
      'playerUid': playerUid,
      'playerWhatsapp': playerWhatsapp,
      'playerEmail': playerEmail,
      'playerProfileImageUrl': playerProfileImageUrl,
      'trxId': trxId,
      'status': status.name,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
