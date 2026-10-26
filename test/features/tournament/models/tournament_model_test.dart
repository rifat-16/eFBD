import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:efbd/features/tournament/models/tournament_model.dart';

class FakeDocumentSnapshot implements DocumentSnapshot {
  final String _id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this._id, this._data);

  @override
  String get id => _id;

  @override
  dynamic data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Tournament Model Tests', () {
    test('fromFirestore creates Tournament from valid data', () {
      final startDate = DateTime.utc(2023, 10, 1, 10, 0, 0);
      final registrationEndDate = DateTime.utc(2023, 9, 25, 23, 59, 59);

      final data = {
        'title': 'Test Tournament',
        'description': 'A test tournament',
        'status': 'ongoing',
        'type': 'groupAndKnockout',
        'startDate': Timestamp.fromDate(startDate),
        'registrationEndDate': Timestamp.fromDate(registrationEndDate),
        'entryFee': 100,
        'isFree': false,
        'maxPlayers': 64,
        'registeredPlayers': ['user1', 'user2'],
        'rules': ['Rule 1', 'Rule 2'],
        'prizes': {'1st': '1000', '2nd': '500'},
        'whatsappGroupLink': 'https://chat.whatsapp.com/test',
      };

      final doc = FakeDocumentSnapshot('test_id', data);
      final tournament = Tournament.fromFirestore(doc);

      expect(tournament.id, 'test_id');
      expect(tournament.title, 'Test Tournament');
      expect(tournament.description, 'A test tournament');
      expect(tournament.status, TournamentStatus.ongoing);
      expect(tournament.type, TournamentType.groupAndKnockout);
      expect(tournament.startDate, startDate.toLocal());
      expect(tournament.registrationEndDate, registrationEndDate.toLocal());
      expect(tournament.entryFee, 100);
      expect(tournament.isFree, false);
      expect(tournament.maxPlayers, 64);
      expect(tournament.registeredPlayers, ['user1', 'user2']);
      expect(tournament.rules, ['Rule 1', 'Rule 2']);
      expect(tournament.prizes, {'1st': '1000', '2nd': '500'});
      expect(tournament.whatsappGroupLink, 'https://chat.whatsapp.com/test');
    });

    test('fromFirestore handles missing/null data gracefully', () {
      final data = <String, dynamic>{};
      final doc = FakeDocumentSnapshot('test_id', data);

      final tournament = Tournament.fromFirestore(doc);

      expect(tournament.id, 'test_id');
      expect(tournament.title, '');
      expect(tournament.description, '');
      expect(tournament.status, TournamentStatus.upcoming);
      expect(tournament.type, TournamentType.knockout);
      expect(tournament.startDate, isNull);
      expect(tournament.registrationEndDate, isNull);
      expect(tournament.entryFee, 0);
      expect(tournament.isFree, true);
      expect(tournament.maxPlayers, 32);
      expect(tournament.registeredPlayers, isEmpty);
      expect(tournament.rules, isEmpty);
      expect(tournament.prizes, isEmpty);
      expect(tournament.whatsappGroupLink, isNull);
    });

    test('toFirestore serializes Tournament to valid map', () {
      final startDate = DateTime.utc(2023, 10, 1, 10, 0, 0);
      final registrationEndDate = DateTime.utc(2023, 9, 25, 23, 59, 59);

      final tournament = Tournament(
        id: 'test_id',
        title: 'Test Tournament',
        description: 'A test tournament',
        status: TournamentStatus.ongoing,
        type: TournamentType.groupAndKnockout,
        startDate: startDate,
        registrationEndDate: registrationEndDate,
        entryFee: 100,
        isFree: false,
        maxPlayers: 64,
        registeredPlayers: ['user1', 'user2'],
        rules: ['Rule 1', 'Rule 2'],
        prizes: {'1st': '1000', '2nd': '500'},
        whatsappGroupLink: 'https://chat.whatsapp.com/test',
      );

      final data = tournament.toFirestore();

      expect(data['title'], 'Test Tournament');
      expect(data['description'], 'A test tournament');
      expect(data['status'], 'ongoing');
      expect(data['type'], 'groupAndKnockout');
      expect((data['startDate'] as Timestamp).toDate(), startDate.toLocal());
      expect((data['registrationEndDate'] as Timestamp).toDate(), registrationEndDate.toLocal());
      expect(data['entryFee'], 100);
      expect(data['isFree'], false);
      expect(data['maxPlayers'], 64);
      expect(data['registeredPlayers'], ['user1', 'user2']);
      expect(data['rules'], ['Rule 1', 'Rule 2']);
      expect(data['prizes'], {'1st': '1000', '2nd': '500'});
      expect(data['whatsappGroupLink'], 'https://chat.whatsapp.com/test');
    });

    test('toFirestore handles null dates gracefully', () {
      final tournament = Tournament(
        id: 'test_id',
        title: 'Test Tournament',
        description: 'A test tournament',
        status: TournamentStatus.upcoming,
      );

      final data = tournament.toFirestore();

      expect(data['startDate'], isNull);
      expect(data['registrationEndDate'], isNull);
    });
  });
}
