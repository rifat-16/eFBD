import 'package:flutter_test/flutter_test.dart';
import 'package:efbd/core/providers/leaderboard_provider.dart';
import 'package:efbd/features/profile/models/player_profile_model.dart';

void main() {
  group('LeaderboardProvider.sortPlayers', () {
    test('should return empty list when given an empty list', () {
      final sorted = LeaderboardProvider.sortPlayers([]);
      expect(sorted, isEmpty);
    });

    test('should return list with one element unchanged', () {
      final player = Player(
        id: '1',
        name: 'Player 1',
        email: 'player1@test.com',
        ign: 'p1',
        uid: 'uid1',
      );
      final sorted = LeaderboardProvider.sortPlayers([player]);
      expect(sorted.length, 1);
      expect(sorted.first.id, '1');
    });

    test('all-time sort: should sort by totalPoints (Primary)', () {
      final p1 = Player(id: '1', name: 'P1', email: '', ign: 'p1', uid: '', totalPoints: 10);
      final p2 = Player(id: '2', name: 'P2', email: '', ign: 'p2', uid: '', totalPoints: 20);
      final p3 = Player(id: '3', name: 'P3', email: '', ign: 'p3', uid: '', totalPoints: 15);

      final sorted = LeaderboardProvider.sortPlayers([p1, p2, p3]);

      expect(sorted[0].id, '2'); // 20 points
      expect(sorted[1].id, '3'); // 15 points
      expect(sorted[2].id, '1'); // 10 points
    });

    test('all-time sort: should sort by goalDifference (Secondary) when totalPoints are equal', () {
      // goalDifference = goalsFor - goalsAgainst
      final p1 = Player(id: '1', name: 'P1', email: '', ign: 'p1', uid: '', totalPoints: 10, goalsFor: 10, goalsAgainst: 5); // GD: +5
      final p2 = Player(id: '2', name: 'P2', email: '', ign: 'p2', uid: '', totalPoints: 10, goalsFor: 10, goalsAgainst: 2); // GD: +8
      final p3 = Player(id: '3', name: 'P3', email: '', ign: 'p3', uid: '', totalPoints: 10, goalsFor: 10, goalsAgainst: 8); // GD: +2

      final sorted = LeaderboardProvider.sortPlayers([p1, p2, p3]);

      expect(sorted[0].id, '2'); // GD: +8
      expect(sorted[1].id, '1'); // GD: +5
      expect(sorted[2].id, '3'); // GD: +2
    });

    test('all-time sort: should sort by goalsFor (Tertiary) when totalPoints and goalDifference are equal', () {
      final p1 = Player(id: '1', name: 'P1', email: '', ign: 'p1', uid: '', totalPoints: 10, goalsFor: 10, goalsAgainst: 5); // GD: +5, GF: 10
      final p2 = Player(id: '2', name: 'P2', email: '', ign: 'p2', uid: '', totalPoints: 10, goalsFor: 15, goalsAgainst: 10); // GD: +5, GF: 15
      final p3 = Player(id: '3', name: 'P3', email: '', ign: 'p3', uid: '', totalPoints: 10, goalsFor: 5, goalsAgainst: 0); // GD: +5, GF: 5

      final sorted = LeaderboardProvider.sortPlayers([p1, p2, p3]);

      expect(sorted[0].id, '2'); // GF: 15
      expect(sorted[1].id, '1'); // GF: 10
      expect(sorted[2].id, '3'); // GF: 5
    });

    test('monthly sort: should sort by monthlyPoints (Primary)', () {
      final p1 = Player(id: '1', name: 'P1', email: '', ign: 'p1', uid: '', monthlyPoints: 10);
      final p2 = Player(id: '2', name: 'P2', email: '', ign: 'p2', uid: '', monthlyPoints: 20);
      final p3 = Player(id: '3', name: 'P3', email: '', ign: 'p3', uid: '', monthlyPoints: 15);

      final sorted = LeaderboardProvider.sortPlayers([p1, p2, p3], isMonthly: true);

      expect(sorted[0].id, '2'); // 20 points
      expect(sorted[1].id, '3'); // 15 points
      expect(sorted[2].id, '1'); // 10 points
    });

    test('monthly sort: should sort by monthlyGoalDifference (Secondary) when monthlyPoints are equal', () {
      // monthlyGoalDifference = monthlyGoalsFor - monthlyGoalsAgainst
      final p1 = Player(id: '1', name: 'P1', email: '', ign: 'p1', uid: '', monthlyPoints: 10, monthlyGoalsFor: 10, monthlyGoalsAgainst: 5); // MGD: +5
      final p2 = Player(id: '2', name: 'P2', email: '', ign: 'p2', uid: '', monthlyPoints: 10, monthlyGoalsFor: 10, monthlyGoalsAgainst: 2); // MGD: +8
      final p3 = Player(id: '3', name: 'P3', email: '', ign: 'p3', uid: '', monthlyPoints: 10, monthlyGoalsFor: 10, monthlyGoalsAgainst: 8); // MGD: +2

      final sorted = LeaderboardProvider.sortPlayers([p1, p2, p3], isMonthly: true);

      expect(sorted[0].id, '2'); // MGD: +8
      expect(sorted[1].id, '1'); // MGD: +5
      expect(sorted[2].id, '3'); // MGD: +2
    });

    test('monthly sort: should sort by monthlyGoalsFor (Tertiary) when monthlyPoints and monthlyGoalDifference are equal', () {
      final p1 = Player(id: '1', name: 'P1', email: '', ign: 'p1', uid: '', monthlyPoints: 10, monthlyGoalsFor: 10, monthlyGoalsAgainst: 5); // MGD: +5, MGF: 10
      final p2 = Player(id: '2', name: 'P2', email: '', ign: 'p2', uid: '', monthlyPoints: 10, monthlyGoalsFor: 15, monthlyGoalsAgainst: 10); // MGD: +5, MGF: 15
      final p3 = Player(id: '3', name: 'P3', email: '', ign: 'p3', uid: '', monthlyPoints: 10, monthlyGoalsFor: 5, monthlyGoalsAgainst: 0); // MGD: +5, MGF: 5

      final sorted = LeaderboardProvider.sortPlayers([p1, p2, p3], isMonthly: true);

      expect(sorted[0].id, '2'); // MGF: 15
      expect(sorted[1].id, '1'); // MGF: 10
      expect(sorted[2].id, '3'); // MGF: 5
    });
  });
}
