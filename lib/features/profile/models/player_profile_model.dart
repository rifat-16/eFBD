import 'package:cloud_firestore/cloud_firestore.dart';
import 'trophy_model.dart';

class Player {
  final String id;
  final String name;
  final String email;
  final String ign;
  final String uid;
  final String? whatsapp;
  final int totalPoints;
  final int goalsFor;
  final int goalsAgainst;
  final int wins;
  final int draws;
  final int losses;
  final int matchesPlayed;
  
  // Monthly Stats
  final int monthlyPoints;
  final int monthlyGoalsFor;
  final int monthlyGoalsAgainst;
  final int monthlyWins;
  final int monthlyDraws;
  final int monthlyLosses;
  final int monthlyMatchesPlayed;

  final int champions;
  final int runnersUp;
  final int goldenBoots;
  final String? profileImageUrl;
  final List<String> achievements;
  final List<Trophy> trophies;
  final String role;

  Player({
    required this.id,
    required this.name,
    required this.email,
    required this.ign,
    required this.uid,
    this.whatsapp,
    this.totalPoints = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.matchesPlayed = 0,
    this.monthlyPoints = 0,
    this.monthlyGoalsFor = 0,
    this.monthlyGoalsAgainst = 0,
    this.monthlyWins = 0,
    this.monthlyDraws = 0,
    this.monthlyLosses = 0,
    this.monthlyMatchesPlayed = 0,
    this.champions = 0,
    this.runnersUp = 0,
    this.goldenBoots = 0,
    this.profileImageUrl,
    this.achievements = const [],
    this.trophies = const [],
    this.role = 'player',
  });

  int get goalDifference => goalsFor - goalsAgainst;
  int get monthlyGoalDifference => monthlyGoalsFor - monthlyGoalsAgainst;

  factory Player.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Player(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      ign: data['ign']?.toString() ?? '',
      uid: data['uid']?.toString() ?? '',
      whatsapp: data['whatsapp']?.toString(),
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
      goalsFor: (data['goalsFor'] as num?)?.toInt() ?? 0,
      goalsAgainst: (data['goalsAgainst'] as num?)?.toInt() ?? 0,
      wins: (data['wins'] as num?)?.toInt() ?? 0,
      draws: (data['draws'] as num?)?.toInt() ?? 0,
      losses: (data['losses'] as num?)?.toInt() ?? 0,
      matchesPlayed: (data['matchesPlayed'] as num?)?.toInt() ?? 0,
      monthlyPoints: (data['monthlyPoints'] as num?)?.toInt() ?? 0,
      monthlyGoalsFor: (data['monthlyGoalsFor'] as num?)?.toInt() ?? 0,
      monthlyGoalsAgainst: (data['monthlyGoalsAgainst'] as num?)?.toInt() ?? 0,
      monthlyWins: (data['monthlyWins'] as num?)?.toInt() ?? 0,
      monthlyDraws: (data['monthlyDraws'] as num?)?.toInt() ?? 0,
      monthlyLosses: (data['monthlyLosses'] as num?)?.toInt() ?? 0,
      monthlyMatchesPlayed: (data['monthlyMatchesPlayed'] as num?)?.toInt() ?? 0,
      champions: (data['champions'] as num?)?.toInt() ?? 0,
      runnersUp: (data['runnersUp'] as num?)?.toInt() ?? 0,
      goldenBoots: (data['goldenBoots'] as num?)?.toInt() ?? 0,
      profileImageUrl: data['profileImageUrl']?.toString(),
      achievements: data['achievements'] is List ? List<String>.from(data['achievements']) : [],
      trophies: data['trophies'] is List
          ? (data['trophies'] as List).map((t) => Trophy.fromMap(t as Map<String, dynamic>)).toList()
          : [],
      role: data['role']?.toString() ?? 'player',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'ign': ign,
      'uid': uid,
      'whatsapp': whatsapp,
      'totalPoints': totalPoints,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'matchesPlayed': matchesPlayed,
      'monthlyPoints': monthlyPoints,
      'monthlyGoalsFor': monthlyGoalsFor,
      'monthlyGoalsAgainst': monthlyGoalsAgainst,
      'monthlyWins': monthlyWins,
      'monthlyDraws': monthlyDraws,
      'monthlyLosses': monthlyLosses,
      'monthlyMatchesPlayed': monthlyMatchesPlayed,
      'champions': champions,
      'runnersUp': runnersUp,
      'goldenBoots': goldenBoots,
      'profileImageUrl': profileImageUrl,
      'achievements': achievements,
      'trophies': trophies.map((t) => t.toMap()).toList(),
      'role': role,
    };
  }

  Player copyWith({
    String? id,
    String? name,
    String? email,
    String? ign,
    String? uid,
    String? whatsapp,
    int? totalPoints,
    int? goalsFor,
    int? goalsAgainst,
    int? wins,
    int? draws,
    int? losses,
    int? matchesPlayed,
    int? monthlyPoints,
    int? monthlyGoalsFor,
    int? monthlyGoalsAgainst,
    int? monthlyWins,
    int? monthlyDraws,
    int? monthlyLosses,
    int? monthlyMatchesPlayed,
    int? champions,
    int? runnersUp,
    int? goldenBoots,
    String? profileImageUrl,
    List<String>? achievements,
    List<Trophy>? trophies,
    String? role,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      ign: ign ?? this.ign,
      uid: uid ?? this.uid,
      whatsapp: whatsapp ?? this.whatsapp,
      totalPoints: totalPoints ?? this.totalPoints,
      goalsFor: goalsFor ?? this.goalsFor,
      goalsAgainst: goalsAgainst ?? this.goalsAgainst,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      monthlyPoints: monthlyPoints ?? this.monthlyPoints,
      monthlyGoalsFor: monthlyGoalsFor ?? this.monthlyGoalsFor,
      monthlyGoalsAgainst: monthlyGoalsAgainst ?? this.monthlyGoalsAgainst,
      monthlyWins: monthlyWins ?? this.monthlyWins,
      monthlyDraws: monthlyDraws ?? this.monthlyDraws,
      monthlyLosses: monthlyLosses ?? this.monthlyLosses,
      monthlyMatchesPlayed: monthlyMatchesPlayed ?? this.monthlyMatchesPlayed,
      champions: champions ?? this.champions,
      runnersUp: runnersUp ?? this.runnersUp,
      goldenBoots: goldenBoots ?? this.goldenBoots,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      achievements: achievements ?? this.achievements,
      trophies: trophies ?? this.trophies,
      role: role ?? this.role,
    );
  }
}
