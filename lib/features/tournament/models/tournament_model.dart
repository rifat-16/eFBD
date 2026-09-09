import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentStatus { upcoming, ongoing, completed }
enum TournamentType { knockout, groupAndKnockout }

class Tournament {
  final String id;
  final String title;
  final String description;
  final TournamentStatus status;
  final TournamentType type;
  final DateTime? startDate;
  final DateTime? registrationEndDate;
  final int entryFee;
  final bool isFree;
  final int maxPlayers;
  final List<String> registeredPlayers;
  final List<String> rules;
  final Map<String, String> prizes;
  final String? whatsappGroupLink;

  Tournament({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.type = TournamentType.knockout,
    this.startDate,
    this.registrationEndDate,
    this.entryFee = 0,
    this.isFree = true,
    this.maxPlayers = 32,
    this.registeredPlayers = const [],
    this.rules = const [],
    this.prizes = const {},
    this.whatsappGroupLink,
  });

  factory Tournament.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Tournament(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: TournamentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TournamentStatus.upcoming,
      ),
      type: TournamentType.values.firstWhere(
        (e) => e.name == (data['type'] ?? 'knockout'),
        orElse: () => TournamentType.knockout,
      ),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      registrationEndDate: (data['registrationEndDate'] as Timestamp?)?.toDate(),
      entryFee: data['entryFee'] ?? 0,
      isFree: data['isFree'] ?? true,
      maxPlayers: data['maxPlayers'] ?? 32,
      registeredPlayers: List<String>.from(data['registeredPlayers'] ?? []),
      rules: List<String>.from(data['rules'] ?? []),
      prizes: Map<String, String>.from(data['prizes'] ?? {}),
      whatsappGroupLink: data['whatsappGroupLink'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'type': type.name,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'registrationEndDate': registrationEndDate != null ? Timestamp.fromDate(registrationEndDate!) : null,
      'entryFee': entryFee,
      'isFree': isFree,
      'maxPlayers': maxPlayers,
      'registeredPlayers': registeredPlayers,
      'rules': rules,
      'prizes': prizes,
      'whatsappGroupLink': whatsappGroupLink,
    };
  }
}
