import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../../features/profile/models/player_profile_model.dart';

class LeaderboardProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Player> _players = [];
  List<Player> _monthlyPlayers = [];
  bool _isLoading = true;
  bool _isMonthlyLoading = true;
  StreamSubscription<List<Player>>? _subscription;

  List<Player> get players => _players;
  List<Player> get monthlyPlayers => _monthlyPlayers;
  bool get isLoading => _isLoading;
  bool get isMonthlyLoading => _isMonthlyLoading;

  LeaderboardProvider() {
    _initStreams();
  }

  void _initStreams() {
    _isLoading = true;
    _isMonthlyLoading = true;
    notifyListeners();

    // All-time Players Stream
    _dbService.getPlayersStream(limit: 100).listen(
      (data) {
        _players = _sortPlayers(data);
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Leaderboard Stream Error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );

    // Monthly Players Stream
    _dbService.getPlayersStream(limit: 100).listen(
      (data) {
        _monthlyPlayers = _sortPlayers(data, isMonthly: true);
        _isMonthlyLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Monthly Leaderboard Stream Error: $error');
        _isMonthlyLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> refreshAll() async {
    // With streams, manual refresh just triggers a re-fetch if needed
    await fetchLeaderboard();
    await fetchMonthlyLeaderboard();
  }

  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _dbService.getPlayers(limit: 100);
      _players = _sortPlayers(data);
    } catch (error) {
      debugPrint('Leaderboard Error: $error');
      _players = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMonthlyLeaderboard() async {
    _isMonthlyLoading = true;
    notifyListeners();

    try {
      final data = await _dbService.getPlayers(limit: 100);
      _monthlyPlayers = _sortPlayers(data, isMonthly: true);
    } catch (error) {
      debugPrint('Monthly Leaderboard Error: $error');
      _monthlyPlayers = [];
    } finally {
      _isMonthlyLoading = false;
      notifyListeners();
    }
  }

  List<Player> _sortPlayers(List<Player> data, {bool isMonthly = false}) {
    final List<Player> sortedData = List<Player>.from(data);
    if (sortedData.isNotEmpty) {
      // Apply ranking algorithm
      sortedData.sort((a, b) {
        if (isMonthly) {
          // 1. Primary: Monthly Points
          int cmp = b.monthlyPoints.compareTo(a.monthlyPoints);
          if (cmp != 0) return cmp;

          // 2. Secondary: Monthly Goal Difference
          cmp = b.monthlyGoalDifference.compareTo(a.monthlyGoalDifference);
          if (cmp != 0) return cmp;

          // 3. Tertiary: Monthly Goals For
          return b.monthlyGoalsFor.compareTo(a.monthlyGoalsFor);
        } else {
          // 1. Primary: Total Points
          int cmp = b.totalPoints.compareTo(a.totalPoints);
          if (cmp != 0) return cmp;

          // 2. Secondary: Goal Difference
          cmp = b.goalDifference.compareTo(a.goalDifference);
          if (cmp != 0) return cmp;

          // 3. Tertiary: Goals For
          return b.goalsFor.compareTo(a.goalsFor);
        }
      });
    }
    return sortedData;
  }

  List<Player> get topPlayers => _players.take(10).toList();
  List<Player> get topMonthlyPlayers => _monthlyPlayers.take(10).toList();

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
