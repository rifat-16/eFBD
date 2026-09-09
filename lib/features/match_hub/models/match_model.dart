import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentMatch {
  final String id;
  final String tournamentId;
  final String player1Id;
  final String player2Id;
  final String player1Ign;
  final String player2Ign;
  final int? player1Score;
  final int? player2Score;
  final bool isCompleted;
  final DateTime timestamp;
  final DateTime? deadline;
  final String round; 
  final String? groupId;
  final bool isVerified;
  final String? resultSubmittedBy;
  final String? screenshotUrl;
  final int bracketIndex; // Added for stable bracket ordering

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.player1Id,
    required this.player2Id,
    required this.player1Ign,
    required this.player2Ign,
    this.player1Score,
    this.player2Score,
    this.isCompleted = false,
    required this.timestamp,
    this.deadline,
    required this.round,
    this.groupId,
    this.isVerified = false,
    this.resultSubmittedBy,
    this.screenshotUrl,
    this.bracketIndex = 0,
  });

  factory TournamentMatch.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TournamentMatch(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      player1Id: data['player1Id'] ?? '',
      player2Id: data['player2Id'] ?? '',
      player1Ign: data['player1Ign'] ?? '',
      player2Ign: data['player2Ign'] ?? '',
      player1Score: data['player1Score'],
      player2Score: data['player2Score'],
      isCompleted: data['isCompleted'] ?? false,
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate() 
          : DateTime.now(),
      deadline: data['deadline'] != null 
          ? (data['deadline'] as Timestamp).toDate() 
          : null,
      round: data['round'] ?? 'Group Stage',
      groupId: data['groupId'],
      isVerified: data['isVerified'] ?? false,
      resultSubmittedBy: data['resultSubmittedBy'],
      screenshotUrl: data['screenshotUrl'],
      bracketIndex: data['bracketIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tournamentId': tournamentId,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'player1Ign': player1Ign,
      'player2Ign': player2Ign,
      'player1Score': player1Score,
      'player2Score': player2Score,
      'isCompleted': isCompleted,
      'timestamp': Timestamp.fromDate(timestamp),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'round': round,
      'groupId': groupId,
      'isVerified': isVerified,
      'resultSubmittedBy': resultSubmittedBy,
      'screenshotUrl': screenshotUrl,
      'bracketIndex': bracketIndex,
    };
  }

  TournamentMatch copyWith({
    String? id,
    String? tournamentId,
    String? player1Id,
    String? player2Id,
    String? player1Ign,
    String? player2Ign,
    int? player1Score,
    int? player2Score,
    bool? isCompleted,
    DateTime? timestamp,
    DateTime? deadline,
    String? round,
    String? groupId,
    bool? isVerified,
    String? resultSubmittedBy,
    String? screenshotUrl,
    int? bracketIndex,
  }) {
    return TournamentMatch(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      player1Id: player1Id ?? this.player1Id,
      player2Id: player2Id ?? this.player2Id,
      player1Ign: player1Ign ?? this.player1Ign,
      player2Ign: player2Ign ?? this.player2Ign,
      player1Score: player1Score ?? this.player1Score,
      player2Score: player2Score ?? this.player2Score,
      isCompleted: isCompleted ?? this.isCompleted,
      timestamp: timestamp ?? this.timestamp,
      deadline: deadline ?? this.deadline,
      round: round ?? this.round,
      groupId: groupId ?? this.groupId,
      isVerified: isVerified ?? this.isVerified,
      resultSubmittedBy: resultSubmittedBy ?? this.resultSubmittedBy,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      bracketIndex: bracketIndex ?? this.bracketIndex,
    );
  }
}
