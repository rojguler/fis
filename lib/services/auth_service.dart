import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Authentication service for handling user login and sign up
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _user;
  bool _isAdmin = false;
  bool _isTestModeLoggedIn = false;

  User? get user => _user ?? _auth.currentUser;
  bool get isAuthenticated => user != null || _isTestModeLoggedIn;
  bool get isAdmin => _isAdmin;
  
  String get currentUserId => user?.uid ?? (_isTestModeLoggedIn ? 'test_user_123' : '');
  String get currentUserEmail => user?.email ?? (_isTestModeLoggedIn ? 'test@example.com' : '');
  String get currentUserName => user?.displayName ?? (_isTestModeLoggedIn ? 'Test User' : '');
  
  // Check if Firebase is properly configured
  bool get isFirebaseConfigured {
    try {
      final apiKey = _auth.app.options.apiKey;
      return !apiKey.contains('Dummy') && 
             !apiKey.contains('Replace') && 
             apiKey.length > 20;
    } catch (e) {
      return false;
    }
  }

  AuthService() {
    // Initialize with current user
    _user = _auth.currentUser;
    
    // Check admin status for current user
    if (_user != null) {
      _checkAdminStatus();
    }
    
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _checkAdminStatus();
      } else {
        _isAdmin = false;
        _isTestModeLoggedIn = false;
      }
      notifyListeners();
    });
  }

  // Check if user is admin (from Firestore or email-based check)
  Future<void> _checkAdminStatus() async {
    if (_user == null) {
      _isAdmin = false;
      return;
    }

    try {
      // First, try to get role from Firestore users collection
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        _isAdmin = data?['role'] == 'admin' || data?['isAdmin'] == true;
      } else {
        // If user document doesn't exist, check email-based admin list
        // Admin emails can be stored in Firestore 'admins' collection or hardcoded
        // For now, we'll check a simple email pattern or Firestore admins collection
        final adminDoc = await _firestore.collection('admins').doc(_user!.email).get();
        _isAdmin = adminDoc.exists;
        
        // Also check if email contains 'admin' (for testing)
        // In production, remove this and use only Firestore
        if (!_isAdmin && _user!.email != null) {
          _isAdmin = _user!.email!.toLowerCase().contains('admin@') ||
                     _user!.email!.toLowerCase().endsWith('@admin.ikas.com');
        }
      }
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      // Fallback: check email pattern
      if (_user!.email != null) {
        _isAdmin = _user!.email!.toLowerCase().contains('admin@') ||
                   _user!.email!.toLowerCase().endsWith('@admin.ikas.com');
      } else {
        _isAdmin = false;
      }
    }
    
    notifyListeners();
  }

  // Admin code constant - change this for production
  static const String adminCode = 'IKAS_ADMIN_2024';

  // Sign up with email and password
  // adminCode is optional - if provided and correct, user will be created as admin
  Future<String?> signUp(String email, String password, String name, {String? adminCode}) async {
    try {
      // Check if Firebase is properly initialized
      if (_auth.app.options.apiKey.contains('Dummy') || 
          _auth.app.options.apiKey.contains('Replace') ||
          _auth.app.options.apiKey.length < 20) {
        // Firebase not configured - continue in test mode
        debugPrint('Firebase not configured - allowing test signup');
        // Temporarily set user in test mode (without real authentication)
        _isTestModeLoggedIn = true;
        if (adminCode != null && adminCode.trim() == AuthService.adminCode) {
          _isAdmin = true;
        } else {
          _isAdmin = false;
        }
        notifyListeners();
        return null; // Consider successful in test mode
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();
      _user = _auth.currentUser;
      
      // Check if admin code is provided and correct
      bool isAdmin = false;
      if (adminCode != null && adminCode.trim().isNotEmpty) {
        if (adminCode.trim() == AuthService.adminCode) {
          isAdmin = true;
          debugPrint('Admin code verified - creating admin user');
        } else {
          debugPrint('Invalid admin code provided');
        }
      }
      
      // Save user data to Firestore with role information
      if (_user != null) {
        try {
          await _firestore.collection('users').doc(_user!.uid).set({
            'email': email,
            'name': name,
            'role': isAdmin ? 'admin' : 'user',
            'isAdmin': isAdmin,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          
          // If admin, also add to admins collection
          if (isAdmin) {
            await _firestore.collection('admins').doc(email).set({
              'uid': _user!.uid,
              'name': name,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
          
          // Update admin status
          _isAdmin = isAdmin;
          notifyListeners();
        } catch (e) {
          debugPrint('Error saving user data to Firestore: $e');
          // Continue even if Firestore save fails
        }
      }
      
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      debugPrint('Full error details: $e');
      return _getErrorMessage(e.code, e.message);
    } catch (e) {
      debugPrint('Auth Error: $e');
      // Check if Firebase is initialized
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('firebase') || 
          errorStr.contains('platform') ||
          errorStr.contains('api') ||
          errorStr.contains('invalid') ||
          errorStr.contains('unauthorized')) {
        return 'Firebase configuration error. Please add your real API keys from Firebase Console to firebase_options.dart file.';
      }
      return 'Sign up failed: ${e.toString()}';
    }
  }

  // Sign in with email and password
  Future<String?> signIn(String email, String password) async {
    try {
      // Check if Firebase is properly initialized
      if (_auth.app.options.apiKey.contains('Dummy') || 
          _auth.app.options.apiKey.contains('Replace') ||
          _auth.app.options.apiKey.length < 20) {
        // Firebase not configured - continue in test mode
        debugPrint('Firebase not configured - allowing test login');
        // Temporarily set user in test mode (without real authentication)
        _isTestModeLoggedIn = true;
        notifyListeners();
        return null; // Consider successful in test mode
      }

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = _auth.currentUser;
      return null; // Success
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      debugPrint('Full error details: $e');
      return _getErrorMessage(e.code, e.message);
    } catch (e) {
      debugPrint('Auth Error: $e');
      // Check if Firebase is initialized
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('firebase') || 
          errorStr.contains('platform') ||
          errorStr.contains('api') ||
          errorStr.contains('invalid') ||
          errorStr.contains('unauthorized')) {
        return 'Firebase configuration error. Please add your real API keys from Firebase Console to firebase_options.dart file.';
      }
      return 'Sign in failed: ${e.toString()}';
    }
  }

  // Sign in with Google
  Future<String?> signInWithGoogle() async {
    try {
      if (_auth.app.options.apiKey.contains('Dummy') || 
          _auth.app.options.apiKey.contains('Replace') ||
          _auth.app.options.apiKey.length < 20) {
        return 'Firebase configuration error. Google Sign-In requires valid API keys.';
      }

      // V7 API: initialize first
      await GoogleSignIn.instance.initialize(
        clientId: '526611601642-ok7lh33tqf1sekibhps4n70sivtb8fk5.apps.googleusercontent.com',
      );

      GoogleSignInAccount? googleUser;
      try {
        googleUser = await GoogleSignIn.instance.authenticate();
      } catch (e) {
        debugPrint('Google Sign-In Cancelled or Failed: $e');
        return null; // User canceled or error during auth
      }

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // V7 API: accessToken is moved to authorizationClient, idToken is enough for Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
      
      // If it's a new user, create their Firestore profile
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(_user!.uid).set({
          'email': _user!.email,
          'name': _user!.displayName ?? 'Google User',
          'role': 'user',
          'isAdmin': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await _checkAdminStatus(); // Check if existing user is admin
      }

      notifyListeners();
      return null; // Success
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return 'Google girişi başarısız oldu: ${e.toString()}';
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
    _user = null;
    _isTestModeLoggedIn = false;
    _isAdmin = false;
    notifyListeners();
  }

  /// Update the signed-in user's display name.
  Future<void> updateDisplayName(String newName) async {
    try {
      await _auth.currentUser?.updateDisplayName(newName);
      await _auth.currentUser?.reload();
      _user = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('updateDisplayName error: $e');
    }
  }

  // Get user-friendly error messages
  String _getErrorMessage(String code, String? message) {
    // Check for API key issues in the message
    if (message != null) {
      final msgLower = message.toLowerCase();
      if (msgLower.contains('api') && msgLower.contains('key')) {
        return 'Firebase API key is invalid. Please update firebase_options.dart file with your real Firebase keys.';
      }
      if (msgLower.contains('unauthorized') || msgLower.contains('permission')) {
        return 'Firebase authorization error. Please check your API keys and Firebase Console settings.';
      }
    }

    switch (code) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'This email address is already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Internet connection error. Please check your connection.';
      case 'invalid-api-key':
        return 'Firebase configuration error. Please check your Firebase settings.';
      case 'api-key-not-valid.-please-pass-a-valid-api-key.':
        return 'Firebase API key is invalid. Please update firebase_options.dart file with your real Firebase keys.';
      case 'unauthorized':
        return 'Firebase authorization error. Please check your API keys.';
      case 'unknown':
      case 'internal-error':
        return 'Firebase configuration is missing or incorrect. Please update firebase_options.dart file with your real Firebase keys.';
      default:
        return 'Sign in failed: $code. Please check Firebase configuration.';
    }
  }
}

