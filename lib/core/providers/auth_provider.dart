import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../../features/profile/models/player_profile_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseService _dbService = DatabaseService();

  User? _user;
  Player? _playerProfile;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  Player? get playerProfile => _playerProfile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _user != null;
  bool get isAdmin {
    final email = _user?.email?.toLowerCase() ?? _auth.currentUser?.email?.toLowerCase();
    return _playerProfile?.role == 'admin' || email == 'rifat6teen@gmail.com';
  }

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    // Only proceed if the user actually changed or if not initialized yet
    if (_user?.uid == firebaseUser?.uid && _isInitialized) return;

    // Mark as not initialized while we fetch the new user's profile
    _isInitialized = false;
    notifyListeners();

    _user = firebaseUser;
    
    if (firebaseUser != null) {
      await fetchPlayerProfile(firebaseUser.uid);
    } else {
      _playerProfile = null;
    }
    
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> fetchPlayerProfile(String uid) async {
    try {
      _playerProfile = await _dbService.getPlayer(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching player profile: $e');
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      _user = credential.user;
      if (_user != null) {
        await fetchPlayerProfile(_user!.uid);
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String ign,
    required String whatsapp,
    required String efootballUid,
  }) async {
    _setLoading(true);
    try {
      // Normalize data
      final cleanEmail = email.trim().toLowerCase();
      final cleanWhatsapp = whatsapp.trim();
      final cleanUid = efootballUid.trim();
      final cleanName = name.trim();
      final cleanIgn = ign.trim();

      // 1. Check uniqueness in Firestore (Pre-checks)
      final isEmailUnique = await _dbService.isEmailUnique(cleanEmail);
      if (!isEmailUnique) {
        throw 'This email address is already registered.';
      }

      final isMobileUnique = await _dbService.isWhatsappUnique(cleanWhatsapp);
      if (!isMobileUnique) {
        throw 'This WhatsApp number is already in use.';
      }

      final isUidUnique = await _dbService.isUidUnique(cleanUid);
      if (!isUidUnique) {
        throw 'This eFootball UID is already registered.';
      }

      // 2. Create Auth User
      final credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail, 
        password: password
      );
      
      if (credential.user != null) {
        // 3. Create Player Profile
        final newPlayer = Player(
          id: credential.user!.uid,
          name: cleanName,
          email: cleanEmail,
          ign: cleanIgn,
          whatsapp: cleanWhatsapp,
          uid: cleanUid,
        );
        
        // Update Firestore
        await _dbService.updatePlayer(newPlayer);
        
        // Update local state immediately
        _playerProfile = newPlayer;
        _user = credential.user;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'This email address is already registered.';
      } else if (e.code == 'weak-password') {
        throw 'The password provided is too weak.';
      } else if (e.code == 'invalid-email') {
        throw 'The email address is not valid.';
      }
      throw e.message ?? 'An unknown authentication error occurred.';
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
