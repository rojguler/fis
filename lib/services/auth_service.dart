import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  
  bool get isFirebaseConfigured {
    try {
      final apiKey = _auth.app.options.apiKey;
      return !apiKey.contains('Dummy') && !apiKey.contains('Replace') && apiKey.length > 20;
    } catch (e) {
      return false;
    }
  }

  AuthService() {
    _user = _auth.currentUser;
    if (_user != null) _checkAdminStatus();
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) _checkAdminStatus(); else { _isAdmin = false; _isTestModeLoggedIn = false; }
      notifyListeners();
    });
  }

  Future<void> _checkAdminStatus() async {
    if (_user == null) { _isAdmin = false; return; }
    try {
      final userDoc = await _firestore.collection('users').doc(_user!.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        _isAdmin = data?['role'] == 'admin' || data?['isAdmin'] == true;
      } else {
        final adminDoc = await _firestore.collection('admins').doc(_user!.email).get();
        _isAdmin = adminDoc.exists;
        if (!_isAdmin && _user!.email != null) {
          _isAdmin = _user!.email!.toLowerCase().contains('admin@') || _user!.email!.toLowerCase().endsWith('@admin.ikas.com');
        }
      }
    } catch (e) {
      debugPrint('Admin check error: $e');
    }
    notifyListeners();
  }

  static const String adminCode = 'IKAS_ADMIN_2024';

  Future<String?> signUp(String email, String password, String name, {String? adminCode, String languageCode = 'tr'}) async {
    try {
      if (!isFirebaseConfigured) {
        _isTestModeLoggedIn = true;
        _isAdmin = adminCode == AuthService.adminCode;
        notifyListeners();
        return null;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();
      _user = _auth.currentUser;
      
      bool isAdmin = adminCode?.trim() == AuthService.adminCode;
      
      if (_user != null) {
        await _firestore.collection('users').doc(_user!.uid).set({
          'email': email,
          'name': name,
          'role': isAdmin ? 'admin' : 'user',
          'isAdmin': isAdmin,
          'language': languageCode,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        if (isAdmin) {
          await _firestore.collection('admins').doc(email).set({
            'uid': _user!.uid, 'name': name, 'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      
      if (_user != null && !_user!.emailVerified) {
        await _user!.sendEmailVerification();
      }

      await _auth.signOut(); // Verify before login
      _user = null;
      _isAdmin = false;
      
      return languageCode == 'tr' 
          ? 'Kayıt başarılı! Lütfen e-postanızı doğrulayıp giriş yapın.' 
          : 'Signup successful! Please verify your email and then login.';
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code, languageCode);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signIn(String email, String password, {String languageCode = 'tr'}) async {
    try {
      if (!isFirebaseConfigured) {
        _isTestModeLoggedIn = true;
        _isAdmin = email.contains('admin');
        notifyListeners();
        return null;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await _auth.signOut();
        return languageCode == 'tr' 
            ? 'Lütfen önce e-posta adresinizi doğrulayın.' 
            : 'Please verify your email address first.';
      }
      
      _user = userCredential.user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapFirebaseError(e.code, languageCode);
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      if (!isFirebaseConfigured) return 'Firebase not configured.';
      await GoogleSignIn.instance.initialize(clientId: '526611601642-ok7lh33tqf1sekibhps4n70sivtb8fk5.apps.googleusercontent.com');
      final googleUser = await GoogleSignIn.instance.authenticate();
      final AuthCredential credential = GoogleAuthProvider.credential(idToken: googleUser.authentication.idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
      
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _firestore.collection('users').doc(_user!.uid).set({
          'email': _user!.email, 'name': _user!.displayName ?? 'Google User',
          'role': 'user', 'isAdmin': false, 'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await _checkAdminStatus();
      }
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _isAdmin = false;
    _isTestModeLoggedIn = false;
    notifyListeners();
  }

  // Update user profile display name
  Future<String?> updateDisplayName(String newName) async {
    try {
      if (user != null) {
        await user!.updateDisplayName(newName);
        await user!.reload();
        _user = _auth.currentUser;
        
        // Also update Firestore
        await _firestore.collection('users').doc(_user!.uid).update({
          'name': newName,
        });
        
        notifyListeners();
        return null; // Success
      }
      return 'User not logged in';
    } catch (e) {
      debugPrint('Error updating display name: $e');
      return e.toString();
    }
  }

  String _mapFirebaseError(String code, String langCode) {
    final bool isTr = langCode == 'tr';
    switch (code) {
      case 'user-not-found': return isTr ? 'Bu e-posta adresiyle kayıtlı bir kullanıcı bulunamadı.' : 'No user found with this email address.';
      case 'wrong-password': return isTr ? 'Hatalı şifre girdiniz. Lütfen tekrar deneyin.' : 'Wrong password. Please try again.';
      case 'email-already-in-use': return isTr ? 'Bu e-posta adresi zaten kullanımda.' : 'This email is already in use.';
      case 'weak-password': return isTr ? 'Şifreniz çok zayıf.' : 'The password is too weak.';
      case 'invalid-email': return isTr ? 'Geçersiz e-posta adresi.' : 'The email address is invalid.';
      case 'too-many-requests': return isTr ? 'Çok fazla deneme yaptınız. Daha sonra tekrar deneyin.' : 'Too many attempts. Try again later.';
      default: return isTr ? 'Bir hata oluştu. Lütfen tekrar deneyin.' : 'An error occurred. Please try again.';
    }
  }
}
