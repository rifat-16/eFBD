import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../features/profile/models/player_profile_model.dart';
import '../../features/profile/models/trophy_model.dart';
import '../../features/tournament/models/tournament_model.dart';
import '../../features/tournament/models/registration_model.dart';
import '../../features/tournament/models/group_model.dart';
import '../../features/match_hub/models/match_model.dart';
import '../models/community_config.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cache for player profiles (10 minute TTL)
  final Map<String, _CachedPlayer> _playerCache = {};
  static const _cacheDuration = Duration(minutes: 10);

  // --- Players ---
  Future<List<Player>> getPlayers({int limit = 100}) async {
    // We remove the server-side orderBy to ensure players without the field 
    // (due to older versions/bugs) still show up, and then sort in memory.
    final snapshot = await _db
        .collection('players')
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.map((doc) => Player.fromFirestore(doc)).toList();
  }

  Stream<List<Player>> getPlayersStream({int limit = 100}) {
    return _db
        .collection('players')
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Player.fromFirestore(doc)).toList());
  }

  Future<void> updatePlayer(Player player) async {
    final batch = _db.batch();

    // 1. Update Player Document
    batch.set(_db.collection('players').doc(player.id), player.toFirestore());

    // 2. Sync Profile Image with Registrations (Denormalization)
    if (player.profileImageUrl != null) {
      final registrations = await _db
          .collection('registrations')
          .where('playerId', isEqualTo: player.id)
          .get();
      
      for (var doc in registrations.docs) {
        batch.update(doc.reference, {'playerProfileImageUrl': player.profileImageUrl});
      }
    }

    await batch.commit();
    _playerCache.remove(player.id); // Invalidate cache
  }

  Future<Player?> getPlayer(String id) async {
    // Check cache first
    if (_playerCache.containsKey(id)) {
      final cached = _playerCache[id]!;
      if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
        return cached.player;
      }
    }

    final doc = await _db.collection('players').doc(id).get(const GetOptions(source: Source.serverAndCache));
    if (doc.exists) {
      final player = Player.fromFirestore(doc);
      _playerCache[id] = _CachedPlayer(player, DateTime.now());
      return player;
    }
    return null;
  }

  Future<bool> isWhatsappUnique(String whatsapp, {String? excludePlayerId}) async {
    final query = await _db
        .collection('players')
        .where('whatsapp', isEqualTo: whatsapp)
        .get();
    
    if (excludePlayerId != null) {
      return query.docs.every((doc) => doc.id == excludePlayerId);
    }
    return query.docs.isEmpty;
  }

  Future<bool> isUidUnique(String uid, {String? excludePlayerId}) async {
    final query = await _db
        .collection('players')
        .where('uid', isEqualTo: uid)
        .get();
    
    if (excludePlayerId != null) {
      return query.docs.every((doc) => doc.id == excludePlayerId);
    }
    return query.docs.isEmpty;
  }

  Future<bool> isEmailUnique(String email) async {
    final query = await _db
        .collection('players')
        .where('email', isEqualTo: email)
        .get();
    return query.docs.isEmpty;
  }

  Stream<Player?> getPlayerStream(String id) {
    return _db.collection('players').doc(id).snapshots().map((doc) {
      if (doc.exists) return Player.fromFirestore(doc);
      return null;
    });
  }

  Stream<Tournament?> getTournamentStream(String id) {
    return _db.collection('tournaments').doc(id).snapshots().map((doc) {
      if (doc.exists) return Tournament.fromFirestore(doc);
      return null;
    });
  }


  // --- Admins ---
  Future<List<String>> getAdminUserIds() async {
    final snapshot = await _db
        .collection('players')
        .where('role', isEqualTo: 'admin')
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // --- Tournaments ---
  Future<List<Tournament>> getTournamentsOnce({int limit = 20, DocumentSnapshot? startAfter}) async {
    var query = _db.collection('tournaments')
        .orderBy('startDate', descending: true)
        .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.map((doc) => Tournament.fromFirestore(doc)).toList();
  }

  Stream<List<Tournament>> getTournaments() {
    return _db.collection('tournaments').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Tournament.fromFirestore(doc)).toList());
  }


  Future<void> addTournament(Tournament tournament) {
    return _db.collection('tournaments').add(tournament.toFirestore());
  }

  // --- Registrations ---
  Future<List<Registration>> getRegistrationsOnce(String tournamentId) async {
    final snapshot = await _db
        .collection('registrations')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    final list = snapshot.docs.map((doc) => Registration.fromFirestore(doc)).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Stream<List<Registration>> getAllRegistrations() {
    return _db.collection('registrations').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Registration.fromFirestore(doc)).toList());
  }

  Stream<List<Registration>> getRegistrations(String tournamentId) {
    return _db
        .collection('registrations')
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Registration.fromFirestore(doc)).toList();
      // Sort by timestamp in memory to avoid needing a composite index
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Future<List<Registration>> getRegistrationsPaginated({
    required String tournamentId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    RegistrationStatus? status,
  }) async {
    var query = _db
        .collection('registrations')
        .where('tournamentId', isEqualTo: tournamentId);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    // Note: To use startAfter with orderBy, we need an index.
    // If no index exists, we might need to sort in memory or ensure index exists.
    // For now, ordering by timestamp.
    query = query.orderBy('timestamp', descending: true);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(limit).get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.map((doc) => Registration.fromFirestore(doc)).toList();
  }

  Stream<List<Registration>> getUserRegistrations(String tournamentId, String playerId) {
    return _db
        .collection('registrations')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('playerId', isEqualTo: playerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Registration.fromFirestore(doc)).toList());
  }

  Future<void> submitRegistration(Registration registration) {
    return _db.collection('registrations').add(registration.toFirestore());
  }

  // --- Matches ---
  Future<List<TournamentMatch>> getMatchesOnce(String tournamentId) async {
    final snapshot = await _db
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    final list = snapshot.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<List<TournamentMatch>> getMatchesPaginated({
    String? tournamentId,
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    var query = _db.collection('matches')
        .where('isCompleted', isEqualTo: true)
        .orderBy('timestamp', descending: true);

    if (tournamentId != null) {
      query = query.where('tournamentId', isEqualTo: tournamentId);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.limit(limit).get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
  }

  Stream<List<TournamentMatch>> getMatches(String tournamentId) {
    return _db
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    });
  }

  Stream<TournamentMatch?> getMyMatchByTournament(String tournamentId, String playerId) {
    // Check as player 1
    final p1Stream = _db
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('player1Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: false)
        .snapshots();
    
    // Check as player 2
    final p2Stream = _db
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('player2Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: false)
        .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, TournamentMatch?>(
      p1Stream,
      p2Stream,
      (s1, s2) {
        if (s1.docs.isNotEmpty) return TournamentMatch.fromFirestore(s1.docs.first);
        if (s2.docs.isNotEmpty) return TournamentMatch.fromFirestore(s2.docs.first);
        return null;
      },
    );
  }

  Future<void> createMatch(TournamentMatch match) {
    return _db.collection('matches').add(match.toFirestore());
  }

  Future<List<TournamentMatch>> getMyMatchesOnce(String playerId) async {
    final p1Query = await _db
        .collection('matches')
        .where('player1Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: false)
        .get();
    
    final p2Query = await _db
        .collection('matches')
        .where('player2Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: false)
        .get();

    final list1 = p1Query.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
    final list2 = p2Query.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
    return [...list1, ...list2]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Stream<List<TournamentMatch>> getMyMatches(String playerId) {
    // Combine matches where player is either player 1 or player 2
    final p1Stream = _db
        .collection('matches')
        .where('player1Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: false)
        .snapshots();
    
    final p2Stream = _db
        .collection('matches')
        .where('player2Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: false)
        .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<TournamentMatch>>(
      p1Stream,
      p2Stream,
      (s1, s2) {
        final list1 = s1.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
        final list2 = s2.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
        return [...list1, ...list2]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      },
    );
  }

  Future<List<TournamentMatch>> getMyMatchHistoryOnce(String playerId, {int limit = 20, DocumentSnapshot? startAfter}) async {
    // Note: Due to Firestore query limitations on 'orderBy' with multiple 'where' clauses,
    // we fetch from both player1 and player2 slots and combine them.

    var query1 = _db
        .collection('matches')
        .where('player1Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    var query2 = _db
        .collection('matches')
        .where('player2Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .limit(limit);
    
    // Pagination support is tricky here because we have two queries.
    // Realistically, for profile history, we can fetch more and merge.
    
    final p1Query = await query1.get(const GetOptions(source: Source.serverAndCache));
    final p2Query = await query2.get(const GetOptions(source: Source.serverAndCache));

    final list1 = p1Query.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
    final list2 = p2Query.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
    final combined = [...list1, ...list2];
    combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return combined.take(limit).toList();
  }

  Stream<List<TournamentMatch>> getMyMatchHistory(String playerId) {
    final p1Stream = _db
        .collection('matches')
        .where('player1Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: true)
        .snapshots();
    
    final p2Stream = _db
        .collection('matches')
        .where('player2Id', isEqualTo: playerId)
        .where('isCompleted', isEqualTo: true)
        .snapshots();

    return Rx.combineLatest2<QuerySnapshot, QuerySnapshot, List<TournamentMatch>>(
      p1Stream,
      p2Stream,
      (s1, s2) {
        final list1 = s1.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
        final list2 = s2.docs.map((doc) => TournamentMatch.fromFirestore(doc)).toList();
        final combined = [...list1, ...list2];
        combined.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
        return combined;
      },
    );
  }

  Future<void> createMatches(List<TournamentMatch> matches) async {
    if (matches.isEmpty) return;
    
    final batch = _db.batch();
    final tournamentId = matches.first.tournamentId;
    final List<TournamentMatch> createdMatches = [];

    for (var match in matches) {
      final ref = _db.collection('matches').doc();
      final newMatch = match.copyWith(id: ref.id);
      batch.set(ref, newMatch.toFirestore());
      createdMatches.add(newMatch);
    }

    // Update tournament status to ongoing when matches are created
    batch.update(_db.collection('tournaments').doc(tournamentId), {
      'status': TournamentStatus.ongoing.name,
    });

    await batch.commit();

    // Trigger progression for matches that are already completed (e.g., BYEs)
    for (var match in createdMatches) {
      if (match.isVerified && match.isCompleted) {
        await _handleKnockoutProgression(match);
      }
    }
  }

  Future<void> updateMatchResult(TournamentMatch match) async {
    return _db.collection('matches').doc(match.id).set(match.toFirestore());
  }

  Future<void> verifyMatchResult(TournamentMatch match) async {
    final batch = _db.batch();
    final s1 = match.player1Score ?? 0;
    final s2 = match.player2Score ?? 0;

    // 1. Update Match Status
    batch.update(_db.collection('matches').doc(match.id), {
      'isVerified': true,
      'isCompleted': true,
      'player1Score': s1,
      'player2Score': s2,
      'resultSubmittedBy': match.resultSubmittedBy,
    });

    // 2. Update Player Global Stats
    final p1Ref = _db.collection('players').doc(match.player1Id);
    batch.update(p1Ref, {
      'matchesPlayed': FieldValue.increment(1),
      'goalsFor': FieldValue.increment(s1),
      'goalsAgainst': FieldValue.increment(s2),
      'wins': FieldValue.increment(s1 > s2 ? 1 : 0),
      'draws': FieldValue.increment(s1 == s2 ? 1 : 0),
      'losses': FieldValue.increment(s1 < s2 ? 1 : 0),
      'totalPoints': FieldValue.increment(s1 > s2 ? 3 : (s1 == s2 ? 1 : 0)),
      
      // Monthly Stats
      'monthlyMatchesPlayed': FieldValue.increment(1),
      'monthlyGoalsFor': FieldValue.increment(s1),
      'monthlyGoalsAgainst': FieldValue.increment(s2),
      'monthlyWins': FieldValue.increment(s1 > s2 ? 1 : 0),
      'monthlyDraws': FieldValue.increment(s1 == s2 ? 1 : 0),
      'monthlyLosses': FieldValue.increment(s1 < s2 ? 1 : 0),
      'monthlyPoints': FieldValue.increment(s1 > s2 ? 3 : (s1 == s2 ? 1 : 0)),
    });

    if (match.player2Id != 'BYE') {
      final p2Ref = _db.collection('players').doc(match.player2Id);
      batch.update(p2Ref, {
        'matchesPlayed': FieldValue.increment(1),
        'goalsFor': FieldValue.increment(s2),
        'goalsAgainst': FieldValue.increment(s1),
        'wins': FieldValue.increment(s2 > s1 ? 1 : 0),
        'draws': FieldValue.increment(s2 == s1 ? 1 : 0),
        'losses': FieldValue.increment(s2 < s1 ? 1 : 0),
        'totalPoints': FieldValue.increment(s2 > s1 ? 3 : (s2 == s1 ? 1 : 0)),

        // Monthly Stats
        'monthlyMatchesPlayed': FieldValue.increment(1),
        'monthlyGoalsFor': FieldValue.increment(s2),
        'monthlyGoalsAgainst': FieldValue.increment(s1),
        'monthlyWins': FieldValue.increment(s2 > s1 ? 1 : 0),
        'monthlyDraws': FieldValue.increment(s2 == s1 ? 1 : 0),
        'monthlyLosses': FieldValue.increment(s2 < s1 ? 1 : 0),
        'monthlyPoints': FieldValue.increment(s2 > s1 ? 3 : (s2 == s1 ? 1 : 0)),
      });
    }

    await batch.commit();

    // 3. Update Group Stats if it's a Group Match
    if (match.groupId != null && match.groupId!.isNotEmpty) {
      final groupDoc = await _db.collection('groups').doc(match.groupId).get();
      if (groupDoc.exists) {
        final group = TournamentGroup.fromFirestore(groupDoc);
        final stats = Map<String, GroupStats>.from(group.playerStats);

        // Player 1
        final p1 = stats[match.player1Id] ?? GroupStats();
        stats[match.player1Id] = GroupStats(
          played: p1.played + 1,
          won: p1.won + (s1 > s2 ? 1 : 0),
          drawn: p1.drawn + (s1 == s2 ? 1 : 0),
          lost: p1.lost + (s1 < s2 ? 1 : 0),
          goalsFor: p1.goalsFor + s1,
          goalsAgainst: p1.goalsAgainst + s2,
          points: p1.points + (s1 > s2 ? 3 : (s1 == s2 ? 1 : 0)),
        );

        // Player 2
        final p2 = stats[match.player2Id] ?? GroupStats();
        stats[match.player2Id] = GroupStats(
          played: p2.played + 1,
          won: p2.won + (s2 > s1 ? 1 : 0),
          drawn: p2.drawn + (s2 == s1 ? 1 : 0),
          lost: p2.lost + (s2 < s1 ? 1 : 0),
          goalsFor: p2.goalsFor + s2,
          goalsAgainst: p2.goalsAgainst + s1,
          points: p2.points + (s2 > s1 ? 3 : (s2 == s1 ? 1 : 0)),
        );

        await _db.collection('groups').doc(match.groupId).update({
          'playerStats': stats.map((key, value) => MapEntry(key, value.toMap())),
        });

        // Check if all group stage matches are completed to notify admin or auto-advance
        // (Manual advancement is currently preferred in the UI)
      }
    } else {
      // 4. Handle Knockout Progression
      await _handleKnockoutProgression(match);
    }
  }

  Future<void> _handleKnockoutProgression(TournamentMatch match) async {
    final currentRound = match.round.trim();
    final normalizedRound = currentRound.toLowerCase();
    
    if (normalizedRound == 'final' || normalizedRound == '3rd place' || normalizedRound == 'qualifying round') return;

    final winnerId = (match.player1Score ?? 0) > (match.player2Score ?? 0) 
        ? match.player1Id 
        : match.player2Id;
    final winnerIgn = (match.player1Score ?? 0) > (match.player2Score ?? 0)
        ? match.player1Ign
        : match.player2Ign;

    if (winnerId == 'BYE') return;

    // Determine next round name dynamically
    String nextRound = getNextRoundName(currentRound);
    if (nextRound.toLowerCase() == normalizedRound) return;

    // Find the match in the next round where this winner should go
    // Match index i in current round goes to match index floor(i/2) in next round
    final nextMatchIndex = (match.bracketIndex / 2).floor();
    final isPlayer1Slot = match.bracketIndex % 2 == 0;

    final nextMatchQuery = await _db.collection('matches')
        .where('tournamentId', isEqualTo: match.tournamentId)
        .where('round', isEqualTo: nextRound)
        .where('bracketIndex', isEqualTo: nextMatchIndex)
        .get();

    if (nextMatchQuery.docs.isNotEmpty) {
      final nextMatchDoc = nextMatchQuery.docs.first;
      final updates = isPlayer1Slot 
          ? {'player1Id': winnerId, 'player1Ign': winnerIgn}
          : {'player2Id': winnerId, 'player2Ign': winnerIgn};
      
      await _db.collection('matches').doc(nextMatchDoc.id).update(updates);
      
      // If the other player is already a BYE, auto-complete this match too
      final data = nextMatchDoc.data();
      final otherId = isPlayer1Slot ? data['player2Id'] : data['player1Id'];
      if (otherId == 'BYE') {
        final currentNextMatch = TournamentMatch.fromFirestore(await nextMatchDoc.reference.get());
        final autoUpdate = currentNextMatch.copyWith(
          player1Score: isPlayer1Slot ? 1 : 0,
          player2Score: isPlayer1Slot ? 0 : 1,
          isCompleted: true,
          isVerified: true,
        );
        await verifyMatchResult(autoUpdate);
      }
    } else {
      // Create next round match if it doesn't exist (though usually they are pre-generated)
      await _db.collection('matches').add({
        'tournamentId': match.tournamentId,
        'round': nextRound,
        'bracketIndex': nextMatchIndex,
        'player1Id': isPlayer1Slot ? winnerId : 'TBD',
        'player1Ign': isPlayer1Slot ? winnerIgn : 'TBD',
        'player2Id': isPlayer1Slot ? 'TBD' : winnerId,
        'player2Ign': isPlayer1Slot ? 'TBD' : winnerIgn,
        'isCompleted': false,
        'isVerified': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    // Handle 3rd Place Match if this is Semi Finals
    if (normalizedRound == 'semi finals') {
      final loserId = (match.player1Score ?? 0) > (match.player2Score ?? 0) 
          ? match.player2Id 
          : match.player1Id;
      final loserIgn = (match.player1Score ?? 0) > (match.player2Score ?? 0)
          ? match.player2Ign
          : match.player1Ign;
      
      if (loserId != 'BYE') {
        final thirdPlaceQuery = await _db.collection('matches')
            .where('tournamentId', isEqualTo: match.tournamentId)
            .where('round', isEqualTo: '3rd Place')
            .where('bracketIndex', isEqualTo: 0)
            .get();
            
        if (thirdPlaceQuery.docs.isNotEmpty) {
          final docId = thirdPlaceQuery.docs.first.id;
          await _db.collection('matches').doc(docId).update(
            isPlayer1Slot 
              ? {'player1Id': loserId, 'player1Ign': loserIgn}
              : {'player2Id': loserId, 'player2Ign': loserIgn}
          );
        } else {
          await _db.collection('matches').add({
            'tournamentId': match.tournamentId,
            'round': '3rd Place',
            'bracketIndex': 0,
            'player1Id': isPlayer1Slot ? loserId : 'TBD',
            'player1Ign': isPlayer1Slot ? loserIgn : 'TBD',
            'player2Id': isPlayer1Slot ? 'TBD' : loserId,
            'player2Ign': isPlayer1Slot ? 'TBD' : loserIgn,
            'isCompleted': false,
            'isVerified': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }
    }
  }

  // --- Profile Update Requests ---
  Future<void> submitProfileUpdateRequest(Map<String, dynamic> request) {
    return _db.collection('profile_update_requests').add(request);
  }

  Stream<bool> hasPendingProfileRequest(String userId) {
    return _db
        .collection('profile_update_requests')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }

  Stream<Map<String, dynamic>?> getLatestProfileRequest(String userId) {
    return _db
        .collection('profile_update_requests')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      
      final docs = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      
      // Sort: Pending/Newest first. Handle null createdAt by treating it as "now"
      docs.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
        
        // If one is pending and other is not, pending should come first
        final aStatus = a['status'] as String?;
        final bStatus = b['status'] as String?;
        if (aStatus == 'pending' && bStatus != 'pending') return -1;
        if (bStatus == 'pending' && aStatus != 'pending') return 1;

        return bTime.compareTo(aTime);
      });
      
      return docs.isNotEmpty ? docs.first : null;
    });
  }

  Stream<List<Map<String, dynamic>>> getProfileUpdateRequests() {
    return _db
        .collection('profile_update_requests')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .where((data) => data['status'] == 'pending')
          .toList();
      
      docs.sort((a, b) {
        final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      
      return docs;
    });
  }

  Future<void> approveProfileUpdateRequest(String requestId, String userId, Map<String, dynamic> requestedData) async {
    final batch = _db.batch();
    
    // Map requestedData to Player model fields
    final playerUpdates = {
      'name': requestedData['realName'],
      'ign': requestedData['ign'],
      'uid': requestedData['eFootballUid'],
      'whatsapp': requestedData['whatsapp'],
    };
    
    // 1. Update Player Profile
    batch.update(_db.collection('players').doc(userId), playerUpdates);
    
    // 2. Mark Request as Approved
    batch.update(_db.collection('profile_update_requests').doc(requestId), {
      'status': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> rejectProfileUpdateRequest(String requestId, String reason) {
    return _db.collection('profile_update_requests').doc(requestId).update({
      'status': 'rejected',
      'rejectionReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }


  // --- Tournament Stats ---
  Future<void> awardTrophy(String playerId, Trophy trophy) async {
    return _db.collection('players').doc(playerId).update({
      'trophies': FieldValue.arrayUnion([trophy.toMap()]),
    });
  }

  Future<void> completeTournament(Tournament tournament) async {
    // 1. Get all matches to find results
    final matches = await getMatchesOnce(tournament.id);
    
    // 2. Find Final match (the one that determines the champion)
    final finalMatch = matches.firstWhere(
      (m) => m.round.toLowerCase().trim() == 'final',
      orElse: () => throw Exception("Final match not found or not generated yet."),
    );

    if (!finalMatch.isVerified) {
      throw Exception("Final match result must be verified before completing the tournament.");
    }

    // 3. Determine Champion and Runner-up
    final s1 = finalMatch.player1Score ?? 0;
    final s2 = finalMatch.player2Score ?? 0;
    final championId = s1 > s2 ? finalMatch.player1Id : finalMatch.player2Id;
    final championIgn = s1 > s2 ? finalMatch.player1Ign : finalMatch.player2Ign;
    final runnerUpId = s1 > s2 ? finalMatch.player2Id : finalMatch.player1Id;
    final runnerUpIgn = s1 > s2 ? finalMatch.player2Ign : finalMatch.player1Ign;

    // 4. Calculate Golden Boot (Most goals)
    Map<String, int> goalStats = {};
    for (var m in matches) {
      if (!m.isVerified) continue;
      goalStats[m.player1Id] = (goalStats[m.player1Id] ?? 0) + (m.player1Score ?? 0);
      if (m.player2Id != 'BYE') {
        goalStats[m.player2Id] = (goalStats[m.player2Id] ?? 0) + (m.player2Score ?? 0);
      }
    }

    String goldenBootId = '';
    String goldenBootName = 'TBA';
    int maxGoals = 0;
    if (goalStats.isNotEmpty) {
      final topScorerEntry = goalStats.entries.reduce((a, b) => a.value > b.value ? a : b);
      goldenBootId = topScorerEntry.key;
      maxGoals = topScorerEntry.value;
      final topScorer = await getPlayer(goldenBootId);
      goldenBootName = topScorer?.ign ?? 'Unknown';
    }

    final batch = _db.batch();

    // 5. Update Tournament Status
    batch.update(_db.collection('tournaments').doc(tournament.id), {
      'status': TournamentStatus.completed.name,
    });

    // 6. Update Player Stats and Trophies
    final now = Timestamp.now();

    // Champion Updates
    batch.update(_db.collection('players').doc(championId), {
      'champions': FieldValue.increment(1),
      'trophies': FieldValue.arrayUnion([{
        'id': 'champ_${tournament.id}',
        'title': 'CHAMPION',
        'description': 'Winner of ${tournament.title}',
        'tier': 'gold',
        'earnedAt': now,
      }]),
    });

    // Runner-up Updates
    batch.update(_db.collection('players').doc(runnerUpId), {
      'runnersUp': FieldValue.increment(1),
      'trophies': FieldValue.arrayUnion([{
        'id': 'runner_${tournament.id}',
        'title': 'RUNNER-UP',
        'description': 'Finalist in ${tournament.title}',
        'tier': 'silver',
        'earnedAt': now,
      }]),
    });

    // Golden Boot Updates
    if (goldenBootId.isNotEmpty && goldenBootId != 'BYE') {
      batch.update(_db.collection('players').doc(goldenBootId), {
        'goldenBoots': FieldValue.increment(1),
        'trophies': FieldValue.arrayUnion([{
          'id': 'gb_${tournament.id}',
          'title': 'GOLDEN BOOT',
          'description': 'Top Scorer in ${tournament.title} ($maxGoals goals)',
          'tier': 'special',
          'earnedAt': now,
        }]),
      });
    }

    // 7. Add to Hall of Fame
    final hofSnap = await _db.collection('hall_of_fame').get();
    final seasonNumber = hofSnap.docs.length + 1;

    final hofRef = _db.collection('hall_of_fame').doc();
    batch.set(hofRef, {
      'season': seasonNumber.toString(),
      'tournamentName': tournament.title,
      'championName': championIgn,
      'runnerUpName': runnerUpIgn,
      'goldenBootName': goldenBootName,
      'championId': championId,
      'runnerUpId': runnerUpId,
      'goldenBootId': goldenBootId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<void> deleteTournament(String tournamentId) async {
    // Note: In a real app, you might want to also delete related matches, registrations, and groups.
    return _db.collection('tournaments').doc(tournamentId).delete();
  }

  Future<void> updateTournament(Tournament tournament) {
    return _db.collection('tournaments').doc(tournament.id).update(tournament.toFirestore());
  }

  Future<void> verifyRegistration(Registration reg) async {
    final batch = _db.batch();

    // 1. Update registration status
    batch.update(_db.collection('registrations').doc(reg.id), {
      'status': RegistrationStatus.verified.name,
    });

    // 2. Add player to tournament's registeredPlayers list
    batch.update(_db.collection('tournaments').doc(reg.tournamentId), {
      'registeredPlayers': FieldValue.arrayUnion([reg.playerId]),
    });

    await batch.commit();
  }

  Future<void> updateRegistrationStatus(String registrationId, RegistrationStatus status) {
    return _db.collection('registrations').doc(registrationId).update({
      'status': status.name,
    });
  }

  Future<List<TournamentGroup>> getTournamentGroupsOnce(String tournamentId) async {
    final snapshot = await _db
        .collection('groups')
        .where('tournamentId', isEqualTo: tournamentId)
        .get();
    return snapshot.docs.map((doc) => TournamentGroup.fromFirestore(doc)).toList();
  }

  Stream<List<TournamentGroup>> getTournamentGroups(String tournamentId) {
    return _db
        .collection('groups')
        .where('tournamentId', isEqualTo: tournamentId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TournamentGroup.fromFirestore(doc)).toList());
  }

  Future<void> generateGroups(String tournamentId, int playersPerGroup, {List<String>? customPlayerIds, DateTime? deadline}) async {
    final tournamentDoc = await _db.collection('tournaments').doc(tournamentId).get();
    if (!tournamentDoc.exists) throw Exception("Tournament not found");

    final tournament = Tournament.fromFirestore(tournamentDoc);
    final playerIds = (customPlayerIds ?? List<String>.from(tournament.registeredPlayers)).toSet().toList();
    
    if (playerIds.length < 2) throw Exception("At least 2 players are required to generate groups.");
    
    playerIds.shuffle();

    // Fetch players to get their IGNs
    final players = await getPlayers();
    final ignMap = {for (var p in players) p.id: p.ign};

    final batch = _db.batch();
    int groupCount = (playerIds.length / playersPerGroup).ceil();

    for (int i = 0; i < groupCount; i++) {
      final start = i * playersPerGroup;
      final end = (i + 1) * playersPerGroup > playerIds.length
          ? playerIds.length
          : (i + 1) * playersPerGroup;
      
      final groupPlayers = playerIds.sublist(start, end);
      final groupRef = _db.collection('groups').doc();
      
      // Generate Alpha name (A, B, C... Z, AA, AB...)
      String groupLetter = '';
      int temp = i;
      while (temp >= 0) {
        groupLetter = String.fromCharCode((temp % 26) + 65) + groupLetter;
        temp = (temp / 26).floor() - 1;
      }

      final group = TournamentGroup(
        id: groupRef.id,
        tournamentId: tournamentId,
        name: 'Group $groupLetter',
        playerIds: groupPlayers,
        playerStats: {
          for (var p in groupPlayers) p: GroupStats(),
        },
      );
      
      batch.set(groupRef, group.toFirestore());

      // Generate round-robin matches for the group
      for (int j = 0; j < groupPlayers.length; j++) {
        for (int k = j + 1; k < groupPlayers.length; k++) {
          final p1Id = groupPlayers[j];
          final p2Id = groupPlayers[k];
          
          String p1Ign = (ignMap[p1Id] ?? 'Unknown');
          if (p1Ign.isEmpty || p1Ign.toLowerCase() == 'loading..') p1Ign = 'Unknown';
          
          String p2Ign = (ignMap[p2Id] ?? 'Unknown');
          if (p2Ign.isEmpty || p2Ign.toLowerCase() == 'loading..') p2Ign = 'Unknown';

          final matchRef = _db.collection('matches').doc();
          batch.set(matchRef, {
            'tournamentId': tournamentId,
            'groupId': groupRef.id,
            'player1Id': p1Id,
            'player2Id': p2Id,
            'player1Ign': p1Ign,
            'player2Ign': p2Ign,
            'player1Score': null,
            'player2Score': null,
            'isCompleted': false,
            'isVerified': false,
            'timestamp': FieldValue.serverTimestamp(),
            'deadline': deadline != null ? Timestamp.fromDate(deadline) : null,
            'round': 'Group Stage',
            'bracketIndex': 0,
          });
        }
      }
    }

    // Update tournament status
    batch.update(_db.collection('tournaments').doc(tournamentId), {
      'status': TournamentStatus.ongoing.name,
    });

    await batch.commit();
  }

  Future<void> advanceToKnockout(String tournamentId, int topNPerGroup, {DateTime? deadline}) async {
    final groupsQuery = await _db.collection('groups').where('tournamentId', isEqualTo: tournamentId).get();
    
    if (groupsQuery.docs.isEmpty) throw Exception("No groups found in this tournament.");

    // Sort groups by name to ensure consistent progression (Group A, B, C...)
    final groups = groupsQuery.docs.map((doc) => TournamentGroup.fromFirestore(doc)).toList();
    groups.sort((a, b) => a.name.compareTo(b.name));

    List<String> advancedPlayerIds = [];

    for (var group in groups) {
      List<String> sortedIds = List.from(group.playerIds);
      sortedIds.sort((a, b) {
        final statsA = group.playerStats[a] ?? GroupStats();
        final statsB = group.playerStats[b] ?? GroupStats();
        
        // 1. Points
        if (statsB.points != statsA.points) return statsB.points.compareTo(statsA.points);
        // 2. Goal Difference
        if (statsB.goalDifference != statsA.goalDifference) return statsB.goalDifference.compareTo(statsA.goalDifference);
        // 3. Goals For
        return statsB.goalsFor.compareTo(statsA.goalsFor);
      });
      
      advancedPlayerIds.addAll(sortedIds.take(topNPerGroup));
    }

    if (advancedPlayerIds.isEmpty) throw Exception("No players found to advance.");

    // Ensure uniqueness in case of data corruption
    advancedPlayerIds = advancedPlayerIds.toSet().toList();

    // Create knockout fixtures
    final players = await getPlayers();
    
    // Determine target size for knockout (power of 2)
    int count = advancedPlayerIds.length;
    int targetSize = 2;
    while (targetSize < count) {
      targetSize *= 2;
    }

    String roundName = getRoundName(targetSize);
    List<TournamentMatch> matches = [];
    int matchCount = targetSize ~/ 2;

    for (int i = 0; i < matchCount; i++) {
      // For Group Stage advancement, we usually want to pair seeds:
      // Group A Winner vs Group B Runner-up, etc.
      // But for a generic implementation, we use the sorted advanced list
      final p1Idx = i * 2;
      final p2Idx = i * 2 + 1;

      String p1Id = p1Idx < advancedPlayerIds.length ? advancedPlayerIds[p1Idx] : 'BYE';
      String p2Id = p2Idx < advancedPlayerIds.length ? advancedPlayerIds[p2Idx] : 'BYE';

      if (p1Id == 'BYE' && p2Id == 'BYE') continue;

      final p1 = p1Id != 'BYE' ? players.firstWhere((p) => p.id == p1Id, orElse: () => Player(id: p1Id, name: 'Unknown', email: '', ign: 'Unknown', uid: '')) : null;
      final p2 = p2Id != 'BYE' ? players.firstWhere((p) => p.id == p2Id, orElse: () => Player(id: p2Id, name: 'Unknown', email: '', ign: 'Unknown', uid: '')) : null;

      String p1Ign = p1?.ign ?? 'BYE';
      if (p1Ign.isEmpty || p1Ign.toLowerCase() == 'loading..') p1Ign = 'Unknown';
      String p2Ign = p2?.ign ?? 'BYE';
      if (p2Ign.isEmpty || p2Ign.toLowerCase() == 'loading..') p2Ign = 'Unknown';

      matches.add(TournamentMatch(
        id: '',
        tournamentId: tournamentId,
        player1Id: p1Id,
        player2Id: p2Id,
        player1Ign: p1Ign,
        player2Ign: p2Ign,
        timestamp: DateTime.now(),
        deadline: deadline,
        round: roundName,
        bracketIndex: i,
        isCompleted: p2Id == 'BYE' || p1Id == 'BYE',
        isVerified: p2Id == 'BYE' || p1Id == 'BYE',
        player1Score: p2Id == 'BYE' ? 1 : (p1Id == 'BYE' ? 0 : null),
        player2Score: p1Id == 'BYE' ? 1 : (p2Id == 'BYE' ? 0 : null),
      ));
    }

    await createMatches(matches);
  }

  Future<void> generateQualifyingRound(String tournamentId, {DateTime? deadline}) async {
    final tournamentDoc = await _db.collection('tournaments').doc(tournamentId).get();
    if (!tournamentDoc.exists) throw Exception("Tournament not found");

    final tournament = Tournament.fromFirestore(tournamentDoc);
    final playerIds = List<String>.from(tournament.registeredPlayers).toSet().toList();
    
    if (playerIds.length < 2) throw Exception("At least 2 verified players are required.");

    playerIds.shuffle();

    final players = await getPlayers();
    
    List<TournamentMatch> matches = [];
    int matchCount = (playerIds.length / 2).ceil();

    for (int i = 0; i < matchCount; i++) {
      final p1Idx = i * 2;
      final p2Idx = i * 2 + 1;

      String p1Id = p1Idx < playerIds.length ? playerIds[p1Idx] : 'BYE';
      String p2Id = p2Idx < playerIds.length ? playerIds[p2Idx] : 'BYE';

      if (p1Id == 'BYE' && p2Id == 'BYE') continue;

      final p1 = p1Id != 'BYE' ? players.firstWhere((p) => p.id == p1Id, orElse: () => Player(id: p1Id, name: 'Unknown', email: '', ign: 'Unknown', uid: '')) : null;
      final p2 = p2Id != 'BYE' ? players.firstWhere((p) => p.id == p2Id, orElse: () => Player(id: p2Id, name: 'Unknown', email: '', ign: 'Unknown', uid: '')) : null;

      String p1Ign = p1?.ign ?? 'BYE';
      if (p1Ign.isEmpty || p1Ign.toLowerCase() == 'loading..') p1Ign = 'Unknown';
      String p2Ign = p2?.ign ?? 'BYE';
      if (p2Ign.isEmpty || p2Ign.toLowerCase() == 'loading..') p2Ign = 'Unknown';

      matches.add(TournamentMatch(
        id: '',
        tournamentId: tournamentId,
        player1Id: p1Id,
        player2Id: p2Id,
        player1Ign: p1Ign,
        player2Ign: p2Ign,
        timestamp: DateTime.now(),
        deadline: deadline,
        round: 'Qualifying Round',
        bracketIndex: i,
        isCompleted: p2Id == 'BYE' || p1Id == 'BYE',
        isVerified: p2Id == 'BYE' || p1Id == 'BYE',
        player1Score: p2Id == 'BYE' ? 1 : (p1Id == 'BYE' ? 0 : null),
        player2Score: p1Id == 'BYE' ? 1 : (p2Id == 'BYE' ? 0 : null),
      ));
    }

    await createMatches(matches);
  }

  Future<List<String>> getKnockoutWinnersFromRound(String tournamentId, String roundName) async {
    final snapshot = await _db
        .collection('matches')
        .where('tournamentId', isEqualTo: tournamentId)
        .where('round', isEqualTo: roundName)
        .where('isVerified', isEqualTo: true)
        .get();

    Set<String> winners = {};
    for (var doc in snapshot.docs) {
      final match = TournamentMatch.fromFirestore(doc);
      if ((match.player1Score ?? 0) > (match.player2Score ?? 0)) {
        if (match.player1Id != 'BYE') winners.add(match.player1Id);
      } else if ((match.player2Score ?? 0) > (match.player1Score ?? 0)) {
        if (match.player2Id != 'BYE') winners.add(match.player2Id);
      }
    }
    return winners.toList();
  }

  // --- Tournament Stats ---
  // --- Helper Methods ---
  static String getRoundName(int totalPlayers) {
    if (totalPlayers > 128) return 'Round of $totalPlayers';
    if (totalPlayers == 128) return 'Round of 128';
    if (totalPlayers == 64) return 'Round of 64';
    if (totalPlayers == 32) return 'Round of 32';
    if (totalPlayers == 16) return 'Round of 16';
    if (totalPlayers == 8) return 'Quarter Finals';
    if (totalPlayers == 4) return 'Semi Finals';
    return 'Final';
  }

  static String getNextRoundName(String currentRound) {
    final normalized = currentRound.trim().toLowerCase();
    if (normalized.startsWith('round of ')) {
      int currentSize = int.tryParse(normalized.replaceFirst('round of ', '')) ?? 0;
      return getRoundName(currentSize ~/ 2);
    }
    switch (normalized) {
      case 'quarter finals': return 'Semi Finals';
      case 'semi finals': return 'Final';
      default: return currentRound;
    }
  }

  // --- Community Config ---
  Future<CommunityConfig> getCommunityConfig() async {
    final doc = await _db.collection('config').doc('community').get();
    return CommunityConfig.fromFirestore(doc);
  }

  Stream<CommunityConfig> getCommunityConfigStream() {
    return _db
        .collection('config')
        .doc('community')
        .snapshots()
        .map((doc) => CommunityConfig.fromFirestore(doc));
  }

  Future<void> updateCommunityConfig(CommunityConfig config) {
    return _db.collection('config').doc('community').set(config.toFirestore());
  }
}

class _CachedPlayer {
  final Player player;
  final DateTime timestamp;

  _CachedPlayer(this.player, this.timestamp);
}
