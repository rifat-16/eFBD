import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentGroup {
  final String id;
  final String tournamentId;
  final String name; // e.g., "Group A"
  final List<String> playerIds;
  final Map<String, GroupStats> playerStats; // PlayerId -> Stats

  TournamentGroup({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.playerIds,
    this.playerStats = const {},
  });

  factory TournamentGroup.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    Map<String, dynamic> statsData = data['playerStats'] ?? {};
    Map<String, GroupStats> stats = {};
    statsData.forEach((key, value) {
      stats[key] = GroupStats.fromMap(value);
    });

    return TournamentGroup(
      id: doc.id,
      tournamentId: data['tournamentId'] ?? '',
      name: data['name'] ?? '',
      playerIds: List<String>.from(data['playerIds'] ?? []),
      playerStats: stats,
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> statsMap = {};
    playerStats.forEach((key, value) {
      statsMap[key] = value.toMap();
    });

    return {
      'tournamentId': tournamentId,
      'name': name,
      'playerIds': playerIds,
      'playerStats': statsMap,
    };
  }
}

class GroupStats {
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int points;

  GroupStats({
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.points = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  factory GroupStats.fromMap(Map<String, dynamic> map) {
    return GroupStats(
      played: map['played'] ?? 0,
      won: map['won'] ?? 0,
      drawn: map['drawn'] ?? 0,
      lost: map['lost'] ?? 0,
      goalsFor: map['goalsFor'] ?? 0,
      goalsAgainst: map['goalsAgainst'] ?? 0,
      points: map['points'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'played': played,
      'won': won,
      'drawn': drawn,
      'lost': lost,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'points': points,
    };
  }
}
