import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../../features/tournament/models/tournament_model.dart';
import '../../features/tournament/models/registration_model.dart';
import '../../features/tournament/models/group_model.dart';
import '../../features/match_hub/models/match_model.dart';

class TournamentProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Tournament> _tournaments = [];
  List<Registration> _activeRegistrations = [];
  List<TournamentGroup> _tournamentGroups = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  List<Tournament> get tournaments => _tournaments;
  List<Registration> get activeRegistrations => _activeRegistrations;
  List<TournamentGroup> get tournamentGroups => _tournamentGroups;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> fetchTournaments({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    _setLoading(true);
    if (refresh) {
      _tournaments = [];
      _lastDocument = null;
      _hasMore = true;
    }

    try {
      Query query = FirebaseFirestore.instance.collection('tournaments')
          .orderBy('startDate', descending: true)
          .limit(10);
      
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final querySnapshot = await query.get(const GetOptions(source: Source.serverAndCache));
      
      if (querySnapshot.docs.length < 10) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        final newTournaments = querySnapshot.docs.map((doc) => Tournament.fromFirestore(doc)).toList();
        _tournaments.addAll(newTournaments);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching tournaments: $e');
    } finally {
      _setLoading(false);
    }
  }

  List<Registration> _registrations = [];
  bool _isLoadingRegs = false;
  bool _hasMoreRegs = true;
  DocumentSnapshot? _lastRegDocument;

  List<Registration> get registrations => _registrations;
  bool get isLoadingRegs => _isLoadingRegs;
  bool get hasMoreRegs => _hasMoreRegs;

  Future<void> fetchRegistrationsPaginated({required String tournamentId, bool refresh = false}) async {
    if (_isLoadingRegs) return;
    if (!refresh && !_hasMoreRegs) return;

    _isLoadingRegs = true;
    if (refresh) {
      _registrations = [];
      _lastRegDocument = null;
      _hasMoreRegs = true;
    }
    notifyListeners();

    try {
      var query = FirebaseFirestore.instance.collection('registrations')
          .where('tournamentId', isEqualTo: tournamentId)
          .where('status', isEqualTo: RegistrationStatus.verified.name)
          .orderBy('timestamp', descending: true)
          .limit(20);

      if (_lastRegDocument != null) {
        query = query.startAfterDocument(_lastRegDocument!);
      }

      final querySnapshot = await query.get(const GetOptions(source: Source.serverAndCache));

      if (querySnapshot.docs.length < 20) {
        _hasMoreRegs = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastRegDocument = querySnapshot.docs.last;
        final newRegs = querySnapshot.docs.map((doc) => Registration.fromFirestore(doc)).toList();
        _registrations.addAll(newRegs);
      }
    } catch (e) {
      debugPrint('Error fetching registrations: $e');
    } finally {
      _isLoadingRegs = false;
      notifyListeners();
    }
  }

  Future<void> fetchRegistrations(String tournamentId) async {
    // Keep this as a stream or change to future? 
    // For now, let's make it a future to save reads, as registrations don't change every second.
    final registrationsStream = _dbService.getRegistrations(tournamentId);
    final snapshot = await registrationsStream.first;
    _activeRegistrations = snapshot;
    notifyListeners();
  }

  Future<void> fetchGroups(String tournamentId) async {
    final groupsStream = _dbService.getTournamentGroups(tournamentId);
    final snapshot = await groupsStream.first;
    _tournamentGroups = snapshot;
    notifyListeners();
  }

  List<TournamentMatch> _matchHistory = [];
  bool _isLoadingHistory = false;
  bool _hasMoreHistory = true;
  DocumentSnapshot? _lastHistoryDocument;

  List<TournamentMatch> get matchHistory => _matchHistory;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get hasMoreHistory => _hasMoreHistory;

  Future<void> fetchMatchHistory({String? tournamentId, bool refresh = false}) async {
    if (_isLoadingHistory) return;
    if (!refresh && !_hasMoreHistory) return;

    _isLoadingHistory = true;
    if (refresh) {
      _matchHistory = [];
      _lastHistoryDocument = null;
      _hasMoreHistory = true;
    }
    notifyListeners();

    try {
      var query = FirebaseFirestore.instance.collection('matches')
          .where('isCompleted', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .limit(15);

      if (tournamentId != null) {
        query = query.where('tournamentId', isEqualTo: tournamentId);
      }

      if (_lastHistoryDocument != null) {
        query = query.startAfterDocument(_lastHistoryDocument!);
      }

      final querySnapshot = await query.get(const GetOptions(source: Source.serverAndCache));

      if (querySnapshot.docs.length < 15) {
        _hasMoreHistory = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastHistoryDocument = querySnapshot.docs.last;
        final newMatches = querySnapshot.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
        _matchHistory.addAll(newMatches);
      }
    } catch (e) {
      debugPrint('Error fetching match history for tournament $tournamentId: $e');
      if (e.toString().contains('failed-precondition')) {
        debugPrint('MISSING INDEX: Matches (isCompleted: true, tournamentId: $tournamentId, timestamp: desc)');
      }
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> registerForTournament(Registration registration) async {
    _setLoading(true);
    try {
      await _dbService.submitRegistration(registration);
      // Logic for notification could be added here or via Firestore trigger
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
