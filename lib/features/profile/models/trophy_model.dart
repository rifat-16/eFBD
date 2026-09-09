import 'package:cloud_firestore/cloud_firestore.dart';

enum TrophyTier { gold, silver, bronze, special }

class Trophy {
  final String id;
  final String title;
  final String description;
  final TrophyTier tier;
  final DateTime earnedAt;
  final String? iconUrl;

  Trophy({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.earnedAt,
    this.iconUrl,
  });

  factory Trophy.fromMap(Map<String, dynamic> data) {
    return Trophy(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      tier: TrophyTier.values.firstWhere(
        (e) => e.toString().split('.').last == data['tier'],
        orElse: () => TrophyTier.special,
      ),
      earnedAt: (data['earnedAt'] as Timestamp).toDate(),
      iconUrl: data['iconUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tier': tier.toString().split('.').last,
      'earnedAt': Timestamp.fromDate(earnedAt),
      'iconUrl': iconUrl,
    };
  }
}
