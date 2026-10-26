import 'package:flutter_test/flutter_test.dart';
import 'package:efbd/core/providers/leaderboard_provider.dart';
import 'package:efbd/core/services/database_service.dart';
import 'package:efbd/features/profile/models/player_profile_model.dart';

class FakeDatabaseService implements DatabaseService {
  final bool shouldThrow;
  final List<Player> fakePlayers;

  FakeDatabaseService({this.shouldThrow = false, this.fakePlayers = const []});

  @override
  Stream<List<Player>> getPlayersStream({int limit = 100}) {
    if (shouldThrow) {
      return Stream.error(Exception('Stream error'));
    }
    return Stream.value(fakePlayers);
  }

  @override
  Future<List<Player>> getPlayers({int limit = 100}) async {
    if (shouldThrow) {
      throw Exception('Database connection failed');
    }
    return fakePlayers;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LeaderboardProvider', () {
    test('fetchLeaderboard updates players on success', () async {
      final fakePlayer = Player(
        id: '1',
        name: 'Test Player',
        email: 'test@example.com',
        ign: 'testign',
        uid: 'uid1',
        totalPoints: 10,
      );
      final fakeDb = FakeDatabaseService(fakePlayers: [fakePlayer]);
      final provider = LeaderboardProvider(dbService: fakeDb);

      await Future.microtask(() {}); // allow init streams to resolve

      await provider.fetchLeaderboard();

      expect(provider.players, isNotEmpty);
      expect(provider.players.first.id, '1');
      expect(provider.isLoading, false);
    });

    test('fetchLeaderboard handles exceptions gracefully', () async {
      final fakeDb = FakeDatabaseService(shouldThrow: true);
      final provider = LeaderboardProvider(dbService: fakeDb);

      await Future.microtask(() {}); // allow init streams to resolve

      await provider.fetchLeaderboard();

      expect(provider.players, isEmpty);
      expect(provider.isLoading, false);
    });

    test('fetchMonthlyLeaderboard updates players on success', () async {
      final fakePlayer = Player(
        id: '1',
        name: 'Test Player',
        email: 'test@example.com',
        ign: 'testign',
        uid: 'uid1',
        monthlyPoints: 20,
      );
      final fakeDb = FakeDatabaseService(fakePlayers: [fakePlayer]);
      final provider = LeaderboardProvider(dbService: fakeDb);

      await Future.microtask(() {});

      await provider.fetchMonthlyLeaderboard();

      expect(provider.monthlyPlayers, isNotEmpty);
      expect(provider.monthlyPlayers.first.id, '1');
      expect(provider.isMonthlyLoading, false);
    });

    test('fetchMonthlyLeaderboard handles exceptions gracefully', () async {
      final fakeDb = FakeDatabaseService(shouldThrow: true);
      final provider = LeaderboardProvider(dbService: fakeDb);

      await Future.microtask(() {});

      await provider.fetchMonthlyLeaderboard();

      expect(provider.monthlyPlayers, isEmpty);
      expect(provider.isMonthlyLoading, false);
    });
  });
}
